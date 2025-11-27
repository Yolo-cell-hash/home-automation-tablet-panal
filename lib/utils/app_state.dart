import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  bool _spinner = false;
  dynamic _update;
  dynamic _isWindowOpen;
  dynamic _isFire;
  dynamic _lightsStatus;
  dynamic _gasLeak;
  bool _isConnected = true;
  DateTime? _lastUpdateTime;
  bool _isInitialLoadComplete = false;

  dynamic _morning_ac_temp;

  // Getters
  dynamic get morning_ac_temp => _morning_ac_temp;
  dynamic get update => _update;
  dynamic get isWindowOpen => _isWindowOpen;
  dynamic get isFire => _isFire;
  dynamic get lightsStatus => _lightsStatus;
  dynamic get gasLeak => _gasLeak;
  bool get spinner => _spinner;
  bool get isConnected => _isConnected;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  bool get isInitialLoadComplete => _isInitialLoadComplete;

  set spinner(bool newValue) {
    _spinner = newValue;
    notifyListeners();
  }

  void setConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      notifyListeners();
    }
  }

  void setUpdates(dynamic data) {
    try {
      _update = data;
      _lastUpdateTime = DateTime.now();

      // Safely update individual properties if data is a Map
      if (data != null && data is Map) {
        _isWindowOpen = data['isWindowOpen'];
        _isFire = data['isFire'];
        _lightsStatus = data['lightsStatus'];
        _gasLeak = data['gasLeak'] ?? data['isGasLeak']; // Handle both keys

        // Mark initial load as complete after first data load
        if (!_isInitialLoadComplete) {
          _isInitialLoadComplete = true;
          print('Initial data load complete');
        }

        print(
          'AppState updated: Window=${_isWindowOpen}, Fire=${_isFire}, Lights=${_lightsStatus}, Gas=${_gasLeak}',
        );
      } else {
        // Reset to null if no valid data
        _isWindowOpen = null;
        _isFire = null;
        _lightsStatus = null;
        _gasLeak = null;

        print('AppState reset: No valid data received');
      }

      notifyListeners();
    } catch (e) {
      print('Error in setUpdates: $e');
    }
  }

  set isWindowOpen(dynamic data) {
    _isWindowOpen = data;
    notifyListeners();
  }

  set gasLeak(dynamic data) {
    _gasLeak = data;
    notifyListeners();
  }

  set isFire(dynamic data) {
    _isFire = data;
    notifyListeners();
  }

  set lightsStatus(dynamic data) {
    _lightsStatus = data;
    notifyListeners();
  }

  set morning_ac_temp(dynamic value) {
    _morning_ac_temp = value;
    notifyListeners();
  }

  // Helper method to check if data is fresh
  bool get isDataFresh {
    if (_lastUpdateTime == null) return false;
    return DateTime.now().difference(_lastUpdateTime!).inMinutes < 5;
  }

  // Safe getters that return boolean values
  bool get isFireActive {
    if (!_isConnected || _update == null || _update is! Map) return false;
    final fireStatus = _update['isFire']?.toString().toLowerCase();
    return fireStatus == 'true' || fireStatus == '1';
  }

  bool get isWindowOpenActive {
    if (!_isConnected || _update == null || _update is! Map) return false;
    final windowStatus = _update['isWindowOpen']?.toString().toLowerCase();
    return windowStatus == 'true' || windowStatus == '1';
  }

  bool get isGasLeakActive {
    if (!_isConnected || _update == null || _update is! Map) return false;
    // Check both 'gasLeak' and 'isGasLeak' keys
    final gasStatus = (_update['gasLeak'] ?? _update['isGasLeak'])
        ?.toString()
        .toLowerCase();
    return gasStatus == 'true' || gasStatus == '1';
  }

  bool get isLightsOn {
    if (!_isConnected || _update == null || _update is! Map) return false;
    final lightStatus = _update['lightsStatus']?.toString().toLowerCase();
    return lightStatus == 'true' || lightStatus == '1' || lightStatus == 'on';
  }

  // Method to reset initial load flag (useful for testing)
  void resetInitialLoad() {
    _isInitialLoadComplete = false;
    notifyListeners();
  }
}
