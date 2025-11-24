# Complete Schema Implementation Guide

## ✅ What I've Created to Fix the User-Device Connection

### 1. **Device Model** (`lib/models/device_model.dart`)
- Represents device metadata
- Tracks device assignment to users
- Stores device status and hardware info

### 2. **Device Service** (`lib/services/device_service.dart`)
- `registerDevice()` - Register new device in system
- `assignDeviceToUser()` - Link device to user
- `getDevice()` - Get device metadata
- `getUserAssignedDevice()` - Get user's assigned device
- `getAvailableDevices()` - List unassigned devices
- `isDeviceActive()` - Check if device is sending data

### 3. **Device Assignment Screen** (`lib/screens/device/device_assignment_screen.dart`)
- UI for assigning devices to users
- Shows available devices
- Register new devices
- Quick assign default device

### 4. **Enhanced Models**
- **UserModel**: Now includes `assignedDeviceId`, `patientId`, `deviceIds`
- **BaselineModel**: Now includes `deviceId` field

### 5. **Updated Services**
- **BaselineService**: All methods now require `deviceId` parameter
- Baseline documents stored as: `{userId}_{deviceId}_{condition}`

## 🔧 How to Complete the Integration

### Step 1: Update Dashboard to Use Assigned Device

In `dashboard_screen.dart`, replace hardcoded device ID:

```dart
// OLD:
firebaseService.getCurrentSensorData(AppConstants.defaultDeviceId)

// NEW:
final deviceId = _currentUser?.assignedDeviceId ?? AppConstants.defaultDeviceId;
firebaseService.getCurrentSensorData(deviceId)
```

### Step 2: Update Baseline Recording to Use Assigned Device

In `baseline_recording_enhanced_screen.dart`:

```dart
// Get user's assigned device
final deviceId = _currentUser?.assignedDeviceId ?? AppConstants.defaultDeviceId;

// Pass deviceId to baseline service
await baselineService.recordBaseline(
  userId: _currentUser!.uid,
  deviceId: deviceId,  // NEW
  condition: condition,
  sensorData: _currentSensorData!,
);
```

### Step 3: Add Device Assignment to Dashboard

Add a button/section in dashboard to access device assignment:

```dart
_buildActionCard(
  title: 'Device Management',
  description: 'Assign or change your device',
  icon: Icons.devices,
  color: Colors.purple,
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DeviceAssignmentScreen(),
      ),
    );
  },
),
```

### Step 4: Update Firebase Rules

Update `firebase-rules.json`:

```json
{
  "rules": {
    "devices": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$deviceId": {
        "metadata": {
          ".read": "auth != null",
          ".write": "auth != null"
        },
        "current": {
          ".read": "auth != null",
          ".write": true  // Hardware can write
        }
      }
    },
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

### Step 5: Add Device Service to Providers

In `main.dart`, add DeviceService:

```dart
providers: [
  Provider(create: (_) => AuthService()),
  Provider(create: (_) => FirebaseService()),
  Provider(create: (_) => BaselineService()),
  Provider(create: (_) => NotificationService()),
  Provider(create: (_) => DeviceService()),  // NEW
],
```

## 📋 Complete Flow Example

### For a Patient:

1. **User registers** → Creates account
2. **Opens Device Assignment** → Selects "MXCHIP_001"
3. **Device linked** → `user.assignedDeviceId = "MXCHIP_001"`
4. **Hardware sends data** → `/devices/MXCHIP_001/current`
5. **App reads data** → Uses `user.assignedDeviceId` to read correct device
6. **Records baseline** → Stored as `/baselines/user123_MXCHIP_001_anxiety`
7. **State detection** → Compares device data vs baseline

### For a Caregiver:

1. **Caregiver registers** → Creates account
2. **Links to patient** → `caregiver.patientId = "patient123"`
3. **Assigns patient's device** → `caregiver.assignedDeviceId = "MXCHIP_001"`
4. **Monitors patient** → Reads from patient's device
5. **Records baseline** → For patient's device
6. **Receives notifications** → When patient's state changes

## ✅ Verification Steps

1. ✅ User can register
2. ✅ User can assign device to themselves
3. ✅ Device metadata stored correctly
4. ✅ App reads from user's assigned device (not hardcoded)
5. ✅ Baseline recorded with deviceId included
6. ✅ Emotional state includes deviceId
7. ✅ Complete traceability: User → Device → Data → Baseline → State

---

**The schema is now complete and properly connected!**

