# Quick Setup Guide

## Step-by-Step Setup

### 1. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Make sure FlutterFire CLI is in your PATH.

### 2. Configure Firebase

Navigate to the `mobile_app` directory and run:

```bash
flutterfire configure
```

This will:
- Detect your Firebase projects
- Allow you to select a project
- Generate `lib/firebase_options.dart` automatically
- Configure Firebase for Android and iOS

### 3. Enable Firebase Services

In your Firebase Console:

1. **Authentication**:
   - Go to Authentication > Sign-in method
   - Enable "Email/Password"

2. **Realtime Database**:
   - Create a Realtime Database
   - Start in test mode initially, then update rules

3. **Cloud Firestore** (for baselines):
   - Go to Firestore Database
   - Create database
   - Start in test mode initially

### 4. Update Database Rules

#### Realtime Database Rules:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
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

#### Firestore Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /baselines/{baselineId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 5. Uncomment Firebase Initialization

Open `lib/main.dart` and uncomment the Firebase initialization:

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

### 6. Update Device ID (Optional)

If your device ID is different from `MXCHIP_001`, update it in `lib/utils/constants.dart`:

```dart
static const String defaultDeviceId = 'YOUR_DEVICE_ID';
```

### 7. Run the App

```bash
flutter run
```

## Testing

1. **Sign Up**: Create a new account
2. **Sign In**: Log in with your credentials
3. **Record Baseline**: Navigate to "Record Baselines" and record a baseline
4. **Monitor**: Navigate to "Real-time Monitoring" to see sensor data

## Common Issues

### Issue: Firebase not initialized error

**Solution**: Make sure you've run `flutterfire configure` and uncommented Firebase initialization in `main.dart`.

### Issue: Authentication not working

**Solution**: 
- Verify Email/Password is enabled in Firebase Console
- Check Firebase project settings
- Ensure `firebase_options.dart` is generated correctly

### Issue: Database permission denied

**Solution**: Update Firebase database rules as shown above.

### Issue: Notifications not working

**Solution**:
- Grant notification permissions when prompted
- Check Android/iOS permission settings
- Verify notification service is initialized

## Next Steps

1. Connect your MXChip device
2. Ensure sensor data is being sent to Firebase
3. Record baselines for conditions
4. Monitor real-time emotional states
5. Receive notifications when states change

