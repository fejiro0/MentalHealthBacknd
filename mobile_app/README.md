# Mental Health Monitoring Mobile App

A Flutter mobile application for monitoring mental health conditions (Anxiety, Stress, Discomfort) using sensor data from MXChip devices. The app allows caregivers to record baseline values and monitor real-time emotional states.

## Features

- ✅ **User Authentication** - Sign up, Sign in, and Logout
- ✅ **Baseline Recording** - Record baseline values for Anxiety, Stress, and Discomfort
- ✅ **Real-time Monitoring** - Monitor current sensor data and emotional states
- ✅ **Notifications** - Receive notifications when emotional states change
- ✅ **Dashboard** - View current status and quick actions
- ✅ **History Tracking** - View emotional state history

## Project Structure

```
lib/
├── models/              # Data models
│   ├── user_model.dart
│   ├── baseline_model.dart
│   ├── sensor_data_model.dart
│   └── emotional_state_model.dart
├── services/            # Business logic services
│   ├── auth_service.dart
│   ├── firebase_service.dart
│   ├── baseline_service.dart
│   └── notification_service.dart
├── screens/             # UI screens
│   ├── auth/
│   │   ├── sign_in_screen.dart
│   │   └── sign_up_screen.dart
│   ├── home/
│   │   └── dashboard_screen.dart
│   ├── baseline/
│   │   └── baseline_recording_screen.dart
│   └── monitoring/
│       └── monitoring_screen.dart
├── widgets/             # Reusable widgets
│   ├── custom_text_field.dart
│   └── custom_button.dart
├── utils/               # Utilities
│   ├── constants.dart
│   └── app_theme.dart
└── main.dart            # App entry point
```

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (3.4.4 or higher)
- Dart SDK (3.4.4 or higher)
- Firebase project set up
- Android Studio / Xcode (for mobile development)

### 2. Firebase Configuration

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication:
   - Go to Authentication > Sign-in method
   - Enable Email/Password authentication
3. Set up Firebase Realtime Database:
   - Create a Realtime Database
   - Configure database rules (see below)
4. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
5. Configure Firebase for Flutter:
   ```bash
   flutterfire configure
   ```
   This will generate `lib/firebase_options.dart` automatically.

### 3. Firebase Database Rules

Add these rules to your Firebase Realtime Database:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    },
    "baselines": {
      "$uid": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "devices": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "emotional_states": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "auth != null"
      }
    }
  }
}
```

### 4. Update Firebase Configuration

After running `flutterfire configure`, update `lib/main.dart` to uncomment Firebase initialization:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MyApp());
}
```

### 5. Android Configuration

#### Update `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34
    minSdkVersion 21
    targetSdkVersion 34
    // ... other settings
}
```

#### Update `android/app/src/main/AndroidManifest.xml`:

Add internet permission (if not already present):

```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- ... other permissions -->
</manifest>
```

### 6. iOS Configuration (if developing for iOS)

Update `ios/Podfile`:
```ruby
platform :ios, '12.0'
```

Run:
```bash
cd ios
pod install
```

### 7. Install Dependencies

```bash
flutter pub get
```

### 8. Run the App

```bash
flutter run
```

## Usage

### Sign Up / Sign In

1. Launch the app
2. If you don't have an account, tap "Sign Up"
3. Fill in your details:
   - Full Name
   - Email
   - Select role: Caregiver or Patient
   - Password (minimum 6 characters)
   - Confirm Password
4. Tap "Sign Up" to create your account
5. If you already have an account, use "Sign In"

### Recording Baselines

1. From the Dashboard, tap "Record Baselines"
2. Wait for sensor data to be available
3. Select the condition (Anxiety, Stress, or Discomfort)
4. Tap "Record Now" to capture current sensor values as baseline
   - Or tap "Initialize (Zero)" to set baseline to zero values
5. The baseline will be saved and used for comparison

### Real-time Monitoring

1. From the Dashboard, tap "Real-time Monitoring"
2. View current sensor data:
   - Temperature
   - Humidity
   - Motion (magnitude, X, Y, Z)
   - Sound level
3. View current emotional state:
   - State type (Normal, Anxiety, Stress, Discomfort)
   - Confidence level
   - Key indicators
4. View emotional state history

### Notifications

The app will automatically send notifications when:
- An emotional state is detected (Anxiety, Stress, or Discomfort)
- The state changes from normal to a detected condition
- Confidence level is above 70%
- At least 5 minutes have passed since the last notification (cooldown)

## Configuration

### Device ID

Update the default device ID in `lib/utils/constants.dart`:

```dart
static const String defaultDeviceId = 'MXCHIP_001';
```

### Notification Settings

Adjust notification thresholds in `lib/utils/constants.dart`:

```dart
static const double defaultConfidenceThreshold = 0.7;
static const int notificationCooldownMinutes = 5;
```

## Troubleshooting

### Firebase Connection Issues

- Verify Firebase configuration in `firebase_options.dart`
- Check Firebase project settings
- Ensure internet permission is granted
- Verify database rules allow authenticated access

### Notification Not Appearing

- Grant notification permissions when prompted
- Check device notification settings
- Verify notification service is initialized in `main.dart`

### Sensor Data Not Showing

- Verify MXChip device is connected and sending data
- Check Firebase Realtime Database for data under `/devices/{deviceId}/current`
- Ensure Firebase service is properly configured

## Dependencies

Key dependencies used in this project:

- `firebase_core` - Firebase initialization
- `firebase_auth` - User authentication
- `firebase_database` - Realtime database access
- `cloud_firestore` - Firestore database (for baselines)
- `provider` - State management
- `flutter_local_notifications` - Local notifications
- `permission_handler` - Request permissions
- `google_fonts` - Custom fonts
- `intl` - Date/time formatting

## License

This project is part of the MXChip Mental Health Monitoring System.

## Support

For issues or questions, please refer to the main project documentation.
