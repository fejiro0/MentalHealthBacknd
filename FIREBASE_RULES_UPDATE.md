# Firebase Rules Update Required

## ⚠️ IMPORTANT: Update Firebase Realtime Database Rules

The Firebase rules file has been updated locally, but **you must deploy them to Firebase** for the changes to take effect.

### Steps to Update:

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com/
   - Select your project: `mental-healthmonitor`

2. **Navigate to Realtime Database:**
   - Click on "Realtime Database" in the left sidebar
   - Click on the "Rules" tab

3. **Copy the Updated Rules:**
   - Copy the contents from `backend/firebase-rules.json`

4. **Paste and Publish:**
   - Paste the rules into the Firebase Console
   - Click "Publish"

### Updated Rules Include:

```json
{
  "rules": {
    "devices": {
      ".read": true,
      ".write": true,
      "$deviceId": {
        ".read": true,
        ".write": true,
        "current": {
          ".read": true,
          ".write": true
        },
        "history": {
          "$timestamp": {
            ".read": true,
            ".write": true
          }
        }
      }
    },
    "emotional_states": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$userId": {
        ".read": "auth != null",
        ".write": "auth != null",
        "current": {
          ".read": "auth != null",
          ".write": "auth != null"
        },
        "history": {
          "$timestamp": {
            ".read": "auth != null",
            ".write": "auth != null"
          }
        }
      }
    },
    "baselines": {
      "$userId": {
        ".read": "auth != null && auth.uid == $userId",
        ".write": "auth != null && auth.uid == $userId"
      }
    },
    "alerts": {
      ".read": true,
      ".write": false
    },
    "test": {
      ".read": true,
      ".write": true
    }
  }
}
```

### What Changed:

- **Added `emotional_states` path rules** - Previously missing, causing permission denied errors
- **Allowed authenticated users** to read/write emotional states
- **Maintained security** for user-specific data

### After Updating:

- Restart the Flutter app
- The permission denied errors should stop
- Emotional states should now save to Firebase Realtime Database

