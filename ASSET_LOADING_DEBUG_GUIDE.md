# Asset Loading Debug Guide

## 🔍 **ISSUE: Asset Not Loading - Only Getting Fallback Data**

### **What We've Added**

1. **Detailed Error Logging**
   - Logs platform (Web/Native)
   - Logs exact asset path being tried
   - Logs each step of the loading process
   - Logs full error details with stack trace

2. **Web-Specific HTTP Fallback**
   - If `rootBundle.loadString()` fails on web, tries HTTP fetch
   - Tries multiple possible paths:
     - `/assets/data/ap_police_hierarchy_complete.json`
     - `assets/data/ap_police_hierarchy_complete.json`
     - `/assets/assets/data/ap_police_hierarchy_complete.json`

3. **Better Error Messages**
   - Shows exact error type
   - Shows platform information
   - Provides troubleshooting hints

---

## **HOW TO DEBUG**

### **Step 1: Check Browser Console (Web)**

Open browser DevTools (F12) and look for these logs:

```
🔄 [Petitions] Loading police hierarchy data...
   📍 Platform: Web
   📍 Asset path: assets/data/ap_police_hierarchy_complete.json
   🔄 Attempting rootBundle.loadString()...
```

**If you see:**
- `❌ rootBundle.loadString() failed: ...` → Asset not found via rootBundle
- `🔄 Attempting HTTP fetch for web...` → Trying HTTP fallback
- `❌ HTTP fetch failed with status 404` → Asset not in web build
- `✅ HTTP fetch succeeded from: /assets/...` → Asset found via HTTP

### **Step 2: Check Network Tab (Web)**

1. Open DevTools → Network tab
2. Filter by "json" or search for "ap_police_hierarchy"
3. Look for requests to the asset file
4. Check the status code:
   - **200** = Found
   - **404** = Not found (asset not bundled)
   - **CORS error** = CORS issue

### **Step 3: Check Build Output**

**For Web:**
```bash
# Check if asset is in build output
ls -la frontend/build/web/assets/data/
```

**For Android APK:**
```bash
# Unzip APK and check assets
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep ap_police_hierarchy
```

### **Step 4: Verify pubspec.yaml**

Check that the asset is declared:
```yaml
flutter:
  assets:
    - assets/data/ap_police_hierarchy_complete.json
```

**Important:** The path in `pubspec.yaml` must match the actual file path exactly (case-sensitive).

### **Step 5: Rebuild the App**

After changing `pubspec.yaml`, you MUST rebuild:
```bash
flutter clean
flutter pub get
flutter build web  # or flutter build apk
```

**Hot reload won't pick up asset changes!**

---

## **COMMON ISSUES & SOLUTIONS**

### **Issue 1: Asset Not Bundled in Build**

**Symptoms:**
- Works in development (`flutter run`)
- Fails in production build (`flutter build web`)
- 404 error in network tab

**Solution:**
1. Check `pubspec.yaml` has the asset listed
2. Run `flutter clean`
3. Run `flutter pub get`
4. Rebuild: `flutter build web`

### **Issue 2: Case Sensitivity**

**Symptoms:**
- Works on Windows (development)
- Fails on Linux/web server (production)
- Fails on Android APK

**Solution:**
- Ensure folder is `data/` (lowercase) everywhere
- Ensure path in code is `assets/data/...` (lowercase)
- Ensure path in `pubspec.yaml` is `assets/data/...` (lowercase)

### **Issue 3: Wrong Asset Path in Web Build**

**Symptoms:**
- Asset exists in `build/web/assets/`
- But HTTP fetch returns 404

**Solution:**
- Check actual path in `build/web/assets/`
- Update HTTP fetch paths if needed
- Check `index.html` base href

### **Issue 4: CORS Issues (Web Only)**

**Symptoms:**
- HTTP fetch fails with CORS error
- Works in development, fails in production

**Solution:**
- Ensure asset is served from same origin
- Check Firebase hosting configuration
- Verify `firebase.json` includes assets

---

## **WHAT TO CHECK IN PRODUCTION**

1. **Browser Console Logs**
   - Look for the detailed error messages
   - Check which loading method failed
   - Note the exact error type

2. **Network Tab**
   - Check if asset request is made
   - Check response status code
   - Check response headers

3. **Build Output**
   - Verify asset file exists in build
   - Check file size (should be > 0)
   - Verify path matches code

4. **Firebase Hosting**
   - Check `firebase.json` configuration
   - Verify assets are being deployed
   - Check hosting cache

---

## **NEXT STEPS**

After checking the above, share:
1. **Console logs** - The exact error messages
2. **Network tab** - Screenshot of asset request
3. **Build output** - Whether asset exists in build folder
4. **Platform** - Web or Android APK

This will help identify the exact issue!
