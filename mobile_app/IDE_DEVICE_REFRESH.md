# IDE Device Not Showing - Quick Fix

Your device **IS** detected by Flutter (RFCW50SV73E), but your IDE might not be showing it. Here's how to fix:

## VS Code Fix

### Method 1: Refresh Device List
1. Press `Ctrl + Shift + P` (or `Cmd + Shift + P` on Mac)
2. Type: `Flutter: Select Device`
3. Press Enter
4. Your device should appear in the list

### Method 2: Restart Flutter Daemon
1. Press `Ctrl + Shift + P`
2. Type: `Flutter: Reload`
3. Or type: `Developer: Reload Window` to reload VS Code

### Method 3: Check Device Selector
1. Look at the **bottom-right corner** of VS Code
2. Click on the device name (should show "No device" or current device)
3. Select your device from the dropdown

### Method 4: Restart Extension
1. Press `Ctrl + Shift + P`
2. Type: `Developer: Reload Window`
3. Or restart VS Code completely

## Android Studio Fix

### Method 1: Refresh Device List
1. Click on the device selector dropdown (top toolbar, usually shows emulator name)
2. Click "Refresh" or the refresh icon
3. Your device should appear

### Method 2: Restart Flutter Plugin
1. Go to **File** > **Invalidate Caches / Restart**
2. Choose **Invalidate and Restart**
3. Wait for Android Studio to restart

### Method 3: Check ADB Integration
1. Go to **Tools** > **SDK Manager**
2. Under **SDK Tools**, ensure **Android SDK Platform-Tools** is installed
3. Click **Apply** if changes needed

## Command Line (Always Works)

If IDE still doesn't show it, use command line:

```powershell
# Run on specific device
flutter run -d RFCW50SV73E

# Or let Flutter ask which device
flutter run
```

## Verify Device Connection

Run this to verify:
```powershell
flutter devices
```

You should see:
```
SM F936B (mobile) • RFCW50SV73E • android-arm64 • Android 15 (API 35)
```

## Still Not Working?

1. **Check if Android Studio is using ADB:**
   - Android Studio might be locking ADB
   - Close Android Studio, then try in VS Code

2. **Restart ADB:**
   ```powershell
   & "C:\Users\dabon\AppData\Local\Android\sdk\platform-tools\adb.exe" kill-server
   & "C:\Users\dabon\AppData\Local\Android\sdk\platform-tools\adb.exe" start-server
   ```

3. **Check VS Code Flutter Extension:**
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "Flutter"
   - Ensure it's enabled and updated to latest version

4. **Check Device Selector Location:**
   - VS Code: Bottom-right status bar
   - Android Studio: Top toolbar device dropdown

