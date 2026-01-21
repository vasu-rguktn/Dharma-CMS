# Platform Detection Fix

## Issue
```
UnsupportedError: Unsupported operation: Platform._operatingSystem
```

## Root Cause
The code was using `Platform.isAndroid` from `dart:io` which is not supported on web platform. When running the Flutter app in Chrome (web), this causes an `UnsupportedError`.

## Solution
Replaced all instances of `Platform.isAndroid` with web-safe platform detection:

```dart
// ❌ Old (not web-safe)
if (Platform.isAndroid) {
  // Android-specific code
}

// ✅ New (web-safe)
if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
  // Android-specific code
}
```

## Files Modified
- `lib/screens/ai_legal_chat_screen.dart` - 7 occurrences fixed

## Explanation
The proper way to detect platform in Flutter:

1. **For Web Check**: Use `kIsWeb` from `package:flutter/foundation.dart`
2. **For Platform Check**: Use `defaultTargetPlatform` from `package:flutter/foundation.dart`

This works across all platforms:
- ✅ Android (native)
- ✅ iOS (native)
- ✅ Web (Chrome, Firefox, Safari)
- ✅ Desktop (Windows, macOS, Linux)

## Testing
The app should now run correctly on:
- Chrome (web) ✅
- Android device/emulator ✅
- iOS device/simulator ✅

## Note
The geo-camera feature will work differently on web:
- **Native (Android/iOS)**: Full geo-camera with watermarks
- **Web**: Will fall back to standard image picker (browser limitation)

For production law enforcement use, deploy as native Android/iOS app for full geo-camera functionality.
