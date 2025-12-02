# MXChip Firebase Proxy Server

This Node.js proxy server forwards sensor data from MXChip AZ3166 to Firebase Realtime Database.

## Setup

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Configure environment:**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and set your configuration:
   ```env
   PORT=3000
   FIREBASE_DATABASE_URL=https://mental-healthmonitor-default-rtdb.firebaseio.com
   FIREBASE_API_KEY=your-api-key-here
   ```

3. **Start the server:**
   ```bash
   npm start
   ```
   
   For development with auto-reload:
   ```bash
   npm run dev
   ```

## Endpoints

- **POST `/sensor-data`** - Receive sensor data from MXChip
- **GET `/health`** - Health check endpoint
- **GET `/test-firebase`** - Test Firebase connection

## Hardware Configuration

In your MXChip code, update the proxy server host or IP address. Use a hostname when pointing to a hosted backend (advanced), or a local IP for a local proxy (default behavior).

```cpp
// Use a hostname for hosted backends (e.g. "my-backend.onrender.com")
// or a local IP for a local proxy
// Hosted example (Render - requires HTTPS):
// #define PROXY_SERVER_HOST "mentalhealthbacknd.onrender.com"
// Because the device uses a simple HTTP client by default (WiFiClient), it cannot communicate with HTTPS-only endpoints
// (like Render) without TLS support. Recommended ways to use a hosted backend:
// 1) Use a local HTTP proxy (node backend on your PC) and set PROXY_SERVER_HOST to your PC IP (e.g., 192.168.1.100:3000)
// 2) Use a Node.js proxy on the hosted provider (if you control it) that accepts HTTP from the device and forwards to Firebase
// 3) Add TLS/HTTPS client (`WiFiClientSecure`) on the device (not implemented by default).
// Local example:
// #define PROXY_SERVER_HOST "192.168.1.100"
```

To find your IP address:
- **Windows:** `ipconfig` (look for IPv4 Address)
-- **Mac/Linux:** `ifconfig` or `ip addr show`

Update `PROXY_SERVER_HOST` in `src/config.h` with this hostname or IP address.
You can also set the proxy host at runtime using the device's serial console (115200 baud), e.g.:

```
SET PROXY my-backend.onrender.com:3000
GET CONFIG
```

## Firebase Security Rules

Firebase security rules are provided in `firebase-rules.json`. 

To apply these rules:
1. Go to Firebase Console > Realtime Database > Rules
2. Copy the contents of `firebase-rules.json`
3. Paste into the Firebase Rules editor
4. Click "Publish"

**Note:** The rules require authentication (`auth != null`). Make sure anonymous authentication is enabled in Firebase Authentication settings.

### HTTPS on hosted providers (Render)
If you are using a hosted provider (like Render), the endpoint will typically be HTTPS on port `443`. The device will automatically select a secure TLS client if `PROXY_SERVER_PORT` is `443`. For quick testing, the device uses insecure TLS (no CA validation). For production, configure proper root CA verification in `MXChipFirebase`.

## Testing

1. **Test server health:**
   ```bash
   curl http://localhost:3000/health
   ```

2. **Test Firebase connection:**
   ```bash
   curl http://localhost:3000/test-firebase
   ```

3. **Test with sample data:**
   ```bash
   curl -X POST http://localhost:3000/sensor-data \
     -H "Content-Type: application/json" \
     -d '{
       "device_id": "MXCHIP_001",
       "timestamp": 1234567890,
       "temperature": 22.5,
       "humidity": 55.0,
       "motion_magnitude": 0.35,
       "sound": 2450
     }'
   ```

## Troubleshooting

- **Connection refused:** Check if server is running and firewall allows port 3000
- **Firebase errors:** Check API key and Firebase URL in `.env`
- **CORS errors:** The server includes CORS headers, should work from any origin

