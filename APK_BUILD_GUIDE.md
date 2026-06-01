# 📱 GaitWatch APK Build Guide

## ✅ Current Status
- ✅ Server: Running on port 8000
- ✅ All tests: Passing
- ✅ Flutter: Ready
- ✅ Dependencies: Available

## 🚀 Build APK (Release)

### Step 1: Navigate to Project
```bash
cd /home/kali/Documents/college\ project/gaitwatch
```

### Step 2: Get Dependencies
```bash
flutter pub get
```

### Step 3: Configure Server IP (IMPORTANT!)
Edit `lib/core/utils/providers.dart`:
```dart
const String SERVER_URL = "http://YOUR_MACHINE_IP:8000";
```

Example:
```dart
const String SERVER_URL = "http://192.168.1.100:8000";
```

### Step 4: Build APK (Release Mode)
```bash
flutter build apk --release
```

### Step 5: APK Location
```
build/app/outputs/flutter-apk/app-release.apk
```

## 📲 Install on Device

### Option 1: USB Connected
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Option 2: Manual Install
1. Copy APK to phone
2. Open with file manager
3. Tap install

## ⚙️ Configuration

Before building, edit:
**lib/core/utils/providers.dart**

```dart
// Change this to your server IP:
const String SERVER_URL = "http://192.168.1.100:8000";
```

## 🧪 Testing the App

1. **Open App**
2. **Fill Profile** (optional)
3. **Start Walk Test**
4. **Walk for 30 seconds**
5. **View Results**

## ❌ Troubleshooting

### Build Error: "Flutter not found"
```bash
flutter doctor
```

### Build Error: "Android SDK not found"
Install Android Studio from https://developer.android.com/studio

### Connection Error
Check:
1. Server IP is correct in code
2. Server is running: `curl http://SERVER_IP:8000/health`
3. Both devices on same network

## 📊 File Sizes

- APK Size: ~50-100 MB
- Installation: ~150 MB
- Runtime: ~30 MB

## ✨ Features Available

✅ Gait capture (30 seconds)
✅ Real-time risk scoring
✅ Encryption working
✅ History tracking
✅ Offline mode
✅ PDF export

---

**Version**: 1.0.0
**Status**: Production Ready
**Build Time**: 5-10 minutes
