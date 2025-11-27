# Home Automation Tablet Panel

A Flutter-based home automation control panel application designed for tablet devices. This app provides a comprehensive interface for monitoring and controlling various smart home features including security sensors, climate control, lighting, and device management.

## Features

### Real-time Monitoring
- **Status Bar**: Live indicators for WiFi connectivity, camera status, fire detection, window sensors, gas leak detection, and lighting status
- **Connection Health**: Automatic retry mechanism with configurable intervals for maintaining Firebase connection
- **Push Notifications**: Firebase Cloud Messaging (FCM) integration for real-time alerts

### Climate Control
- **AC Unit Management**: Configure and control air conditioning settings
- **Temperature Presets**: Pre-configured temperature settings for different times of day

### Security & Safety
- **Fire Sensor Configuration**: Monitor fire detection sensors with alarm and notification settings
- **Gas Sensor Configuration**: Track gas leak detection with customizable alerts
- **Window Sensor Configuration**: Monitor window status with notification options
- **Smart Lock Control**: Manage front door smart lock

### Lighting Control
- **Lights Configuration**: Control and monitor home lighting
- **Customizable Presets**: Save and apply lighting presets

### Time-based Presets
- **Morning Preset**: Optimized settings for morning routines
- **Afternoon Preset**: Balanced settings for daytime
- **Evening Preset**: Comfortable settings for evening
- **Night Preset**: Energy-efficient and secure nighttime settings

### Device Management
- **Front Door Lock**: Smart lock control and monitoring
- **Video Doorbell (VDB)**: Doorbell integration
- **Connectivity Management**: WiFi and network status monitoring

## Screenshots

The application features a modern blue-themed interface optimized for tablet displays with:
- User profile section with avatar
- Real-time status bar with animated alerts
- Camera feed placeholder with Lottie animations
- Sensor configuration cards with detailed preset dialogs
- Device management section

## Tech Stack

- **Framework**: Flutter SDK ^3.9.0
- **State Management**: Provider ^6.1.2
- **Backend**: Firebase Realtime Database
- **Push Notifications**: Firebase Cloud Messaging
- **Animations**: Lottie ^3.3.1, animate_do ^4.2.0
- **UI Components**: 
  - flutter_svg ^2.0.16
  - cupertino_icons ^1.0.8
  - another_flutter_splash_screen ^1.2.1
  - quickalert ^1.1.0
  - modal_progress_hud_nsn ^0.5.0
- **Permissions**: permission_handler ^12.0.1

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── firebase_options.dart     # Firebase configuration (auto-generated)
├── screens/
│   ├── home_screen.dart      # Main dashboard screen
│   └── splash_screen.dart    # App splash/loading screen
├── utils/
│   ├── app_state.dart        # Provider state management
│   └── fb_utils.dart         # Firebase utility functions
└── widgets/
    ├── tile_card.dart        # Reusable tile component
    ├── ac_unit_card.dart     # AC control widget
    ├── sensor_card.dart      # Sensor configuration widget
    ├── presets_tile.dart     # Preset selection widget
    ├── preset_content.dart   # Preset editing dialog content
    └── lock_utility.dart     # Device management section

images/
├── animations/               # Lottie animation files
│   ├── AC.json
│   ├── Fire.json
│   └── ...
├── fire.png                  # Fire sensor icon
├── gas.png                   # Gas sensor icon
├── window.png                # Window sensor icon
├── light-control.png         # Lighting icon
├── smart-lock.png            # Smart lock icon
├── door-bell.png             # Doorbell icon
├── wi-fi-icon.png            # WiFi icon
└── gnb_new_logo_.svg         # App logo
```

## Getting Started

### Prerequisites

- Flutter SDK ^3.9.0
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Firebase project with Realtime Database enabled

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Yolo-cell-hash/home-automation-tablet-panal.git
   cd home-automation-tablet-panal
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   
   The project uses Firebase Realtime Database. To use your own Firebase project:
   
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Realtime Database
   - Run FlutterFire CLI to configure:
     ```bash
     flutterfire configure
     ```
   - Update the database URL in `lib/screens/home_screen.dart` and `lib/utils/fb_utils.dart`

4. **Run the application**
   ```bash
   # For Android
   flutter run -d android

   # For iOS
   flutter run -d ios
   ```

### Firebase Database Structure

The app expects the following structure in Firebase Realtime Database:

```json
{
  "updates": {
    "isFire": false,
    "isWindowOpen": false,
    "gasLeak": false,
    "lightsStatus": false,
    "fcmDeviceToken": "device_token_here",
    "morning_preset": {
      "ac_temp": 22,
      "lights": false,
      "window": true,
      "security": false
    },
    "afternoon_preset": { ... },
    "evening_preset": { ... },
    "night_preset": { ... }
  }
}
```

## Development

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Configuration

### Environment Variables

The app uses Firebase configuration stored in `lib/firebase_options.dart`. This file is auto-generated by FlutterFire CLI and should not be committed with sensitive credentials in production.

### Customizing Presets

Default presets can be modified in `lib/widgets/preset_content.dart`:

```dart
Map<String, Map<String, String>> defaultPresets = {
  'Morning': {
    'AC Temperature': '22°C',
    'Lights': 'Off',
    'Curtains': 'Open',
    'Security': 'Inactive',
  },
  // ... other presets
};
```

## Platform Support

| Platform | Status |
|----------|--------|
| Android  | ✅ Supported |
| iOS      | ✅ Supported |
| Web      | ❌ Not configured |
| macOS    | ❌ Not configured |
| Windows  | ❌ Not configured |
| Linux    | ❌ Not configured |

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

## Architecture

For detailed technical documentation about the app's architecture and design patterns, see [ARCHITECTURE.md](ARCHITECTURE.md).

## License

This project is private and not licensed for public distribution.

## Support

For questions or issues, please open an issue on the GitHub repository.

## Acknowledgments

- Flutter team for the excellent cross-platform framework
- Firebase team for real-time database and cloud messaging
- Lottie for beautiful animations
