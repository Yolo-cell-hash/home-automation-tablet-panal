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

  bool _isLoading = false;
  bool _otpSent = false;
  bool _isStreamSubscribed = false;
  bool _survailanceModeEnabled = false;
  bool _wifiState = false;

  String _macAddress = '';
  String _ip = '';
  String _fcmToken = '';
  String _selectedUserName = '';
  String? _selectedUserId;
  String _phoneNumber = '';
  String _accessToekn = '';
  String _refreshToken = '';
  String _lockID = '';
  String _ipType = '';

  dynamic _otp;

  bool get otpSent => _otpSent;
  bool get isLoading => _isLoading;
  bool get survailanceModeEnabled => _survailanceModeEnabled;
  bool get isStreamSubscribed => _isStreamSubscribed;
  bool get wifiState => _wifiState;

  String get macAddress => _macAddress;
  String get ip => _ip;
  String get ipType => _ipType;
  String get fcmToken => _fcmToken;
  String get selectedUserName => _selectedUserName;
  String? get selectedUserId => _selectedUserId;
  String get phoneNumber => _phoneNumber;
  String get accessToken => _accessToekn;
  String get refreshToken => _refreshToken;
  String get lockID => _lockID;

  dynamic get otp => _otp;

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

  void setIpType(String ipType) {
    _ipType = ipType;
    notifyListeners();
  }

  void setIpAddress(String ip, String ipType) {
    _ip = ip;
    _ipType = ipType;
    notifyListeners();
    print('📱 AppState updated: IP=$ip, Type=$ipType');
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

  void setStreamSubscribed(bool value) {
    _isStreamSubscribed = value;
    notifyListeners();
  }

  void setSurvailanceMode(bool value) {
    _survailanceModeEnabled = value;
    notifyListeners();
  }

  void setWifiState(bool newValue) {
    _wifiState = newValue;
    notifyListeners();
  }

  void showLoader() {
    _isLoading = true;
    notifyListeners();
  }

  void hideLoader() {
    _isLoading = false;
    notifyListeners();
  }

  void setMacAddress(String macAddress) {
    _macAddress = macAddress;
    notifyListeners();
  }

  set lockID(String newValue) {
    _lockID = newValue;
    notifyListeners();
  }

  void setIp(String ip) {
    _ip = ip;
    notifyListeners();
  }

  void setFcmToken(String fcmToken) {
    _fcmToken = fcmToken;
    notifyListeners();
  }

  void setSelectedUser(String userId, String userName) {
    _selectedUserId = userId;
    _selectedUserName = userName;
    notifyListeners();
  }

  void clearSelection() {
    _selectedUserId = null;
    _selectedUserName = '';
    notifyListeners();
  }

  set otpSent(bool newValue) {
    _otpSent = newValue;
    notifyListeners();
  }

  set otp(dynamic newValue) {
    _otp = newValue;
    notifyListeners();
  }

  set phoneNumber(String newValue) {
    _phoneNumber = newValue;
    notifyListeners();
  }

  set accessToken(String newValue) {
    _accessToekn = newValue;
    notifyListeners();
  }

  set refreshToken(String newValue) {
    _refreshToken = newValue;
    notifyListeners();
  }
}
