# Android Device Connection Guide

## Issue: Phone not showing in Flutter devices

If your phone is in Developer Mode but not showing up in `flutter devices`, follow these steps:

## Step 1: Enable USB Debugging

1. **On your phone:**
   - Go to **Settings** > **About Phone**
   - Tap **Build Number** 7 times to enable Developer Options
   - Go back to **Settings** > **Developer Options**
   - Enable **USB Debugging**
   - Optionally enable **Stay Awake** (keeps screen on while charging)

## Step 2: Connect Phone to Computer

1. **Use a USB cable:**
   - Use a **data cable** (not charging-only cable)
   - Connect phone to computer via USB
   - When prompted on phone, select **File Transfer (MTP)** or **PTP** mode
   - Do NOT select "Charge only" mode

## Step 3: Authorize Computer (First Time Only)

When you connect for the first time:
1. Your phone will show a popup: **"Allow USB debugging?"**
2. Check **"Always allow from this computer"**
3. Tap **"Allow"** or **"OK"**

## Step 4: Verify Connection

Open PowerShell/Command Prompt and run:

```powershell
# Using full path to adb
& "C:\Users\dabon\AppData\Local\Android\sdk\platform-tools\adb.exe" devices
```

You should see something like:
```
List of devices attached
ABC123XYZ    device
```

If you see `unauthorized`, go back to Step 3 and authorize the computer.

## Step 5: Check Flutter Devices

```powershell
flutter devices
```

Your phone should now appear in the list.

## Troubleshooting

### Device shows as "unauthorized"

1. Disconnect and reconnect USB cable
2. Revoke USB debugging authorizations on phone:
   - Settings > Developer Options > Revoke USB debugging authorizations
3. Reconnect and authorize again

### Device shows as "offline"

1. Restart ADB server:
   ```powershell
   & "C:\Users\dabon\AppData\Local\Android\sdk\platform-tools\adb.exe" kill-server
   & "C:\Users\dabon\AppData\Local\Android\sdk\platform-tools\adb.exe" start-server
   & "C:\Users\dabon\AppData\Local\Android\sdk\platform-tools\adb.exe" devices
   ```

2. Disconnect and reconnect phone
3. Check USB connection mode on phone

### No device found

1. **Check USB cable:**
   - Try a different USB cable
   - Try a different USB port
   - Ensure it's a data cable, not charging-only

2. **Check USB drivers:**
   - Windows might need device drivers
   - Install your phone manufacturer's USB drivers
   - Or use Android Studio to install generic drivers

3. **Restart ADB:**
   ```powershell
   & "C:\Users\dabon\AppData\Local\Android\sdk\platform-tools\adb.exe" kill-server
   & "C:\Users\dabon\AppData\Local\Android\sdk\platform-tools\adb.exe" start-server
   ```

4. **Restart phone:**
   - Sometimes a restart helps

5. **Check Developer Options:**
   - Ensure USB Debugging is ON
   - Try enabling "USB Debugging (Security settings)" if available
   - Try disabling "Verify apps over USB" if causing issues

### Add ADB to PATH (Optional)

To use `adb` directly without full path, add to Windows PATH:

1. Press `Win + X` > **System** > **Advanced system settings**
2. Click **Environment Variables**
3. Under **System variables**, select **Path** > **Edit**
4. Click **New** and add:
   ```
   C:\Users\dabon\AppData\Local\Android\sdk\platform-tools
   ```
5. Click **OK** on all windows
6. Restart PowerShell/Command Prompt

Now you can use `adb devices` directly.

## Quick Commands Reference

```powershell
# Check devices (using full path)
& "C:\Users\dabon\AppData\Local\Android\sdk\platform-tools\adb.exe" devices

# Restart ADB server
& "C:\Users\dabon\AppData\Local\Android\sdk\platform-tools\adb.exe" kill-server
& "C:\Users\dabon\AppData\Local\Android\sdk\platform-tools\adb.exe" start-server

# Check Flutter devices
flutter devices

# Run app on connected device
flutter run
```

## Alternative: Use Wireless Debugging (Android 11+)

If USB is problematic, try wireless debugging:

1. **On your phone:**
   - Settings > Developer Options > **Wireless debugging**
   - Enable it
   - Tap **Pair device with pairing code**

2. **On computer:**
   ```powershell
   # Connect to pairing code (shown on phone)
   & "C:\Users\dabon\AppData\Local\Android\sdk\platform-tools\adb.exe" pair <IP>:<PORT>
   # Then connect
   & "C:\Users\dabon\AppData\Local\Android\sdk\platform-tools\adb.exe" connect <IP>:<PORT>
   ```

## Still Not Working?

1. **Check phone manufacturer drivers:**
   - Samsung: Samsung USB Drivers
   - Xiaomi: Mi USB Driver
   - Huawei: HiSuite
   - Generic: Install via Android Studio > SDK Manager > SDK Tools > Google USB Driver

2. **Try different USB port:**
   - Use USB 2.0 port instead of USB 3.0
   - Try different ports on your computer

3. **Check Windows Device Manager:**
   - Connect phone
   - Open Device Manager (Win + X > Device Manager)
   - Look for your phone under "Portable Devices" or "Android Phone"
   - If it shows with yellow exclamation, drivers need updating

4. **Use Android Studio to check connection**

