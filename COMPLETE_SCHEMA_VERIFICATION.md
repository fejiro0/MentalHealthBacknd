# Complete Schema Verification & Architecture

## ✅ Complete Data Flow Chain

### 1. USER REGISTRATION → DEVICE ASSIGNMENT

```
User Signs Up (Flutter App)
  ↓
User stored in Firestore: /users/{userId}
  ↓
User assigns/links a device (Device Assignment Screen)
  ↓
Device metadata stored: /devices/{deviceId}/metadata (Realtime DB)
  ↓
User document updated: /users/{userId}.assignedDeviceId = deviceId
```

### 2. HARDWARE → BACKEND → DATABASE

```
MXChip Hardware
  ↓ [Sends sensor data via HTTP POST to backend]
Backend Server (Node.js)
  - Receives: POST /sensor-data
  - Extracts: device_id, sensor readings
  - Forwards to Firebase
  ↓
Firebase Realtime Database
  - Stores: /devices/{deviceId}/current
  - Stores: /devices/{deviceId}/history/{timestamp}
```

### 3. FLUTTER APP → DATABASE READING

```
Flutter App
  ↓ [User logged in]
Reads user's assigned device: user.assignedDeviceId
  ↓
Reads sensor data: /devices/{user.assignedDeviceId}/current
  ↓
Displays real-time sensor readings
```

### 4. BASELINE RECORDING (User → Device → Baseline)

```
Caregiver opens Baseline Recording Screen
  ↓
Selects condition (Anxiety/Stress/Discomfort)
  ↓
Reads current sensor data from: /devices/{user.assignedDeviceId}/current
  ↓
Records baseline to: Firestore /baselines/{userId}_{deviceId}_{condition}
  ↓
Baseline now linked to:
  - User (userId)
  - Device (deviceId) 
  - Condition (condition)
```

### 5. REAL-TIME PROCESSING (Device → Baseline → Emotional State)

```
Continuous Monitoring Loop:
  1. Read sensor data: /devices/{deviceId}/current
  2. Read user's baselines: /baselines/{userId}_{deviceId}_{condition}
  3. Compare sensor data vs baseline
  4. Calculate emotional state
  5. Save to: /emotional_states/{userId}/current (includes deviceId)
  6. Send notification if state changed
```

## 📊 Complete Database Schema

### Firebase Realtime Database Structure:

```
/
├── devices/
│   ├── {deviceId}/
│   │   ├── metadata/          # Device registration info
│   │   │   ├── deviceId
│   │   │   ├── name
│   │   │   ├── assignedUserId
│   │   │   ├── patientId
│   │   │   ├── registeredAt
│   │   │   ├── lastSeen
│   │   │   └── status
│   │   ├── current/           # Latest sensor reading
│   │   │   ├── device_id
│   │   │   ├── timestamp
│   │   │   ├── sensors/
│   │   │   ├── temperature
│   │   │   └── humidity
│   │   └── history/
│   │       └── {timestamp}/   # Historical readings
│
├── emotional_states/
│   ├── {userId}/
│   │   ├── current/           # Latest emotional state
│   │   │   ├── userId
│   │   │   ├── deviceId       # NEW: Which device detected this
│   │   │   ├── state
│   │   │   ├── confidence
│   │   │   └── detectedAt
│   │   └── history/
│   │       └── {timestamp}/
│
└── test/                      # Testing endpoint
```

### Cloud Firestore Structure:

```
/
├── users/
│   └── {userId}/
│       ├── uid
│       ├── email
│       ├── name
│       ├── role
│       ├── assignedDeviceId   # NEW: Device assigned to user
│       ├── patientId          # NEW: If caregiver
│       └── createdAt
│
├── devices/
│   └── {deviceId}/            # Mirror of Realtime DB for querying
│       └── [same as metadata]
│
└── baselines/
    └── {userId}_{deviceId}_{condition}/   # NEW: Includes deviceId
        ├── userId
        ├── deviceId           # NEW: Which device this baseline is for
        ├── condition
        ├── sensorValues
        ├── recordedAt
        └── notes
```

## 🔗 Complete Connection Verification

### ✅ Hardware → Backend Connection
- Hardware sends POST to: `http://{PROXY_SERVER_IP}:8081/sensor-data`
- Backend receives and validates
- **Status**: ✅ CONNECTED

### ✅ Backend → Firebase Connection
- Backend forwards to: `/devices/{deviceId}/current`
- Uses Firebase Admin SDK or REST API
- **Status**: ✅ CONNECTED

### ✅ Flutter App → Firebase Connection
- Reads from: `/devices/{deviceId}/current`
- Uses Firebase Realtime Database listener
- **Status**: ⚠️ NEEDS DEVICE ASSIGNMENT

### ✅ User → Device Association
- User registers → Device assignment screen
- Device stored with `assignedUserId`
- User document updated with `assignedDeviceId`
- **Status**: 🆕 NEWLY IMPLEMENTED

### ✅ Baseline → Device Linking
- Baselines now include `deviceId` in document ID
- Format: `{userId}_{deviceId}_{condition}`
- **Status**: 🆕 UPDATED

### ✅ Emotional State → Device Linking
- Emotional states include `deviceId` field
- Links to which device detected the state
- **Status**: 🆕 TO BE UPDATED

## 🎯 Current Status

### ✅ Working:
1. Hardware sends data to backend
2. Backend forwards to Firebase
3. Flutter app can read from Firebase
4. User registration works

### ⚠️ Needs Implementation:
1. Device assignment workflow (SCREEN CREATED)
2. Update all baseline calls to include deviceId
3. Update dashboard to use user's assigned device
4. Update monitoring to use user's assigned device
5. Update Firebase rules for new structure

### 🆕 Newly Created:
1. DeviceModel
2. DeviceService
3. DeviceAssignmentScreen
4. Enhanced UserModel with deviceId

## 📝 Next Steps

1. ✅ Update baseline recording screen to use deviceId
2. ✅ Update dashboard to get user's assigned device
3. ✅ Update monitoring to use user's assigned device
4. ✅ Add device assignment to dashboard
5. ✅ Update Firebase rules
6. ✅ Test complete flow

