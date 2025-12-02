import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:home_automation_tablet/utils/app_state.dart';

class FirebaseUtils {
  late DatabaseReference _dbRef1;
  StreamSubscription<DatabaseEvent>? _dbSubscription, _dbSubscription1;
  dynamic dbResponse1;
  late FirebaseApp firebaseApp;
  late FirebaseDatabase database;
  late String ipType;
  late bool wifiState;

  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://vdb-poc-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );

  /// Get a reference to a specific path in the database
  static DatabaseReference getReference(String path) {
    return _database.ref(path);
  }

  /// Save preset data to Firebase
  ///
  /// [presetName] - The name of the preset (e.g., 'morning', 'evening')
  /// [presetData] - Map containing the preset configuration values
  static Future<void> savePreset(
    String presetName,
    Map<String, String> presetData,
  ) async {
    try {
      // Convert preset name to lowercase and replace spaces with underscore
      String formattedPresetName = presetName.toLowerCase().replaceAll(
        ' ',
        '_',
      );

      // Reference to the preset path
      DatabaseReference presetRef = getReference(
        '/updates/${formattedPresetName}_preset',
      );

      // Convert the preset data to the required format
      Map<String, dynamic> firebaseData = _convertToFirebaseFormat(presetData);

      // Save to Firebase
      await presetRef.set(firebaseData);

      print('✅ Successfully saved $presetName preset to Firebase');
    } catch (e) {
      print('❌ Error saving preset to Firebase: $e');
      rethrow;
    }
  }

  /// Convert preset data to Firebase format
  /// Converts string values to appropriate types (bool, int, etc.)
  static Map<String, dynamic> _convertToFirebaseFormat(
    Map<String, String> presetData,
  ) {
    Map<String, dynamic> firebaseData = {};

    presetData.forEach((key, value) {
      String firebaseKey = _convertKeyToFirebaseFormat(key);
      dynamic firebaseValue = _convertValueToFirebaseFormat(key, value);

      if (firebaseValue != null) {
        firebaseData[firebaseKey] = firebaseValue;
      }
    });

    return firebaseData;
  }

  /// Convert display key names to Firebase key format
  /// Example: 'AC Temperature' -> 'ac_temp'
  static String _convertKeyToFirebaseFormat(String key) {
    switch (key) {
      case 'AC Temperature':
        return 'ac_temp';
      case 'Lights':
        return 'lights';
      case 'Security':
        return 'security';
      case 'Curtains':
        return 'window';
      case 'Alarm':
        return 'alarm';
      case 'Notifications':
        return 'notifications';
      case 'Access':
        return 'access';
      default:
        // Default: convert to lowercase and replace spaces with underscore
        return key.toLowerCase().replaceAll(' ', '_');
    }
  }

  /// Convert string values to appropriate Firebase types
  static dynamic _convertValueToFirebaseFormat(String key, String value) {
    switch (key) {
      // Boolean fields
      case 'Lights':
        return _stringToBool(value);
      case 'Security':
        return _stringToBool(value);
      case 'Curtains':
      case 'Window Sensor Configuration':
        return _stringToBool(value);
      case 'Alarm':
        return value.toLowerCase() == 'on';
      case 'Notifications':
        return value.toLowerCase() == 'enabled';
      case 'Access':
        return value.toLowerCase() == 'on';

      // Temperature field - extract numeric value
      case 'AC Temperature':
        return _extractTemperature(value);

      // Keep as string for other fields
      default:
        return value;
    }
  }

  /// Read data from a specific Firebase path
  ///
  /// [path] - The full path to read from (e.g., '/updates/fire_sensor_configs')
  /// Returns a Future with the data or null if not found
  static Future<Map<String, dynamic>?> readFromPath(String path) async {
    try {
      print('📖 Reading from path: $path');

      DatabaseReference ref = getReference(path);
      DataSnapshot snapshot = await ref.get();

      if (snapshot.exists) {
        Map<String, dynamic> data = Map<String, dynamic>.from(
          snapshot.value as Map,
        );
        print('✅ Successfully read data from $path: $data');
        return data;
      } else {
        print('⚠️ No data found at $path');
        return null;
      }
    } catch (e) {
      print('❌ Error reading from path $path: $e');
      return null;
    }
  }

