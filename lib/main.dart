import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:home_automation_tablet/screens/splash_screen.dart';
import 'package:home_automation_tablet/screens/home_screen.dart';
import 'package:home_automation_tablet/utils/app_state.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

// Background message handler (must be top-level)
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message: ${message.notification?.title}');
}

Future<void> _requestAllPermissions() async {
  final permissions = [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
    Permission.locationWhenInUse,
    Permission.notification,
    Permission.storage,
  ];

  await permissions.request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await _requestAllPermissions();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, WidgetBuilder> appRoutes = {
    '/': (context) => SplashScreen(),
    '/home': (context) => HomeScreen(),
  };

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoApp(routes: appRoutes, initialRoute: '/');
    } else {
      return MaterialApp(routes: appRoutes, initialRoute: '/');
    }
  }
}
