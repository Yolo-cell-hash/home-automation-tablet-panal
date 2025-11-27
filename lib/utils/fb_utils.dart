import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseUtils {
  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://iot9systemintegration-default-rtdb.asia-southeast1.firebasedatabase.app/',
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
      String formattedPresetName = presetName.toLowerCase().replaceAll(
        ' ',
        '_',
      );
      DatabaseReference presetRef = getReference(
        '/updates/${formattedPresetName}_preset',
      );

      DataSnapshot snapshot = await presetRef.get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      } else {
        print('⚠️ No data found for $presetName preset');
        return null;
      }
    } catch (e) {
      print('❌ Error reading preset from Firebase: $e');
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
      DatabaseReference connectedRef = _database.ref('. info/connected');
      DataSnapshot snapshot = await connectedRef.get();

      return snapshot.value == true;
    } catch (e) {
      print('❌ Error checking Firebase connection: $e');
      return false;
    }
  }
}
