# Reset Onboarding - Instructions

## The Issue

The `dart run reset_onboarding.dart` command is failing due to Flutter SDK errors (not related to our code).

## Solution: Use These Methods Instead

### Method 1: Clear App Data (Easiest) ✅

**On Android Device/Emulator**:
1. Go to **Settings**
2. Tap **Apps** or **Applications**
3. Find **Dharma**
4. Tap **Storage**
5. Tap **Clear Data** or **Clear Storage**
6. Restart the app

This will reset everything including onboarding.

---

### Method 2: Uninstall and Reinstall

```bash
# In terminal
cd c:\Users\APSSDC\Desktop\main\Dharma-CMS\frontend
flutter clean
flutter pub get
flutter run
```

This gives you a completely fresh install.

---

### Method 3: Add Reset Button in App (Recommended for Testing)

I can add a temporary "Reset Onboarding" button in the Settings screen for easy testing.

Would you like me to add this button?

---

### Method 4: Use ADB (Advanced)

```bash
# Clear app data via ADB
adb shell pm clear com.example.dharma

# Then restart app
flutter run
```

---

## Why the Script Failed

The error is from Flutter's gesture recognizer files, not our code. This happens when:
- Flutter SDK is corrupted
- Version mismatch between Flutter and dependencies
- Cache issues

## Recommended Action

**Use Method 1 (Clear App Data)** - It's the fastest and easiest way to reset onboarding for testing.

Or let me know if you want Method 3 (Reset button in Settings) - I can add it in 2 minutes!
