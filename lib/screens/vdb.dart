import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:home_automation_tablet/widgets/view_users_widget.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../utils/janus_webrtc_client.dart';
import 'package:home_automation_tablet/utils/fb_utils.dart';
import 'dart:io';
import 'package:home_automation_tablet/utils/app_state.dart';
import 'package:home_automation_tablet/utils/web_api.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:home_automation_tablet/widgets/full_screen_video_view.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:home_automation_tablet/widgets/add_users_widget.dart';

class VDB extends StatefulWidget {
  const VDB({super.key});

  @override
  State<VDB> createState() => _VDBState();
}

class _VDBState extends State<VDB> {
  late String ip;
  late String? ipType;
  String? _recordedFilePath;
  bool isViewUserClicked = false;
  bool isStremVisible = false;
  bool isStreamStarted = false;
  String counterValue = '0';
  bool isDisconnectVisible = false;
  bool isConnectVisible = true;
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  FirebaseUtils fbUtils = FirebaseUtils();
  GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _connected = false;
  String _status = 'Disconnected';
  WebApi webApi = WebApi();
  late JanusWebRTCClient _client;
  MediaRecorder? _mediaRecorder;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _showControls = false;
  Timer? _hideControlsTimer;
  StreamSubscription<DatabaseEvent>? _ipSubscription;

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _connect() async {
    try {
      await _client.connect();
      await _client.attachToStreamingPlugin();
      setState(() {
        _connected = true;
        _status = 'Connected to Janus Streaming';
      });
      await _client.listStreams();
    } catch (e) {
      setState(() {
        _status = 'Connection failed: $e';
      });
    }
  }

  void _watchStream() async {
    final streamId = 7;
    await _client.watchStream(streamId);
    print('Watch Stream Called');
  }

  Future<void> connectOnPageInit() async {
    try {
      await _client.connect();
      await _client.attachToStreamingPlugin();
      setState(() {
        _connected = true;
        _status = 'Connected to Janus Streaming';
      });
      await _client.listStreams();
    } catch (e) {
      print(e);
      setState(() {
        _status = 'Connection failed: $e';
      });
    }
  }

