// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:home_automation_tablet/utils/fb_utils.dart';
// import 'package:home_automation_tablet/utils/app_state.dart';
// import 'package:provider/provider.dart';
//
// class AddUserWidget extends StatefulWidget {
//   final RTCVideoRenderer remoteRenderer;
//
//   const AddUserWidget({super.key, required this.remoteRenderer});
//
//   @override
//   State<AddUserWidget> createState() => _AddUserWidgetState();
// }
//
// class _AddUserWidgetState extends State<AddUserWidget> {
//   late String name = '';
//   bool isStreamStarted = false;
//   FirebaseUtils fbUtils = FirebaseUtils();
//   final TextEditingController _nameController = TextEditingController();
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     super.dispose();
//   }
//
//   void _showConfirmDialog() {
//     if (name.trim().isEmpty) {
//       _showAlert(
//         title: 'Error',
//         message: 'Please enter a user name',
//         isDestructive: false,
//       );
//       return;
//     }
//
//     showCupertinoDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (BuildContext context) {
//         return CupertinoAlertDialog(
//           title: const Text('Add User'),
//           content: Text('Are you sure you want to add user with name - $name?'),
//           actions: [
//             CupertinoDialogAction(
//               isDefaultAction: true,
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: const Text('Cancel'),
//             ),
//             CupertinoDialogAction(
//               isDestructiveAction: false,
//               onPressed: () async {
//                 Navigator.pop(context);
//                 await _confirmUser();
//               },
//               child: const Text('Confirm'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<void> _confirmUser() async {
//     final loaderProvider = Provider.of<AppState>(context, listen: false);
//     loaderProvider.showLoader();
//
//     try {
//       DatabaseReference sendFeedState = fbUtils.database.ref(
//         '/dev_env/addUsersFeed',
//       );
//       await sendFeedState.set(true);
//
//       if (kDebugMode) {
//         print('Add users feed started');
//       }
//
//       setState(() {
//         isStreamStarted = true;
//       });
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error starting add users feed: $e');
//       }
//       _showAlert(
//         title: 'Error',
//         message: 'Failed to start add users process: $e',
//         isDestructive: true,
//       );
//     } finally {
//       loaderProvider.hideLoader();
//     }
//   }
//
//   Future<void> _addUser() async {
//     final loaderProvider = Provider.of<AppState>(context, listen: false);
//     loaderProvider.showLoader();
//
//     try {
//       final database = fbUtils.database;
//       await database.ref('/dev_env/addUsers').set(name);
//       await database.ref('/dev_env/addUsersFeed').set(false);
//       await database.ref('/dev_env/confirm').set(true);
//
//       final DatabaseEvent event = await database
//           .ref('/dev_env/ack')
//           .onValue
//           .skip(1)
//           .first;
//       final DataSnapshot snapshot = event.snapshot;
//
//       if (snapshot.exists) {
//         final data = snapshot.value.toString();
//         loaderProvider.hideLoader();
//
//         if (data.contains('Success')) {
//           _showAlert(
//             title: 'Success',
//             message: data,
//             isDestructive: false,
//             onDismiss: () {
//               Navigator.pop(context);
//             },
//           );
//         } else if (data.contains('Error')) {
//           _showAlert(
//             title: 'Error',
//             message: data,
//             isDestructive: true,
//             onDismiss: () {
//               Navigator.pop(context);
//             },
//           );
//         }
//       } else {
//         loaderProvider.hideLoader();
//         if (kDebugMode) {
//           print('No valid ACK received.');
//         }
//       }
//     } catch (e) {
//       loaderProvider.hideLoader();
//       if (kDebugMode) {
//         print('Error adding user: $e');
//       }
//       _showAlert(
//         title: 'Error',
//         message: 'Failed to add user: $e',
//         isDestructive: true,
//       );
//     }
//   }
//
//   void _showAlert({
//     required String title,
//     required String message,
//     required bool isDestructive,
//     VoidCallback? onDismiss,
//   }) {
//     showCupertinoDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (BuildContext context) {
//         return CupertinoAlertDialog(
//           title: Text(title),
//           content: Text(message),
//           actions: [
//             CupertinoDialogAction(
//               isDestructiveAction: isDestructive,
//               onPressed: () {
//                 Navigator.pop(context);
//                 onDismiss?.call();
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       onPopInvokedWithResult: (didPop, result) async {
//         final loaderProvider = Provider.of<AppState>(context, listen: false);
//         if (didPop) {
//           loaderProvider.showLoader();
//           try {
//             await fbUtils.database.ref('/dev_env/addUsersFeed').set(false);
//           } catch (e) {
//             if (kDebugMode) {
//               print('Error updating add users feed to false: $e');
//             }
//           } finally {
//             loaderProvider.hideLoader();
//           }
//         }
//       },
//       child: CupertinoPageScaffold(
//         backgroundColor: CupertinoColors.systemGroupedBackground,
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 if (!isStreamStarted) ...[
//                   CupertinoTextField(
//                     controller: _nameController,
//                     placeholder: 'Enter User Name',
//                     padding: const EdgeInsets.all(16.0),
//                     decoration: BoxDecoration(
//                       color: CupertinoColors.white,
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     onChanged: (value) {
//                       name = value;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   CupertinoButton.filled(
//                     onPressed: _showConfirmDialog,
//                     borderRadius: BorderRadius.circular(10.0),
//                     child: const Text(
//                       'Confirm Name',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//                 const SizedBox(height: 20),
//                 if (isStreamStarted) ...[
//                   Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12.0),
//                       boxShadow: [
//                         BoxShadow(
//                           color: CupertinoColors.systemGrey.withOpacity(0.3),
//                           blurRadius: 10,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(12.0),
//                       child: SizedBox(
//                         width: 350,
//                         height: 275,
//                         child: InteractiveViewer(
//                           minScale: 1.0,
//                           maxScale: 4.0,
//                           child: RTCVideoView(widget.remoteRenderer),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   CupertinoButton.filled(
//                     onPressed: _addUser,
//                     borderRadius: BorderRadius.circular(10.0),
//                     child: const Text(
//                       'Add User',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
