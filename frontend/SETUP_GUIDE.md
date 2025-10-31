# Complete Setup Guide - Dharma Flutter

This guide will walk you through setting up and running the Flutter app from scratch.

## Prerequisites Check

Before starting, ensure you have:

- [ ] Flutter SDK 3.0+ installed
- [ ] Dart SDK 3.0+ installed
- [ ] Android Studio (for Android development) OR Xcode (for iOS development)
- [ ] A Firebase project created
- [ ] Git installed
- [ ] A code editor (VS Code or Android Studio recommended)

### Verify Installation

```bash
flutter --version
dart --version
flutter doctor
```

Fix any issues reported by `flutter doctor` before proceeding.

---

## Step-by-Step Setup

### Step 1: Navigate to Project

```bash
cd flutter_app
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

This will download all packages listed in `pubspec.yaml`.

### Step 3: Firebase Configuration

#### Option A: Automatic (Recommended)

1. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

2. Login to Firebase:
```bash
firebase login
```

3. Configure Firebase for your project:
```bash
flutterfire configure
```

This will:
- Create or select a Firebase project
- Generate `lib/firebase_options.dart`
- Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- Place them in the correct directories

#### Option B: Manual

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or select existing
3. Add an Android app and/or iOS app
4. Download configuration files:
   - **Android**: `google-services.json` → Place in `android/app/`
   - **iOS**: `GoogleService-Info.plist` → Add to `ios/Runner/` via Xcode

5. Create `.env` file in project root:

```env
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

6. If the `.env` file approach is used, ensure `pubspec.yaml` has the assets declared:

```yaml
flutter:
  assets:
    - .env
```

### Step 4: Enable Firebase Services

In Firebase Console, enable:

1. **Authentication**:
   - Go to Authentication → Sign-in method
   - Enable Email/Password
   - Enable Google (download OAuth client config if needed)

2. **Firestore Database**:
   - Go to Firestore Database → Create database
   - Start in **test mode** (or set custom security rules)

3. **Storage**:
   - Go to Storage → Get started
   - Use default security rules or customize

### Step 5: Set Firestore Security Rules

Go to Firestore → Rules and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /cases/{caseId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    match /complaints/{complaintId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
  }
}
```

### Step 6: Platform-Specific Configuration

#### Android

1. Open `android/app/build.gradle`
2. Ensure `minSdkVersion` is **21 or higher**:

```gradle
defaultConfig {
    minSdkVersion 21  // or higher
    targetSdkVersion flutter.targetSdkVersion
}
```

3. Ensure Google Services plugin is applied (should already be there):

```gradle
apply plugin: 'com.google.gms.google-services'
```

4. If facing multidex issues, add in `defaultConfig`:

```gradle
multiDexEnabled true
```

#### iOS

1. Open `ios/Podfile`
2. Set platform to iOS 12.0 or higher:

```ruby
platform :ios, '12.0'
```

3. Run pod install:

```bash
cd ios
pod install
cd ..
```

4. Open `ios/Runner.xcworkspace` in Xcode (NOT `.xcodeproj`)
5. Add `GoogleService-Info.plist` to the project if not already added
6. Set deployment target to iOS 12.0+ in Xcode project settings

### Step 7: Google Sign-In Configuration (Optional but Recommended)

#### Android

1. Get SHA-1 fingerprint:

```bash
cd android
./gradlew signingReport
```

2. Copy the SHA-1 from the output
3. In Firebase Console → Project Settings → Your Android app
4. Add the SHA-1 fingerprint
5. Download the updated `google-services.json`

#### iOS

1. In Firebase Console → Project Settings → Your iOS app
2. Copy the `REVERSED_CLIENT_ID`
3. Open `ios/Runner/Info.plist` in Xcode
4. Add a new URL scheme with the `REVERSED_CLIENT_ID` value

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

---

## Running the App

### Step 1: Connect a Device or Start Emulator

**Physical Device**:
- Enable Developer Options and USB Debugging
- Connect via USB
- Verify with `flutter devices`

**Emulator/Simulator**:
- Android: Open Android Studio → AVD Manager → Start emulator
- iOS: `open -a Simulator`

### Step 2: Run the App

```bash
flutter run
```

Or for a specific device:

```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