  void _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _showCupertinoDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    bool isError = false,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message),
        ),
        actions: [
          if (onCancel != null)
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                onCancel();
              },
              child: const Text('No'),
            ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(onCancel != null ? 'Yes' : 'OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeClient(String ip, String ipType) async {
    print('🔌 Initializing client with IP: $ip (Type: $ipType)');

    String wsUrl;
    if (ipType == "IPv6") {
      wsUrl = 'ws://[$ip]:8188';
    } else if (ipType == "IPv4") {
      wsUrl = 'ws://$ip:8188';
    } else {
      _showCupertinoDialog(
        title: 'Error',
        message: 'IP Type is neither IPv4 nor IPv6',
        onConfirm: () {},
        isError: true,
      );
      return;
    }

    _client = JanusWebRTCClient(wsUrl);
    await connectOnPageInit();

    _client.messages.listen((message) {
      if (mounted) {
        setState(() {
          _status = message;
        });
      }
    });

    _client.remoteStream.listen((stream) {
      if (mounted) {
        _remoteRenderer.srcObject = stream;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initRenderers();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.showLoader();

      try {
        // Read initial IP address from Firebase
        final ipData = await fbUtils.readIpAddress();
        final initialIp = ipData['ip'];
        final initialIpType = ipData['ipType'];

        if (initialIp == null || initialIpType == null) {
          appState.hideLoader();
          _showCupertinoDialog(
            title: 'Error',
            message: 'Unable to read IP address from Firebase',
            onConfirm: () {
              Navigator.pop(context);
            },
            isError: true,
          );
          return;
        }

        // Update provider with initial IP
        appState.setIpAddress(initialIp, initialIpType);

        // Set local variables
        ip = initialIp;
        ipType = initialIpType;

        print('📖 Initial IP: $ip (Type: $ipType)');

        // Start listening for IP changes
        _ipSubscription = fbUtils.listenToIpAddress(
          onIpChanged: (newIp, newIpType) async {
            print('📡 IP changed from $ip to $newIp');

            // Update provider
            appState.setIpAddress(newIp, newIpType);

            // If IP changed while connected, reconnect with new IP
            if (_connected && (newIp != ip || newIpType != ipType)) {
              _showCupertinoDialog(
                title: 'IP Address Changed',
                message:
                    'Server IP changed to $newIp ($newIpType). Reconnecting...',
                onConfirm: () async {
                  appState.showLoader();

                  try {
                    // Stop recording if active
                    if (_isRecording) {
                      _recordingTimer?.cancel();
                      await _mediaRecorder?.stop();
                      setState(() {
                        _isRecording = false;
                        _mediaRecorder = null;
                        _recordingDuration = 0;
                      });
                    }

                    // Disconnect from old server
                    await _client.disconnect();

                    setState(() {
                      ip = newIp;
                      ipType = newIpType;
                      _connected = false;
                      isStreamStarted = false;
                      _remoteRenderer.srcObject = null;
                    });

                    // Connect to new server
                    await _initializeClient(newIp, newIpType);

                    appState.hideLoader();

                    _showCupertinoDialog(
                      title: 'Reconnected',
                      message: 'Successfully connected to new server',
                      onConfirm: () {},
                    );
                  } catch (e) {
                    appState.hideLoader();
                    _showCupertinoDialog(
                      title: 'Error',
                      message: 'Failed to reconnect: $e',
                      onConfirm: () {},
                      isError: true,
                    );
                  }
                },
              );
            } else if (!_connected) {
              // Just update the IP if not connected
              setState(() {
                ip = newIp;
                ipType = newIpType;
              });
            }
          },
        );

        // Initialize client with IP
        await _initializeClient(initialIp, initialIpType);
      } catch (e) {
        print('❌ Initialization error: $e');
        _showCupertinoDialog(
          title: 'Error',
          message: 'Failed to initialize: $e',
          onConfirm: () {
            Navigator.pop(context);
          },
          isError: true,
        );
      } finally {
        appState.hideLoader();
      }
    });
  }

  @override
  void dispose() {
    _mediaRecorder?.stop();
    _recordingTimer?.cancel();
    _hideControlsTimer?.cancel();
    _ipSubscription?.cancel();
    _client.disconnect();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final macAddress = Provider.of<AppState>(context).macAddress;
    FirebaseDatabase database = fbUtils.database;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        return ModalProgressHUD(
          inAsyncCall: appState.isLoading,
          child: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              backgroundColor: CupertinoColors.activeBlue,
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.back,
                  color: CupertinoColors.white,
                ),
                onPressed: () async {
                  appState.showLoader();

                  // Stop recording if active
                  if (_isRecording) {
                    _recordingTimer?.cancel();
                    await _mediaRecorder?.stop();
                  }

                  await _client.disconnect();
                  DatabaseReference userResponseFieldRef = database.ref(
                    '/dev_env/sendFeed',
                  );
                  try {
                    await userResponseFieldRef.set(false);
                    appState.hideLoader();
                    Navigator.pop(context);
                  } catch (e) {
                    print('Error updating user response to false: $e');
                    appState.hideLoader();
                    Navigator.pop(context);
                  }
                },
              ),
              middle: const Text(
                'Live Feed',
                style: TextStyle(color: CupertinoColors.white, fontSize: 20),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25.0,
                  vertical: 15.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Center(
                      child: Text(
                        'VDB - Main Door',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Visibility(
                          visible: isConnectVisible && !isStreamStarted,
                          child: _CupertinoFuncButton(
                            btnLabel: 'Watch Feed',
                            icon: CupertinoIcons.videocam_fill,
                            onPressed: () {
                              _showCupertinoDialog(
                                title: 'Alert',
                                message:
                                    'Do you want to view the stream on $ip?',
                                onConfirm: () async {
                                  _watchStream();
                                  DatabaseReference userResponseFieldRef =
                                      database.ref('/dev_env/sendFeed');
                                  try {
                                    await userResponseFieldRef.set(true);
                                    setState(() {
                                      isStreamStarted = true;
                                    });
                                  } catch (e) {
                                    print(
                                      'Error updating user response to true: $e',
                                    );
                                  }
                                },
                                onCancel: () async {
                                  DatabaseReference userResponseFieldRef =
                                      database.ref('/dev_env/sendFeed');
                                  try {
                                    await userResponseFieldRef.set(true);
                                  } catch (e) {
                                    print(
                                      'Error updating user response to true: $e',
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    if (!isStreamStarted) const SizedBox(height: 30),
                    if (_connected && isStreamStarted)
                      Container(
                        margin: const EdgeInsets.all(0.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: CupertinoColors.activeBlue,
                            width: 5,
                          ),
                        ),
                        child: SizedBox(
                          width: double.maxFinite,
                          height: MediaQuery.of(context).size.height * 0.35,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showControls = !_showControls;
                              });
                              if (_showControls) {
                                _hideControlsTimer?.cancel();
                                _hideControlsTimer = Timer(
                                  const Duration(milliseconds: 2500),
                                  () {
                                    if (mounted) {
                                      setState(() {
                                        _showControls = false;
                                      });
                                    }
                                  },
                                );
                              }
                            },
                            child: Stack(
                              children: [
                                RepaintBoundary(
                                  key: _repaintBoundaryKey,
                                  child: RTCVideoView(
                                    _remoteRenderer,
                                    filterQuality: FilterQuality.high,
                                    objectFit: RTCVideoViewObjectFit
                                        .RTCVideoViewObjectFitCover,
                                    mirror: false,
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Flash(
                                    animate: true,
                                    infinite: true,
                                    child: const Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.circle_fill,
                                          color: CupertinoColors.systemRed,
                                          size: 18,
                                        ),
                                        Text(
                                          ' Live',
                                          style: TextStyle(
                                            color: CupertinoColors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isRecording)
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.black
                                            .withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.circle_fill,
                                            color: CupertinoColors.systemRed,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDuration(_recordingDuration),
                                            style: const TextStyle(
                                              color: CupertinoColors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (_showControls)
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.black
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: CupertinoButton(
                                        padding: const EdgeInsets.all(8),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            CupertinoPageRoute(
                                              builder: (context) =>
                                                  FullScreenVideoView(
                                                    renderer: _remoteRenderer,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: const Icon(
                                          CupertinoIcons.fullscreen,
                                          color: CupertinoColors.white,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    if (isStreamStarted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 16.0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          color: Colors.lightBlueAccent.withOpacity(0.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _CupertinoFuncButton(
                              btnLabel: 'Unlock',
                              icon: CupertinoIcons.lock,
                              onPressed: () async {
                                DatabaseReference userResponseFieldRef =
                                    database.ref('/dev_env/unlockDoor');
                                try {
                                  await userResponseFieldRef.set(true);
                                  await webApi.unlockDoor(context);
                                } catch (e) {
                                  appState.hideLoader();
                                  _showCupertinoDialog(
                                    title: 'Error',
                                    message: 'Failed to Unlock Door',
                                    onConfirm: () {},
                                    isError: true,
                                  );
                                }
                              },
                            ),
                            _CupertinoFuncButton(
                              btnLabel: 'Capture',
                              icon: CupertinoIcons.camera,
                              onPressed: () async {
                                try {
                                  final GlobalKey repaintBoundaryKey =
                                      GlobalKey();
                                  setState(() {
                                    _repaintBoundaryKey = repaintBoundaryKey;
                                  });
                                  await Future.delayed(
                                    const Duration(milliseconds: 100),
                                  );

                                  RenderRepaintBoundary boundary =
                                      repaintBoundaryKey.currentContext!
                                              .findRenderObject()
                                          as RenderRepaintBoundary;
                                  ui.Image image = await boundary.toImage(
                                    pixelRatio: 3.0,
                                  );
                                  ByteData? byteData = await image.toByteData(
                                    format: ui.ImageByteFormat.png,
                                  );
                                  Uint8List imageBytes = byteData!.buffer
                                      .asUint8List();

                                  final result =
                                      await ImageGallerySaverPlus.saveImage(
                                        imageBytes,
                                        quality: 100,
                                        name:
                                            'door_capture_${DateTime.now().millisecondsSinceEpoch}',
                                      );

                                  if (result != null && result['isSuccess']) {
                                    _showCupertinoDialog(
                                      title: 'Success',
                                      message: 'Image saved to gallery',
                                      onConfirm: () {},
                                    );
                                  } else {
                                    throw Exception('Failed to save image');
                                  }
                                } catch (e) {
                                  _showCupertinoDialog(
                                    title: 'Error',
                                    message: 'Failed to capture image',
                                    onConfirm: () {},
                                    isError: true,
                                  );
                                }
                              },
                            ),
                            _CupertinoFuncButton(
                              btnLabel: _isRecording ? 'Stop' : 'Record',
                              icon: _isRecording
                                  ? CupertinoIcons.stop_fill
                                  : CupertinoIcons.circle_fill,
                              onPressed: () async {
                                if (_isRecording) {
                                  try {
                                    _recordingTimer?.cancel();
                                    await _mediaRecorder?.stop();
                                    final result =
                                        await ImageGallerySaverPlus.saveFile(
                                          _recordedFilePath!,
                                          name:
                                              'door_recording_${DateTime.now().millisecondsSinceEpoch}',
                                        );

                                    if (result != null && result['isSuccess']) {
                                      _showCupertinoDialog(
                                        title: 'Success',
                                        message: 'Video saved to gallery',
                                        onConfirm: () {},
                                      );
                                    } else {
                                      throw Exception('Failed to save video');
                                    }

                                    setState(() {
                                      _isRecording = false;
                                      _mediaRecorder = null;
                                      _recordingDuration = 0;
                                    });
                                  } catch (e) {
                                    _showCupertinoDialog(
                                      title: 'Error',
                                      message: 'Failed to save recording',
                                      onConfirm: () {},
                                      isError: true,
                                    );
                                  }
                                } else {
                                  try {
                                    if (_remoteRenderer.srcObject == null) {
                                      throw Exception(
                                        'No video stream to record',
                                      );
                                    }

                                    Directory tempDir =
                                        await getTemporaryDirectory();
                                    String tempPath =
                                        '${tempDir.path}/temp_recording_${DateTime.now().millisecondsSinceEpoch}.mp4';
                                    _recordedFilePath = tempPath;

                                    _mediaRecorder = MediaRecorder();
                                    final videoTrack = _remoteRenderer
                                        .srcObject!
                                        .getVideoTracks()
                                        .first;

                                    await _mediaRecorder!.start(
                                      tempPath,
                                      videoTrack: videoTrack,
                                    );

                                    setState(() {
                                      _isRecording = true;
                                      _recordingDuration = 0;
                                    });

                                    _recordingTimer = Timer.periodic(
                                      const Duration(seconds: 1),
                                      (timer) {
                                        setState(() {
                                          _recordingDuration++;
                                        });
                                      },
                                    );

                                    _showCupertinoDialog(
                                      title: 'Recording',
                                      message: 'Video recording started',
                                      onConfirm: () {},
                                    );
                                  } catch (e) {
                                    _showCupertinoDialog(
                                      title: 'Error',
                                      message: 'Failed to start recording',
                                      onConfirm: () {},
                                      isError: true,
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 30),
                    if (isStreamStarted)
                      const Center(
                        child: Text(
                          'User Management',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    if (isStreamStarted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 16.0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          color: Colors.lightBlueAccent.withOpacity(0.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _CupertinoFuncButton(
                              btnLabel: 'Add User',
                              icon: CupertinoIcons.add,
                              onPressed: () {
                                print('Clicked Add User');
                              },
                            ),
                            _CupertinoFuncButton(
                              btnLabel: 'Delete User',
                              icon: CupertinoIcons.delete,
                              onPressed: () {
                                print('Clicked Delete User');
                              },
                            ),
                            _CupertinoFuncButton(
                              btnLabel: 'View Users',
                              icon: CupertinoIcons.list_bullet,
                              onPressed: () {
                                setState(() {
                                  isViewUserClicked = !isViewUserClicked;
                                });
                                print('Clicked View Users');
                              },
                            ),
                            _CupertinoFuncButton(
                              btnLabel: 'Verify Users',
                              icon: CupertinoIcons.eye,
                              onPressed: () {
                                print('Clicked View Users');
                              },
                            ),
                          ],
                        ),
                      ),
                    if (isViewUserClicked)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30.0),
                          child: ViewUsersWidget(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CupertinoFuncButton extends StatelessWidget {
  final String btnLabel;
  final IconData icon;
  final VoidCallback onPressed;

  const _CupertinoFuncButton({
    required this.btnLabel,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: CupertinoColors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            btnLabel,
            style: const TextStyle(fontSize: 14, color: CupertinoColors.label),
          ),
        ],
      ),
    );
  }
}
