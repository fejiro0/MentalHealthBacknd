# Firebase Data Locations Guide

## 📍 Where to Find Your Data in Firebase

### 1. **Emotional States (Anxiety, Stress, Discomfort, Normal)**

**Location:** Firebase Realtime Database

**Path Structure:**
```
/emotional_states/
  └── {userId}/
      ├── current/          ← CURRENT emotional state
      │   ├── state: "anxiety" | "stress" | "discomfort" | "normal" | "unknown"
      │   ├── confidence: 0.0-1.0
      │   ├── indicators: {...}
      │   └── detectedAt: "2024-01-01T12:00:00Z"
      │
      └── history/          ← HISTORY of emotional states
          └── {timestamp}/
              ├── state: "anxiety"
              ├── confidence: 0.85
              ├── indicators: {...}
              └── detectedAt: "2024-01-01T12:00:00Z"
```

**Example:**
- User ID: `btUZnuxKRUZn7wudiXQ0bFhYY7s1`
- Current state: `/emotional_states/btUZnuxKRUZn7wudiXQ0bFhYY7s1/current`
- History: `/emotional_states/btUZnuxKRUZn7wudiXQ0bFhYY7s1/history/`

**How to View:**
1. Go to Firebase Console
2. Click "Realtime Database"
3. Navigate to: `emotional_states` → `{your-user-id}` → `current`
4. You'll see: `state: "anxiety"` or `state: "stress"` etc.

---

### 2. **Baselines (Anxiety, Stress, Discomfort)**

**Location:** Cloud Firestore (NOT Realtime Database)

**Path Structure:**
```
/baselines/
  └── {userId}_{deviceId}_{condition}/
      ├── userId: "user123"
      ├── deviceId: "MXCHIP_001"
      ├── condition: "anxiety" | "stress" | "discomfort"
      ├── sensorValues: {
      │     temperature: 22.5
      │     humidity: 45.0
      │     motion_magnitude: 0.5
      │     sound: 100
      │   }
      ├── recordedAt: "2024-01-01T12:00:00Z"
      └── notes: "Recorded during calm state"
```

**Example:**
- User ID: `btUZnuxKRUZn7wudiXQ0bFhYY7s1`
- Device ID: `MXCHIP_001`
- Condition: `anxiety`
- Document ID: `btUZnuxKRUZn7wudiXQ0bFhYY7s1_MXCHIP_001_anxiety`

**How to View:**
1. Go to Firebase Console
2. Click "Firestore Database"
3. Navigate to: `baselines` collection
4. Look for documents like: `{userId}_{deviceId}_anxiety`

---

### 3. **Sensor Data (from Hardware)**

**Location:** Firebase Realtime Database

**Path Structure:**
```
/devices/
  └── {deviceId}/
      ├── current/          ← LATEST sensor reading
      │   ├── device_id: "MXCHIP_001"
      │   ├── timestamp: 1704110400
      │   ├── temperature: 22.5
      │   ├── humidity: 45.0
      │   ├── sensors: {
      │   │     motion: {...}
      │   │     sound: {raw: 100}
      │   │   }
      │   └── received_at: "2024-01-01T12:00:00Z"
      │
      └── history/          ← HISTORICAL sensor data
          └── {timestamp}/
              └── {...same structure as current...}
```

**Example:**
- Device ID: `MXCHIP_001`
- Current data: `/devices/MXCHIP_001/current`
- History: `/devices/MXCHIP_001/history/`

**How to View:**
1. Go to Firebase Console
2. Click "Realtime Database"
3. Navigate to: `devices` → `MXCHIP_001` → `current`
4. You'll see real-time sensor values updating

---

### 4. **User Data**

**Location:** Cloud Firestore

**Path Structure:**
```
/users/
  └── {userId}/
      ├── uid: "user123"
      ├── email: "user@example.com"
      ├── name: "John Doe"
      ├── role: "caregiver" | "patient"
      ├── assignedDeviceId: "MXCHIP_001"  ← Links user to device
      └── createdAt: "2024-01-01T12:00:00Z"
```

**How to View:**
1. Go to Firebase Console
2. Click "Firestore Database"
3. Navigate to: `users` collection
4. Find your user document

---

## 🔍 Quick Reference

| Data Type | Database | Path | Contains |
|-----------|----------|------|----------|
| **Emotional States** | Realtime DB | `/emotional_states/{userId}/current` | `state: "anxiety"`, `confidence`, etc. |
| **Baselines** | Firestore | `/baselines/{userId}_{deviceId}_{condition}` | Recorded baseline values for anxiety/stress/discomfort |
| **Sensor Data** | Realtime DB | `/devices/{deviceId}/current` | Temperature, humidity, motion, sound |
| **Users** | Firestore | `/users/{userId}` | User info, assigned device |

---

## ⚠️ Troubleshooting

### If you don't see data in Realtime Database:

1. **Check Firebase Rules:**
   - Go to Firebase Console → Realtime Database → Rules
   - Make sure `emotional_states` path has write permissions
   - Rules should allow authenticated users to write

2. **Check Authentication:**
   - Make sure user is logged in
   - Check Firebase Auth in console

3. **Check Console Logs:**
   - Look for error messages like "Permission denied"
   - Check Flutter debug console for save errors

4. **Verify Path:**
   - Make sure you're looking in the correct database (Realtime DB vs Firestore)
   - Emotional states are in **Realtime Database**
   - Baselines are in **Firestore**

---

## 📝 Notes

- **Anxiety/Stress/Discomfort** as entities are stored in:
  - **Baselines**: Firestore `baselines` collection (document ID includes condition name)
  - **Emotional States**: Realtime Database `emotional_states/{userId}/current` (field `state` contains the condition name)

- The app saves emotional states automatically when:
  - Sensor data is received
  - Baseline comparison detects a change
  - Confidence threshold is met

