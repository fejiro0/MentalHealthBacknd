# Firebase Setup Guide

## Firebase Configuration

- **Firebase URL:** https://mental-healthmonitor-default-rtdb.firebaseio.com/
- **Project ID:** mental-healthmonitor
- **Project Number:** 771467428266
- **Device ID:** MXCHIP_001 (change this to unique device ID if needed)

## WiFi Configuration

- **SSID:** AZUSPROG0814
- **Password:** 12345679

## Current Implementation

The hardware code sends sensor data directly to Firebase Realtime Database using HTTP/HTTPS.

### Data Structure in Firebase

```
/devices/{device_id}/current.json
{
  "device_id": "MXCHIP_001",
  "timestamp": 1234567890,
  "sensors": {
    "motion": {
      "magnitude": 0.35,
      "x": 0.1,
      "y": 0.2,
      "z": 9.81,
      "gyro_x": 0.0,
      "gyro_y": 0.0,
      "gyro_z": 0.0,
      "angle_x": 0.0,
      "angle_y": 0.0,
      "angle_z": 0.0
    },
    "sound": {
      "raw": 2450
    },
    "temperature": 22.5,
    "humidity": 55.0
  }
}
```

## HTTPS Support Issue

**Problem:** Firebase Realtime Database requires HTTPS (port 443), but MXChip's `WiFiClient` may not support SSL/TLS.

**Solutions:**

### Option 1: Use Node.js Proxy (Recommended)

Create a Node.js server that accepts HTTP from MXChip and forwards to Firebase via HTTPS.

1. **Install dependencies:**
   ```bash
   npm init -y
   npm install express axios
   ```

2. **Create `proxy-server.js`:**
   ```javascript
   const express = require('express');
   const axios = require('axios');
   const app = express();

   app.use(express.json());

   const FIREBASE_URL = 'https://mental-healthmonitor-default-rtdb.firebaseio.com';

   app.put('/devices/:deviceId/current.json', async (req, res) => {
     try {
       const { deviceId } = req.params;
       const response = await axios.put(
         `${FIREBASE_URL}/devices/${deviceId}/current.json`,
         req.body
       );
       res.json(response.data);
     } catch (error) {
       console.error('Firebase error:', error);
       res.status(500).json({ error: error.message });
     }
   });

   app.listen(3000, () => {
     console.log('Proxy server running on http://localhost:3000');
   });
   ```

3. **Update MXChip code to use proxy:**
   - Change `FIREBASE_HOST` to your computer's IP address (e.g., `192.168.1.100`)
   - Change port from 443 to 3000
   - Use HTTP (port 80) instead of HTTPS

### Option 2: Use WiFiClientSecure (If Available)

If MXChip supports `WiFiClientSecure`, update the code to use it:

```cpp
#include <WiFiClientSecure.h>

class FirebaseClient {
private:
    WiFiClientSecure client;  // Instead of WiFiClient
    // ...
};
```

### Option 3: Configure Firebase Rules (Development Only)

For development/testing only, you can allow HTTP access:

1. Go to Firebase Console → Realtime Database → Rules
2. Temporarily allow writes (NOT recommended for production)

## Testing

1. **Upload code to MXChip**
2. **Open Serial Monitor** (115200 baud)
3. **Check for:**
   - "✅ WiFi Connected!"
   - "✅ Firebase client initialized"
   - "Firebase: Data sent successfully"

4. **Check Firebase Console:**
   - Go to https://console.firebase.google.com/
   - Select project: mental-healthmonitor
   - Go to Realtime Database
   - Look for data under `/devices/MXCHIP_001/current`

## Troubleshooting

- **WiFi Connection Failed:** Check SSID and password
- **Firebase Connection Failed:** May need Node.js proxy for HTTPS
- **Data Not Appearing:** Check Firebase rules allow writes
- **Connection Timeout:** Check internet connection and firewall

