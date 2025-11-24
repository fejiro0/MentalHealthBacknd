# Complete Schema Architecture - User, Device, Data Connection

## 🔴 Current Problem

**MISSING LINK**: No connection between Users and Devices
- Hardware sends data to `/devices/MXCHIP_001/current`
- Flutter app reads from hardcoded `MXCHIP_001`
- No way to assign device to user
- No way for caregiver to monitor specific patient's device
- Baselines stored per userId but sensor data per deviceId - **DISCONNECTED**

## ✅ Required Complete Schema

### 1. User Model (Enhanced with Device Association)
```
/users/{userId} (Firestore)
{
  uid: string
  email: string
  name: string
  role: "caregiver" | "patient"
  assignedDeviceId: string | null  // NEW: Device assigned to this user
  patientId: string | null         // NEW: If caregiver, which patient they monitor
  devices: [deviceId1, deviceId2]  // NEW: Multiple devices support
  createdAt: timestamp
}
```

### 2. Device Registration & Metadata
```
/devices/{deviceId}/metadata (Realtime Database)
{
  deviceId: string
  name: string
  assignedUserId: string | null
  patientId: string | null         // If monitoring a patient
  registeredAt: timestamp
  lastSeen: timestamp
  status: "active" | "inactive" | "offline"
  hardwareInfo: {
    model: "MXChip AZ3166"
    firmwareVersion: "1.0"
  }
}

/devices/{deviceId}/current (Realtime Database) - Sensor Data
{
  device_id: string
  timestamp: number
  sensors: {...}
  temperature: number
  humidity: number
  received_at: string
}
```

### 3. User-Device Association (NEW Collection)
```
/user_devices/{userId} (Firestore) - Alternative approach
{
  userId: string
  primaryDeviceId: string
  devices: [
    {
      deviceId: string
      name: string
      assignedAt: timestamp
      isActive: boolean
      role: "own" | "monitoring"  // own device or monitoring someone else's
      patientId: string | null     // if monitoring
    }
  ]
}
```

### 4. Enhanced Baseline Structure
```
/baselines/{userId}_{deviceId}_{condition} (Firestore)
{
  userId: string
  deviceId: string              // NEW: Which device this baseline is for
  condition: "anxiety" | "stress" | "discomfort"
  sensorValues: {
    temperature: number
    humidity: number
    motion_magnitude: number
    ...
  }
  recordedAt: timestamp
  notes: string | null
}
```

### 5. Enhanced Emotional State Structure
```
/emotional_states/{userId}/current (Realtime Database)
{
  userId: string
  deviceId: string              // NEW: Which device detected this state
  state: "normal" | "anxiety" | "stress" | "discomfort" | "unknown"
  confidence: number (0.0-1.0)
  indicators: {...}
  detectedAt: timestamp
}
```

## 🔗 Complete Data Flow

```
1. USER REGISTRATION
   User signs up → Stored in /users/{userId}
   ↓

2. DEVICE ASSIGNMENT (NEW STEP)
   User assigns/links a device:
   - Option A: Patient assigns their own device
   - Option B: Caregiver assigns patient's device
   → Stored in /devices/{deviceId}/metadata
   → Updated in /users/{userId}.assignedDeviceId
   ↓

3. HARDWARE SENDS DATA
   MXChip → Backend Server → /devices/{deviceId}/current
   ↓

4. FLUTTER APP READS
   App reads user's assigned device: /devices/{user.assignedDeviceId}/current
   ↓

5. BASELINE RECORDING
   Caregiver records baseline → /baselines/{userId}_{deviceId}_{condition}
   ↓

6. REAL-TIME PROCESSING
   Compare /devices/{deviceId}/current vs /baselines/{userId}_{deviceId}_{condition}
   → Calculate emotional state
   → Save to /emotional_states/{userId}/current
   ↓

7. NOTIFICATIONS & DISPLAY
   Show state to caregiver/user
```

## 🎯 Implementation Required

### Phase 1: User-Device Association
1. ✅ Update UserModel to include deviceId
2. ✅ Create device assignment screen
3. ✅ Device registration endpoint in backend
4. ✅ Update Firestore/Realtime Database schema

### Phase 2: Device Selection UI
1. ✅ Device selection/assignment screen
2. ✅ Device list/discovery
3. ✅ Caregiver-patient device linking

### Phase 3: Schema Updates
1. ✅ Update baseline queries to include deviceId
2. ✅ Update emotional state to include deviceId
3. ✅ Ensure all reads filter by user + device

### Phase 4: Backend Device Management
1. ✅ Device registration API
2. ✅ Device-user linking API
3. ✅ Device status tracking

