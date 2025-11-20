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
   - Proxy Server IP (your computer's IP address)
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

Update `PROXY_SERVER_IP` in `src/config.h` with this IP address.

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

