# Android Setup - Fix Gradle Build Error

## ✅ What I Fixed

1. ✅ Added Google Services plugin
2. ✅ Set minSdkVersion to 21 (required for Firebase)
3. ✅ Added multidex support
4. ✅ Updated Gradle configuration

## 🔥 Required: Add Firebase Configuration

You need to add your `google-services.json` file to run the app.

### Option 1: Automatic (Recommended)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (this will create google-services.json automatically)
flutterfire configure
```

### Option 2: Manual

1. **Go to Firebase Console**: https://console.firebase.google.com
2. **Select your project** (or create one)
3. **Add an Android app**:
   - Click "Add app" → Android icon
   - Package name: `com.example.Dharma`
   - App nickname: Dharma
   - Click "Register app"
4. **Download google-services.json**
5. **Place it here**: `android/app/google-services.json`

### Verify File Location

```
flutter_app/
└── android/
    └── app/
        └── google-services.json  ← Must be here!
```

## 🚀 After Adding google-services.json

Run these commands:

```bash
# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## 🔧 If Still Failing

### Check Java Version

```bash
java -version
```

Should be Java 11 or higher.

### Clear Gradle Cache

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter run
```

### Check Android SDK

```bash
flutter doctor -v
```

Make sure Android SDK is properly installed.

## ⚠️ Important Notes

- **Package name**: `com.example.Dharma` (must match in Firebase)
- **minSdkVersion**: 21 (already set)
- **MultiDex**: Enabled (already configured)

## 📝 What Was Changed

### `android/build.gradle.kts`
- Added Google Services classpath

### `android/app/build.gradle.kts`
- Added Google Services plugin
- Set minSdk to 21
- Enabled multidex
- Added multidex dependency

---

**Next Step**: Add `google-services.json` using one of the methods above, then run `flutter run`! 🚀
