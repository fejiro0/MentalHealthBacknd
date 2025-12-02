# Setup Instructions

## 🔐 Security Notice

**IMPORTANT**: This repository does NOT contain sensitive credentials. You must configure them yourself.

## Hardware Setup (MXChip)

1. **Copy the configuration template:**
   ```bash
   cp src/config.h.example src/config.h
   ```

2. **Edit `src/config.h` with your actual values:**
   - WiFi SSID and Password
   - Proxy Server Host (use the hosted domain `mentalhealthbacknd.onrender.com` or a local IP address for local proxy)
   - Device ID (unique identifier for your device)
   - Firebase project details (for reference)

3. **Build and upload:**
   ```bash
   pio run -t upload
   ```

## Backend Setup (Node.js Proxy)

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

4. **Edit `.env` with your actual values:**
   - Firebase Database URL
   - Firebase API Key (optional, for anonymous auth)

5. **Start the server:**
   ```bash
   node server.js
   ```

## Finding Your Computer's IP Address

- **Windows:** Run `ipconfig` in Command Prompt, look for "IPv4 Address"
- **Mac/Linux:** Run `ifconfig` in Terminal, look for "inet" under your active network interface

Update `PROXY_SERVER_HOST` in `src/config.h` with this hostname or IP.
If your backend is hosted (Render), use `mentalhealthbacknd.onrender.com` and Port `443` (HTTPS).
Note: The device now tries to connect with TLS when `PROXY_SERVER_PORT` is 443. For quick testing the device uses insecure TLS verification by default; production use should configure a proper CA root.

If your backend is hosted (on Render for example), use the hosting domain name here.
If you prefer not to recompile when testing, you can set the proxy host at runtime using Serial:
 - Connect to the device's serial console at 115200 baud and type: `SET PROXY my-backend.onrender.com:3000` or `SET PROXY 192.168.1.100:3000`.
 - Use `GET CONFIG` to view current runtime values.

## Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Enable Realtime Database
3. Copy your database URL to `backend/.env`
4. (Optional) Get your API Key from Project Settings > General > Web API Key

## Security Best Practices

- ✅ Never commit `.env` files
- ✅ Never commit `src/config.h` files
- ✅ Use strong passwords for WiFi and Firebase
- ✅ Restrict Firebase database rules appropriately
- ✅ Keep your API keys secret

