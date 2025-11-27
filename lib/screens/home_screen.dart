import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:home_automation_tablet/widgets/tile_card.dart';
import 'package:home_automation_tablet/widgets/presets_tile.dart';
import 'package:home_automation_tablet/widgets/sensor_card.dart';
import 'package:home_automation_tablet/widgets/ac_unit_card.dart';
import 'package:home_automation_tablet/widgets/lock_utility.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../utils/app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<FirebaseApp> _initialization;
  dynamic dbResponse1;
  late DatabaseReference _dbRef1;
  StreamSubscription<DatabaseEvent>? _dbSubscription, _dbSubscription1;
  bool spinner = true;
  dynamic isFire, isWindowOpen, lightsStatus;

  // Connection state tracking
  bool _isConnected = false;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  static const Duration _retryDelay = Duration(seconds: 2);
  Timer? _retryTimer;
  Timer? _connectionCheckTimer;

  Future<void> handler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('Title : ${message.notification!.title}');
    print('Body : ${message.notification!.body}');
  }

  Future<void> getNotifPermission() async {
    try {
      var status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
      if (await Permission.location.isRestricted) {
        await Permission.notification.request();
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
    }
  }

  Future<void> fbPushNotification() async {
    try {
      final firebaseMessaging = FirebaseMessaging.instance;
      await firebaseMessaging.requestPermission();
      FirebaseMessaging.onBackgroundMessage(handler);
    } catch (e) {
      print('Error setting up push notifications: $e');
    }
  }

  Future<void> _getToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null && mounted) {
        try {
          await _dbRef1.child("fcmDeviceToken").set(token);
          print(
            'FCM Token: $token successfully written to database at /updates/fcmDeviceToken',
          );
        } catch (e) {
          print('Error writing FCM token to database: $e');
        }
      } else {
        print('Failed to get FCM token or widget not mounted.');
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  // Load initial data from Firebase
  Future<void> _loadInitialData() async {
    if (!mounted) return;

    try {
      print('Loading initial data from Firebase...');

      // Get a one-time snapshot of the data
      final snapshot = await _dbRef1.once();

      if (!mounted) return;

      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value;
        print('Initial data loaded: $data');

        final appState = Provider.of<AppState>(context, listen: false);
        appState.setUpdates(data);
        appState.setConnectionStatus(true);

        setState(() {
          dbResponse1 = data;
          _isConnected = true;
          spinner = false; // Hide spinner after initial load
        });

        print(
          'Initial load complete - Status bar should now display all flags',
        );
      } else {
        print('No initial data found at Firebase path');
        setState(() {
          spinner = false;
        });
      }
    } catch (e) {
      print('Error loading initial data: $e');
      setState(() {
        spinner = false;
      });
    }
  }

  void _updateConnectionStatus(bool isConnected) {
    if (mounted && _isConnected != isConnected) {
      setState(() {
        _isConnected = isConnected;
      });

      final appState = Provider.of<AppState>(context, listen: false);
      appState.setConnectionStatus(isConnected);

      print('Database connection status changed: $isConnected');
    }
  }

  void _resetRetryCount() {
    _retryCount = 0;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _scheduleRetry() {
    if (_retryCount >= _maxRetries) {
      print('Max retry attempts reached. Stopping retry attempts.');
      _updateConnectionStatus(false);
      setState(() {
        spinner = false;
      });
      return;
    }

    _retryCount++;
    print(
      'Scheduling retry attempt $_retryCount/$_maxRetries in ${_retryDelay.inSeconds} seconds',
    );

    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      if (mounted) {
        print('Retrying database connection...');
        _reconnectToDatabase();
      }
    });
  }

  void _reconnectToDatabase() {
    try {
      _dbSubscription?.cancel();
      listenToDatabaseUpdates(_dbRef1);
    } catch (e) {
      print('Error during reconnection: $e');
      _scheduleRetry();
    }
  }

  void listenToDatabaseUpdates(DatabaseReference dbRef) {
    if (!mounted) {
      print('Widget not mounted, skipping database listener setup');
      return;
    }

    print('Setting up database listener at path: ${dbRef.path}');

    // Cancel existing subscription
    _dbSubscription?.cancel();

    try {
      _dbSubscription = dbRef.onValue.listen(
        (DatabaseEvent event) {
          if (!mounted) {
            print('Widget not mounted, ignoring database event');
            return;
          }

          try {
            print('Database event received at ${DateTime.now()}');
            print('Event type: ${event.type}');
            print('Snapshot exists: ${event.snapshot.exists}');

            // Reset retry count on successful data reception
            if (_retryCount > 0) {
              print('Database connection restored');
              _resetRetryCount();
            }
            _updateConnectionStatus(true);

            // Hide spinner after first successful load
            if (spinner) {
              setState(() {
                spinner = false;
              });
            }

            setState(() {
              if (event.snapshot.exists) {
                final newData = event.snapshot.value;

                // Validate data structure
                if (newData != null) {
                  dbResponse1 = newData;
                  print('Valid data received: $dbResponse1');

                  // Safely update provider
                  try {
                    final appState = Provider.of<AppState>(
                      context,
                      listen: false,
                    );
                    appState.setUpdates(dbResponse1);
                    print(
                      'Provider updated successfully - Status bar should reflect changes',
                    );
                  } catch (providerError) {
                    print('Error updating provider: $providerError');
                  }
                } else {
                  print('Received null data from database');
                  dbResponse1 = null;
                  Provider.of<AppState>(
                    context,
                    listen: false,
                  ).setUpdates(null);
                }
              } else {
                print("No data at path: ${dbRef.path}");
                dbResponse1 = null;
                Provider.of<AppState>(context, listen: false).setUpdates(null);
              }
            });
          } catch (e) {
            print('Error processing database event: $e');
            // Don't trigger retry for processing errors, just log them
          }
        },
        onError: (error) {
          print("Database listener error at ${DateTime.now()}: $error");
          _updateConnectionStatus(false);

          if (mounted) {
            setState(() {
              spinner = false;
            });

            // Schedule retry on connection errors
            _scheduleRetry();
          }
        },
        onDone: () {
          print('Database stream closed');
          _updateConnectionStatus(false);
          if (mounted && _retryCount < _maxRetries) {
            _scheduleRetry();
          }
        },
      );

      print('Database listener setup completed');
    } catch (e) {
      print('Error setting up database listener: $e');
      _updateConnectionStatus(false);
      _scheduleRetry();
    }
  }

  void _startConnectionHealthCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      print('Performing connection health check...');

      // If we haven't received data recently and no retry is in progress
      if (!_isConnected && _retryTimer == null && _retryCount < _maxRetries) {
        print('Connection appears down, attempting reconnection...');
        _reconnectToDatabase();
      }
    });
  }

  @override
  void initState() {
    super.initState();

    print('Initializing HomeScreen...');

    fbPushNotification();
    getNotifPermission();

    _initialization = Firebase.initializeApp();

    _initialization
        .then((firebaseApp) async {
          if (!mounted) return;

          try {
            FirebaseDatabase database = FirebaseDatabase.instanceFor(
              app: firebaseApp,
              databaseURL:
                  'https://vdb-poc-default-rtdb.asia-southeast1.firebasedatabase.app/',
            );

            _dbRef1 = database.ref("updates");

            // Load initial data first
            await _loadInitialData();

            // Then set up real-time listener for updates
            listenToDatabaseUpdates(_dbRef1);

            // Get FCM token
            _getToken();

            // Start connection health monitoring
            _startConnectionHealthCheck();

            print('Firebase initialization completed successfully');
          } catch (e) {
            print('Error during Firebase initialization: $e');
            if (mounted) {
              setState(() {
                spinner = false;
              });
            }
          }
        })
        .catchError((error) {
          print('Firebase initialization failed: $error');
          if (mounted) {
            setState(() {
              spinner = false;
            });
          }
        });
  }

  @override
  void dispose() {
    print('Disposing HomeScreen...');
    _dbSubscription?.cancel();
    _dbSubscription1?.cancel();
    _retryTimer?.cancel();
    _connectionCheckTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: true);

    return SafeArea(
      child: ModalProgressHUD(
        inAsyncCall: spinner,
        child: Scaffold(
          backgroundColor: Color(0xFF08306B),
          body: Column(
            children: [
              if (!_isConnected)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  color: Colors.red.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Connection lost. Retrying... ($_retryCount/$_maxRetries)',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TileCard(
                            height: 100,
                            isUserProfileTile: true,
                            flex: 1,
                            title: 'Godrej Test',
                            tileColor: Colors.lightBlue[400]!,
                            icon:
                                'images/animations/Profile Avatar of Young Boy.json',
                            isStatusBar: false,
                            callBack: () {
                              print('Clicked');
                            },
                          ),
                          TileCard(
                            height: 100,
                            flex: 2,
                            title: 'Status Bar',
                            tileColor: Colors.lightBlue[400]!,
                            isStatusBar: true,
                            callBack: () {
                              print('Clicked Status Bar');
                              print(
                                'Current state - Fire: ${appState.isFireActive}, Window: ${appState.isWindowOpenActive}, Gas: ${appState.isGasLeakActive}, Lights: ${appState.isLightsOn}',
                              );
                            },
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TileCard(
                              flex: 1,
                              useExpanded: false,
                              title: 'Camera',
                              tileColor: Colors.lightBlue[400]!,
                              height: 600,
                              isStatusBar: false,
                              icon: 'images/animations/qEITPsoIMt.json',
                              isImageTile: true,
                              callBack: () {
                                print('Clicked');
                              },
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  height: 310,
                                  margin: const EdgeInsets.all(15),
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                  child: Card(
                                    color: Colors.lightBlue[400]!,
                                    elevation: 4,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        PresetsTile(
                                          title: "Morning",
                                          icon: CupertinoIcons.sunrise_fill,
                                          onTap: () {
                                            print('Morning Preset Clicked');
                                          },
                                        ),
                                        PresetsTile(
                                          title: "Afternoon",
                                          icon: CupertinoIcons.sun_max_fill,
                                          onTap: () {
                                            print('Noon Preset Clicked');
                                          },
                                        ),
                                        PresetsTile(
                                          title: "Evening",
                                          icon: CupertinoIcons.wind,
                                          onTap: () {
                                            print('Evening Preset Clicked');
                                          },
                                        ),
                                        PresetsTile(
                                          title: "Night",
                                          icon: CupertinoIcons.alarm,
                                          onTap: () {
                                            print('Night Preset Clicked');
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: SensorCard(
                                        title: 'Fire Sensor Configuration',
                                        icon: 'images/fire.png',
                                      ),
                                    ),
                                    Expanded(
                                      child: SensorCard(
                                        title: 'Gas Sensor Configuration',
                                        icon: 'images/gas.png',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AcUnitCard(
                              onTap: () {
                                print("AC UNIT CLICKED");
                              },
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: SensorCard(
                                    title: 'Window Sensor Configuration',
                                    icon: 'images/window.png',
                                  ),
                                ),
                                Expanded(
                                  child: SensorCard(
                                    title: 'Lights \nConfiguration',
                                    icon: 'images/light-control.png',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      LockUtility(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
