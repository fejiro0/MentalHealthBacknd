# Schema Analysis & Architecture Review

## 🔍 Current Issues Identified

### ❌ Missing Critical Connections:

1. **No User-to-Device Association**
   - Users register but don't get assigned a device
   - No way to link a caregiver to a patient's device
   - No way to know which device belongs to which user

2. **No Device Management**
   - Hardware uses hardcoded device ID (`MXCHIP_001`)
   - No way to register/manage multiple devices
   - No device assignment workflow

3. **Baseline-to-Device Disconnection**
   - Baselines are stored per userId
   - Sensor data is stored per deviceId
   - No direct connection between them

4. **Backend Schema Mismatch**
   - Realtime Database: `/devices/{deviceId}/current`
   - Firestore: `/baselines/{userId}_{condition}`
   - No linking structure between them

## 📊 Required Architecture

### Data Flow Should Be:

```
Hardware Device (MXChip)
    ↓ [sends sensor data with device_id]
Backend Server (Node.js)
    ↓ [receives & forwards]
Firebase Realtime Database
    ↓ [stores at /devices/{deviceId}/current]
Flutter App
    ↓ [reads based on user's assigned device]
User Interface
    ↓ [records baseline from that device's data]
Firestore
    ↓ [stores baseline linked to userId + deviceId]
Emotional State Processing
    ↓ [compares device data vs baseline]
Notifications & Display
```

## 🔧 Required Schema Structure

### 1. User-Device Association (NEW)

**Firestore Collection: `user_devices`**
```json
{
  "userId": "user123",
  "deviceId": "MXCHIP_001",
  "role": "patient", // or "caregiver"
  "assignedAt": "2025-01-15T10:00:00Z",
  "isActive": true,
  "patientId": "patient456" // if caregiver, link to patient
}
```

### 2. Updated User Model (Enhanced)

```dart
class UserModel {
  String uid;
  String email;
  String? name;
  String role; // 'caregiver' or 'patient'
  String? assignedDeviceId; // NEW: Device assigned to this user
  String? patientId; // NEW: If caregiver, which patient they monitor
  List<String>? deviceIds; // NEW: Multiple devices support
}
```

### 3. Device Registration (NEW)

**Realtime Database: `/devices/{deviceId}/metadata`**
```json
{
  "deviceId": "MXCHIP_001",
  "name": "Patient Device 1",
  "assignedUserId": "user123",
  "registeredAt": "2025-01-15T10:00:00Z",
  "lastSeen": "2025-01-15T15:30:00Z",
  "status": "active"
}
```

### 4. Updated Baseline Structure

**Firestore: `/baselines/{userId}_{deviceId}_{condition}`**
```json
{
  "userId": "user123",
  "deviceId": "MXCHIP_001", // NEW: Link to specific device
  "condition": "anxiety",
  "sensorValues": {...},
  "recordedAt": "2025-01-15T10:00:00Z"
}
```

### 5. Updated Emotional State Structure

**Realtime Database: `/emotional_states/{userId}/current`**
```json
{
  "userId": "user123",
  "deviceId": "MXCHIP_001", // NEW: Which device detected this
  "state": "anxiety",
  "confidence": 0.85,
  "detectedAt": "2025-01-15T15:30:00Z"
}
```

## 🎯 Solution Implementation Plan

### Phase 1: User-Device Association
1. Add device assignment screen in Flutter
2. Update UserModel to include deviceId
3. Create device registration endpoints in backend
4. Update Firebase schema to include user_devices

### Phase 2: Device Management
1. Device selection/assignment UI
2. Device registration workflow
3. Multi-device support for caregivers
4. Device status tracking

### Phase 3: Schema Alignment
1. Update baseline storage to include deviceId
2. Update emotional state to include deviceId
3. Ensure all queries filter by user + device

### Phase 4: Data Flow Verification
1. Hardware → Backend → Database ✅
2. User → Device Assignment ✅
3. Device → Baseline Recording ✅
4. Device Data → Emotional State ✅

## 🔗 Complete Connection Chain

```
USER REGISTRATION
  ↓
ASSIGN DEVICE (caregiver assigns to patient OR patient assigns to self)
  ↓
DEVICE METADATA STORED (/devices/{deviceId}/metadata)
  ↓
HARDWARE SENDS DATA (/devices/{deviceId}/current)
  ↓
FLUTTER READS USER'S DEVICE (/devices/{user.deviceId}/current)
  ↓
BASELINE RECORDING (linked to userId + deviceId)
  ↓
EMOTIONAL STATE (linked to userId + deviceId)
```

