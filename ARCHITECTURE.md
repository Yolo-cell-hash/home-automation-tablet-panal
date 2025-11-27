# Architecture Documentation

This document provides detailed technical documentation for the Home Automation Tablet Panel application architecture, design patterns, and implementation details.

## Table of Contents

- [Overview](#overview)
- [Application Architecture](#application-architecture)
- [State Management](#state-management)
- [Firebase Integration](#firebase-integration)
- [Widget Architecture](#widget-architecture)
- [Data Flow](#data-flow)
- [Error Handling](#error-handling)
- [Performance Considerations](#performance-considerations)

## Overview

The Home Automation Tablet Panel is a Flutter application designed to provide a centralized control interface for smart home devices. The app follows a clean architecture pattern with clear separation of concerns between UI, business logic, and data layers.

### Key Design Principles

1. **Separation of Concerns**: UI components, state management, and data access are kept separate
2. **Reactive Programming**: The app uses streams and Provider for reactive UI updates
3. **Widget Composition**: Complex UIs are built by composing smaller, reusable widgets
4. **Platform Adaptability**: The app adapts its appearance based on iOS or Android platform

## Application Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐│
│  │   Screens   │ │   Widgets   │ │    UI Components        ││
│  │ (home_screen│ │ (tile_card, │ │  (dialogs, cards,       ││
│  │  splash_    │ │  sensor_    │ │   status indicators)    ││
│  │  screen)    │ │  card, etc) │ │                         ││
│  └─────────────┘ └─────────────┘ └─────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   State Management Layer                     │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    AppState (Provider)                   ││
│  │  - Connection status    - Sensor states                 ││
│  │  - Update data          - UI flags                      ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│  ┌─────────────────────────┐ ┌─────────────────────────────┐│
│  │    Firebase Utils       │ │     Firebase Services       ││
│  │  (fb_utils.dart)        │ │  (Realtime DB, FCM)         ││
│  └─────────────────────────┘ └─────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Directory Structure Explained

```
lib/
├── main.dart                 # App entry point, Firebase init, Provider setup
├── firebase_options.dart     # Auto-generated Firebase configuration
│
├── screens/                  # Full-page screen widgets
│   ├── home_screen.dart      # Main dashboard with Firebase listeners
│   └── splash_screen.dart    # Loading screen with logo animation
│
├── utils/                    # Business logic and utilities
│   ├── app_state.dart        # Centralized state management
│   └── fb_utils.dart         # Firebase database operations
│
└── widgets/                  # Reusable UI components
    ├── tile_card.dart        # Generic card with multiple display modes
    ├── ac_unit_card.dart     # Air conditioning control card
    ├── sensor_card.dart      # Sensor display with configuration dialog
    ├── presets_tile.dart     # Preset selection button
    ├── preset_content.dart   # Preset editing form
    └── lock_utility.dart     # Device management section
```

## State Management

### Provider Pattern

The app uses the Provider package for state management, implementing a single `AppState` class that serves as the single source of truth.

#### AppState Class Structure

```dart
class AppState extends ChangeNotifier {
  // Connection state
  bool _isConnected = true;
  DateTime? _lastUpdateTime;
  bool _isInitialLoadComplete = false;
  
  // Sensor states
  dynamic _isFire;
  dynamic _isWindowOpen;
  dynamic _lightsStatus;
  dynamic _gasLeak;
  
  // UI state
  bool _spinner = false;
  dynamic _update;
  
  // Preset configurations
  dynamic _morning_ac_temp;
}
```

#### State Update Flow

```
Firebase Event → HomeScreen Listener → AppState.setUpdates() → notifyListeners() → UI Rebuild
```

#### Safe Boolean Getters

The `AppState` class provides type-safe boolean getters that handle various data formats:

```dart
bool get isFireActive {
  if (!_isConnected || _update == null || _update is! Map) return false;
  final fireStatus = _update['isFire']?.toString().toLowerCase();
  return fireStatus == 'true' || fireStatus == '1';
}
```

This pattern ensures:
- Null safety
- Connection awareness
- Multiple data format support (boolean, string, numeric)

### Provider Setup

```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}
```

### Consuming State

```dart
// With rebuilds on state change
final appState = Provider.of<AppState>(context, listen: true);

// Without rebuilds (for updates only)
final appState = Provider.of<AppState>(context, listen: false);
appState.setUpdates(data);
```

## Firebase Integration

### Realtime Database

The app connects to Firebase Realtime Database for live data synchronization.

#### Database Reference

```dart
FirebaseDatabase database = FirebaseDatabase.instanceFor(
  app: firebaseApp,
  databaseURL: 'https://your-project.firebasedatabase.app/',
);
_dbRef = database.ref("updates");
```

#### Data Listener Implementation

```dart
void listenToDatabaseUpdates(DatabaseReference dbRef) {
  _dbSubscription = dbRef.onValue.listen(
    (DatabaseEvent event) {
      // Handle data updates
      if (event.snapshot.exists) {
        final newData = event.snapshot.value;
        appState.setUpdates(newData);
      }
    },
    onError: (error) {
      // Handle connection errors
      _updateConnectionStatus(false);
      _scheduleRetry();
    },
  );
}
```

### Connection Resilience

The app implements a robust reconnection strategy:

```
Initial Connection
       │
       ▼
   Success? ──No──► Schedule Retry (2s delay)
       │                    │
      Yes                   │
       │                    ▼
       ▼            Retry Count < Max?
  Listen to                 │
  Updates              Yes  │  No
       │                │   │
       │                ▼   ▼
       │         Reconnect  Show Error
       │                │
       └────────────────┘
```

Configuration:
- `_maxRetries`: 5 attempts
- `_retryDelay`: 2 seconds between retries
- Health check interval: 30 seconds

### Firebase Cloud Messaging

Push notifications are configured for real-time alerts:

```dart
Future<void> fbPushNotification() async {
  final firebaseMessaging = FirebaseMessaging.instance;
  await firebaseMessaging.requestPermission();
  FirebaseMessaging.onBackgroundMessage(handler);
}
```

### Firebase Utils

The `FirebaseUtils` class provides a clean API for database operations:

```dart
// Save preset
await FirebaseUtils.savePreset('Morning', presetData);

// Read preset
Map<String, dynamic>? data = await FirebaseUtils.readPreset('Morning');

// Listen to preset changes
Stream<DatabaseEvent> stream = FirebaseUtils.listenToPreset('Morning');
```

## Widget Architecture

### TileCard Widget

A flexible card component with multiple display modes:

| Mode | Use Case | Key Properties |
|------|----------|----------------|
| Default | Simple text display | `title`, `tileColor` |
| Status Bar | System status indicators | `isStatusBar: true` |
| Image Tile | Cards with Lottie animations | `isImageTile: true` |
| User Profile | User avatar and name | `isUserProfileTile: true` |

#### Implementation Pattern

```dart
Widget _buildCardContent() {
  if (widget.isStatusBar == true) {
    return _buildStatusBar();
  } else if (widget.isImageTile == true) {
    return _buildImageTile();
  } else if (widget.isUserProfileTile == true) {
    return _buildUserProfile();
  }
  return _buildDefaultTile();
}
```

### SensorCard Widget

Displays sensor information with a configuration dialog:

```
┌─────────────────────┐
│      [Icon]         │
│                     │
│   Sensor Title      │
│                     │
└─────────────────────┘
         │
         │ onTap
         ▼
┌─────────────────────┐
│   AlertDialog       │
│  ┌───────────────┐  │
│  │ PresetContent │  │
│  │ (Edit Form)   │  │
│  └───────────────┘  │
└─────────────────────┘
```

### PresetContent Widget

Handles preset viewing and editing with form fields:

```dart
Map<String, List<String>> dropdownOptions = {
  'Alarm': ['On', 'Off'],
  'Notifications': ['Enabled', 'Disabled'],
  'Access': ['On', 'Off'],
  'Security': ['Active', 'Inactive'],
  'Curtains': ['Open', 'Closed'],
  'Lights': ['Off', 'On'],
};
```

#### Edit Flow

```
View Mode ──► Edit Button ──► Edit Mode
                                  │
                                  ├──► Save ──► Firebase
                                  │
                                  ├──► Reset ──► Default Values
                                  │
                                  └──► Cancel ──► View Mode
```

## Data Flow

### Initial Load Sequence

```
1. main.dart
   └── Firebase.initializeApp()
   └── Provider setup
   
2. SplashScreen
   └── Display logo animation
   └── Navigate to HomeScreen

3. HomeScreen.initState()
   └── Request notification permission
   └── Initialize Firebase reference
   └── Load initial data (_loadInitialData)
   └── Setup real-time listener
   └── Get FCM token
   └── Start health monitoring
```

### Data Update Sequence

```
Firebase DB Change
       │
       ▼
DatabaseEvent received
       │
       ▼
Validate data structure
       │
       ▼
Update local state (setState)
       │
       ▼
Update AppState provider
       │
       ▼
notifyListeners()
       │
       ▼
Consumer widgets rebuild
```

### Preset Save Flow

```
User edits preset
       │
       ▼
Clicks Save button
       │
       ▼
setState: isSaving = true
       │
       ▼
Collect form data
       │
       ▼
FirebaseUtils.savePreset()
       │
       ├─── Success ──► Show SnackBar ──► Exit edit mode
       │
       └─── Error ──► Show error SnackBar
```

## Error Handling

### Connection Errors

```dart
onError: (error) {
  print("Database listener error: $error");
  _updateConnectionStatus(false);
  _scheduleRetry();
}
```

### UI Error Indicator

The home screen displays a connection status banner:

```dart
if (!_isConnected)
  Container(
    color: Colors.red.shade100,
    child: Row(
      children: [
        Icon(Icons.wifi_off, color: Colors.red),
        Text('Connection lost. Retrying... ($_retryCount/$_maxRetries)'),
      ],
    ),
  ),
```

### Firebase Operation Errors

```dart
try {
  await FirebaseUtils.savePreset(presetTitle, data);
  // Show success
} catch (e) {
  // Show error SnackBar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to save: $e')),
  );
}
```

## Performance Considerations

### Widget Rebuilds

- Use `listen: false` when not needing rebuilds
- Extract rebuild-prone widgets into separate components
- Use `const` constructors where possible

### Database Efficiency

- Single listener for all updates vs multiple listeners
- Initial load with `.once()` before setting up stream
- Proper subscription cleanup in `dispose()`

### Memory Management

```dart
@override
void dispose() {
  _dbSubscription?.cancel();
  _retryTimer?.cancel();
  _connectionCheckTimer?.cancel();
  super.dispose();
}
```

### Asset Loading

- Lottie animations with `animate: false` for static display
- SVG for vector graphics (logo)
- PNG for sensor icons

## Security Considerations

### Firebase Rules

Ensure proper Firebase security rules:

```json
{
  "rules": {
    "updates": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

### Sensitive Data

- Firebase API keys in `firebase_options.dart`
- FCM tokens stored in database
- Consider environment-based configuration for production

## Future Improvements

1. **Modular Architecture**: Extract feature modules
2. **Repository Pattern**: Abstract data sources
3. **Unit Testing**: Increase test coverage
4. **Offline Support**: Local caching with sync
5. **Authentication**: Add user authentication
6. **Theming**: Support for light/dark modes