  /// Write data to a specific Firebase path
  ///
  /// [path] - The full path to write to (e.g., '/updates/fire_sensor_configs')
  /// [data] - Map containing the data to write
  static Future<void> writeToPath(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      print('✍️ Writing to path: $path');
      print('Data: $data');

      DatabaseReference ref = getReference(path);
      await ref.update(data);

      print('✅ Successfully wrote data to $path');
    } catch (e) {
      print('❌ Error writing to path $path: $e');
      rethrow;
    }
  }

  /// Convert string representation to boolean
  static bool _stringToBool(String value) {
    String lowerValue = value.toLowerCase();

    // Handle different boolean representations
    if (lowerValue == 'on' ||
        lowerValue == 'active' ||
        lowerValue == 'enabled' ||
        lowerValue == 'open' ||
        lowerValue == 'auto') {
      return true;
    } else if (lowerValue == 'off' ||
        lowerValue == 'inactive' ||
        lowerValue == 'disabled' ||
        lowerValue == 'closed') {
      return false;
    }

    // Default to false if can't parse
    return false;
  }

  /// Extract temperature value from string (e.g., '22°C' -> 22)
  static int _extractTemperature(String tempString) {
    // Remove non-numeric characters except minus sign
    String numericString = tempString.replaceAll(RegExp(r'[^0-9-]'), '');

    try {
      return int.parse(numericString);
    } catch (e) {
      print('⚠️ Could not parse temperature: $tempString, defaulting to 22');
      return 22; // Default temperature
    }
  }

  /// Read preset data from Firebase
  ///
  /// [presetName] - The name of the preset to read
  /// Returns a Future with the preset data or null if not found
  static Future<Map<String, dynamic>?> readPreset(String presetName) async {
    try {
      // Convert to lowercase and add _preset suffix
      String formattedPresetName = presetName.toLowerCase().replaceAll(
        ' ',
        '_',
      );

      if (!formattedPresetName.endsWith('_preset')) {
        formattedPresetName = '${formattedPresetName}_preset';
      }

      // Read the nested preset data
      DatabaseReference presetRef = getReference(
        '/updates/$formattedPresetName',
      );

      print('📖 Reading from path: /updates/$formattedPresetName');

      DataSnapshot snapshot = await presetRef.get();

      if (snapshot.exists) {
        Map<String, dynamic> data = Map<String, dynamic>.from(
          snapshot.value as Map,
        );
        print('✅ Successfully read $presetName: $data');
        return data;
      } else {
        print('⚠️ No data found at /updates/$formattedPresetName');
        return null;
      }
    } catch (e) {
      print('❌ Error reading preset: $e');
      return null;
    }
  }

  /// Listen to preset changes in real-time
  ///
  /// [presetName] - The name of the preset to listen to
  /// [onData] - Callback function when data changes
  static Stream<DatabaseEvent> listenToPreset(String presetName) {
    String formattedPresetName = presetName.toLowerCase().replaceAll(' ', '_');
    DatabaseReference presetRef = getReference(
      '/updates/${formattedPresetName}_preset',
    );

    return presetRef.onValue;
  }

  /// Delete a preset from Firebase
  static Future<void> deletePreset(String presetName) async {
    try {
      String formattedPresetName = presetName.toLowerCase().replaceAll(
        ' ',
        '_',
      );
      DatabaseReference presetRef = getReference(
        '/updates/${formattedPresetName}_preset',
      );

      await presetRef.remove();
      print('✅ Successfully deleted $presetName preset from Firebase');
    } catch (e) {
      print('❌ Error deleting preset from Firebase: $e');
      rethrow;
    }
  }

  /// Update specific field in a preset
  static Future<void> updatePresetField(
    String presetName,
    String fieldKey,
    dynamic value,
  ) async {
    try {
      String formattedPresetName = presetName.toLowerCase().replaceAll(
        ' ',
        '_',
      );
      String firebaseKey = _convertKeyToFirebaseFormat(fieldKey);

      DatabaseReference fieldRef = getReference(
        '/updates/${formattedPresetName}_preset/$firebaseKey',
      );

      await fieldRef.set(value);
      print('✅ Successfully updated $fieldKey in $presetName preset');
    } catch (e) {
      print('❌ Error updating preset field: $e');
      rethrow;
    }
  }

  /// Check database connection
  static Future<bool> checkConnection() async {
    try {
      DatabaseReference connectedRef = _database.ref('.info/connected');
      DataSnapshot snapshot = await connectedRef.get();

      return snapshot.value == true;
    } catch (e) {
      print('❌ Error checking Firebase connection: $e');
      return false;
    }
  }

  // FIXED: Constructor name must match class name
  FirebaseUtils() {
    firebaseApp = Firebase.app();
    database = FirebaseDatabase.instanceFor(
      app: firebaseApp,
      databaseURL:
          'https://vdb-poc-default-rtdb.asia-southeast1.firebasedatabase.app/',
    );
  }

  Future<Map<String, dynamic>> backgroundListen(
    Future<FirebaseApp> initialization,
    BuildContext context,
  ) async {
    final completer = Completer<Map<String, dynamic>>();
    initialization.then((firebaseApp) {
      FirebaseDatabase database = FirebaseDatabase.instanceFor(
        app: firebaseApp,
        databaseURL:
            'https://vdb-poc-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );
      _dbRef1 = database.ref("dev_env");

      _dbSubscription = _dbRef1.onValue.listen(
        (DatabaseEvent event) {
          if (event.snapshot.exists) {
            dbResponse1 = event.snapshot.value;
            final appState = Provider.of<AppState>(context, listen: false);
            if (dbResponse1 is Map) {
              appState.setWifiState(dbResponse1['wifi_state']);
            }

            print("Data updated: ${event.snapshot.value}");

            if (!completer.isCompleted) {
              if (dbResponse1 is Map) {
                completer.complete(Map<String, dynamic>.from(dbResponse1));
              } else {
                completer.complete({});
              }
            }
          } else {
            dbResponse1 = null;
            print("No data at path");
            if (!completer.isCompleted) {
              completer.complete({});
            }
          }
        },
        onError: (error) {
          print("Error listening to database: $error");
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );
    });
    return completer.future;
  }

  Future<void> handler(RemoteMessage message) async {
    print('Title : ${message.notification!.title}');
    print('Title : ${message.notification!.body}');
  }

  Future<void> fbPushNotification() async {
    final firebaseMessaging = FirebaseMessaging.instance;
    await firebaseMessaging.requestPermission();
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  Future<String?> readIpType() async {
    try {
      final dbRef = FirebaseDatabase.instance.ref('dev_env/ip_type');
      final snapshot = await dbRef.get();
      if (snapshot.exists) {
        ipType = snapshot.value as String;
        return ipType;
      }
      return null;
    } catch (e) {
      print("Error reading IP Type: $e");
      return null;
    }
  }

  // Add this method to fb_utils.dart in the FirebaseUtils class

  /// Listen to IP address changes in real-time
  /// IP is always stored at /dev_env/ipv6 regardless of type
  StreamSubscription<DatabaseEvent> listenToIpAddress({
    required Function(String ip, String ipType) onIpChanged,
  }) {
    DatabaseReference ipRef = database.ref('dev_env');

    return ipRef.onValue.listen(
      (DatabaseEvent event) {
        if (event.snapshot.exists) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;

          String? ip = data['ipv6']?.toString();
          String? ipType = data['ip_type']?.toString();

          print('🔍 Firebase update: ipv6=$ip, ipType=$ipType');

          if (ip != null &&
              ip.isNotEmpty &&
              ipType != null &&
              ipType.isNotEmpty) {
            print('📡 IP Address changed: $ip (Type: $ipType)');
            onIpChanged(ip, ipType);
          } else {
            print('⚠️ Invalid IP data: ip=$ip, type=$ipType');
          }
        }
      },
      onError: (error) {
        print('❌ Error listening to IP address: $error');
      },
    );
  }

  /// Read initial IP address from Firebase
  Future<Map<String, String?>> readIpAddress() async {
    try {
      final dbRef = database.ref('dev_env');
      final snapshot = await dbRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        String? ip = data['ipv6']?.toString();
        String? ipType = data['ip_type']?.toString();

        print('🔍 Raw Firebase data: ipv6=$ip, ipType=$ipType');

        if (ip == null || ip.isEmpty) {
          print('⚠️ Warning: IP address is empty at /dev_env/ipv6');
          return {'ip': null, 'ipType': ipType};
        }

        print('📖 Read IP: $ip (Type: $ipType)');

        return {'ip': ip, 'ipType': ipType};
      } else {
        print('❌ No data exists at /dev_env');
      }

      return {'ip': null, 'ipType': null};
    } catch (e) {
      print('❌ Error reading IP address: $e');
      return {'ip': null, 'ipType': null};
    }
  }

  Future<bool> readWifiState() async {
    try {
      final dbRef = FirebaseDatabase.instance.ref('dev_env/wifi_state');
      final snapshot = await dbRef.get();
      if (snapshot.exists) {
        wifiState = snapshot.value as bool;
        print('Wifi State - $wifiState');
        return wifiState;
      } else {
        print('Wifi State - $wifiState');
        return false;
      }
    } catch (e) {
      print("Error reading WiFi State - $e");
      return false;
    }
  }

  Future<void> getNotifPermission() async {
    var status = await Permission.notification.status;
    if (status.isDenied) {
      Permission.notification.request();
    }
    if (await Permission.location.isRestricted) {
      Permission.notification.request();
    }
  }
}
