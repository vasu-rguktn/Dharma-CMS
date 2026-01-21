# Geo-Camera Quick Start Guide

## 🚀 How to Use the Geo-Camera

### For Users

1. **Open the App**
   - Navigate to AI Legal Chat or Legal Queries screen
   - Tap the camera icon to attach evidence

2. **Grant Permissions** (First Time Only)
   - When prompted, tap "Allow" for:
     - Camera access
     - Location access (While using the app)

3. **Capture Evidence**
   - Camera opens with live location overlay showing:
     - 📍 GPS coordinates
     - 📅 Current date and time
     - 📌 Your current address
   - Wait for location to load (usually 2-5 seconds)
   - Tap the large capture button to take photo/video
   - Photo/video is automatically watermarked

4. **Review and Attach**
   - Captured media is automatically attached to your message
   - You'll see a confirmation: "Geo-tagged photo attached"
   - Continue with your submission

### Camera Controls

- **Capture Button** (Center): Take photo or start/stop video recording
- **Flash Button** (Top Right): Toggle flash on/off
- **Flip Button** (Bottom Right): Switch between front/back camera
- **Refresh Button** (Bottom Left): Refresh location if needed
- **Close Button** (Top Left): Cancel and go back

### Troubleshooting

#### "Location permission required"
- **Solution**: Tap "Open Settings" → Find "Dharma" app → Enable Location permission

#### "Camera permission required"
- **Solution**: Tap "Open Settings" → Find "Dharma" app → Enable Camera permission

#### "Waiting for location..."
- **Cause**: GPS signal is weak or location services disabled
- **Solution**: 
  - Enable Location/GPS in device settings
  - Move to an area with better GPS signal
  - Wait a few more seconds
  - Tap the refresh button

#### "No cameras available"
- **Cause**: Device has no camera or camera is in use by another app
- **Solution**: Close other camera apps and try again

## 🔧 For Developers

### Testing the Implementation

```bash
# Run the app
cd c:\Users\APSSDC\Desktop\main\Dharma-CMS\frontend
flutter run

# Or build for release
flutter build apk --release
flutter build ios --release
```

### File Locations

**Captured Media Storage:**
- Android: `/data/data/com.yourapp.dharma/app_flutter/geo_evidence/`
- iOS: `Documents/geo_evidence/`

**File Naming:**
- Format: `GEO_YYYYMMDD_HHMMSS.jpg` or `.mp4`
- Example: `GEO_20260103_155030.jpg`

### Integration Points

**AI Legal Chat Screen:**
```dart
// Photo capture
final XFile? geoTaggedImage = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const GeoCameraScreen(
      captureMode: CaptureMode.image,
    ),
  ),
);

// Video capture
final XFile? geoTaggedVideo = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const GeoCameraScreen(
      captureMode: CaptureMode.video,
    ),
  ),
);
```

**Legal Queries Screen:**
```dart
// Same as above - GeoCameraScreen returns XFile with permanent path
```

### Watermark Format

```
📍 17.4065°N, 78.4772°E
📅 03/01/2026 15:50:30
📌 Hyderabad, Telangana, India
```

### API Reference

**GeoCameraService:**
```dart
final service = GeoCameraService();

// Request permission
bool granted = await service.requestLocationPermission();

// Get current location
Position? position = await service.getCurrentLocation();

// Get address
String? address = await service.getAddressFromCoordinates(lat, lon);

// Format watermark
String watermark = service.formatLocationWatermark(position, address);
```

**WatermarkProcessor:**
```dart
final processor = WatermarkProcessor();

// Add watermark to image
File watermarkedImage = await processor.addWatermarkToImage(
  imageFile,
  watermarkText,
);

// Process video
File processedVideo = await processor.addWatermarkToVideo(
  videoFile,
  watermarkText,
);

// Cleanup old files (optional)
await processor.cleanupOldFiles(daysToKeep: 30);
```

## 📱 Platform-Specific Notes

### Android
- Minimum SDK: 21 (Android 5.0)
- Permissions auto-requested on first use
- Location accuracy: Best available (usually 3-10 meters)

### iOS
- Minimum iOS: 11.0
- Permissions requested with clear usage descriptions
- Location accuracy: Best for navigation

## 🔒 Security & Privacy

- Location is only captured when user explicitly takes photo/video
- GPS coordinates embedded in both visual watermark and EXIF metadata
- Watermark cannot be removed without obvious tampering
- Files stored securely in app's private directory
- No location tracking when camera is not in use

## ⚡ Performance

- Camera initialization: < 2 seconds
- Location fetch: 2-5 seconds (depends on GPS signal)
- Watermark processing: < 1 second
- No UI lag during capture
- Location caching reduces repeated GPS queries

## 📊 Testing Checklist

- [ ] Camera opens successfully
- [ ] Location permission requested
- [ ] GPS coordinates displayed
- [ ] Address fetched and displayed
- [ ] Watermark appears on captured image
- [ ] File saved to permanent location
- [ ] File accepted in chat/upload
- [ ] Flash toggle works
- [ ] Camera switch works
- [ ] Video recording works
- [ ] Permission denied handled gracefully
- [ ] GPS disabled handled gracefully

## 🆘 Support

If you encounter any issues:

1. Check permissions in device settings
2. Ensure GPS/Location is enabled
3. Try restarting the app
4. Check device has sufficient storage
5. Verify camera is not in use by another app

For technical support, contact the development team with:
- Device model and OS version
- Error message (if any)
- Steps to reproduce the issue