### Step 3: Hot Reload During Development

- Press `r` in terminal for hot reload
- Press `R` for hot restart
- Press `q` to quit

---

## Building for Production

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode:
1. Select "Any iOS Device" or your connected device
2. Product → Archive
3. Follow App Store distribution steps

---

## Testing

### Run All Tests

```bash
flutter test
```

### Run Specific Test

```bash
flutter test test/widgets/login_screen_test.dart
```

### Generate Coverage Report

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS/Linux
start coverage/html/index.html  # Windows
```

---

## Troubleshooting

### Issue: "Flutter pub get" fails

**Solution**:
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

### Issue: Firebase not connecting

**Checklist**:
- [ ] `google-services.json` in `android/app/`
- [ ] `GoogleService-Info.plist` in `ios/Runner/` and added to Xcode project
- [ ] Firebase project has the correct package name / bundle ID
- [ ] Internet connection is active

### Issue: Google Sign-In fails on Android

**Solution**:
- Ensure SHA-1 fingerprint is added in Firebase Console
- Download updated `google-services.json`
- Rebuild the app

### Issue: iOS build fails with CocoaPods error

**Solution**:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

### Issue: "Gradle task assembleDebug failed with exit code 1"

**Solutions**:
1. Check `minSdkVersion` is 21+
2. Ensure `google-services.json` is in `android/app/`
3. Run `flutter clean && flutter pub get`
4. Check for duplicate dependencies in `build.gradle`

### Issue: App crashes on launch

**Check**:
1. Firebase configuration is correct
2. Firestore security rules allow access
3. Check device logs:
   - Android: `adb logcat`
   - iOS: Xcode → Window → Devices and Simulators → View Device Logs

---

## Code Style & Linting

### Run Analyzer

```bash
flutter analyze
```

### Format Code

```bash
flutter format .
```

### Fix Common Issues

```bash
dart fix --apply
```

---

## IDE Setup

### VS Code

**Recommended Extensions**:
- Flutter
- Dart
- Dart Data Class Generator
- Flutter Widget Snippets

**Settings** (`.vscode/settings.json`):
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "editor.formatOnSave": true,
  "dart.lineLength": 120
}
```

### Android Studio

1. Install Flutter and Dart plugins
2. Preferences → Languages & Frameworks → Flutter → Set SDK path
3. Enable "Format on save" in settings

---

## Next Steps After Setup

1. ✅ **Create a test account**: Sign up with email or Google
2. ✅ **Verify authentication**: Check Firebase Console → Authentication for new user
3. ✅ **Test navigation**: Navigate through all screens
4. ⚠️ **Implement pending features**:
   - Dashboard charts (use `fl_chart`)
   - Case management forms
   - AI backend integration (requires API endpoints)
5. ⚠️ **Connect to backend**: Update API endpoints in services

---

## Environment Variables Reference

All environment variables should be in `.env`:

| Variable | Description | Example |
|----------|-------------|---------|
| `FIREBASE_API_KEY` | Firebase Web API Key | `AIza...` |
| `FIREBASE_AUTH_DOMAIN` | Auth domain | `myproject.firebaseapp.com` |
| `FIREBASE_PROJECT_ID` | Project ID | `myproject-12345` |
| `FIREBASE_STORAGE_BUCKET` | Storage bucket | `myproject.appspot.com` |
| `FIREBASE_MESSAGING_SENDER_ID` | FCM sender ID | `123456789` |
| `FIREBASE_APP_ID` | App ID | `1:123456789:web:abc123` |

---

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [Firebase Console](https://console.firebase.google.com/)

---

## Support

For issues with this setup, please:
1. Check the troubleshooting section above
2. Review `MIGRATION_REPORT.md` for feature status
3. Run `flutter doctor -v` and check for errors
4. Contact the development team with error logs

**Happy Coding! 🚀**
