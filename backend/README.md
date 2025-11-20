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

In your MXChip code, update the proxy server IP address:

```cpp
#define PROXY_SERVER_IP "192.168.1.100"  // Your computer's IP address
```

To find your IP address:
- **Windows:** `ipconfig` (look for IPv4 Address)
- **Mac/Linux:** `ifconfig` or `ip addr show`

## Firebase Security Rules

Make sure your Firebase Realtime Database rules allow writes:

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

**Note:** For production, you should use proper authentication and stricter rules!

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

