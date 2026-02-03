# Flutter Build File Lock Error - Solution Guide

## Error Message
```
Execution failed for task ':app:minifyReleaseWithR8'.
> java.nio.file.FileSystemException: classes.dex: The process cannot access 
  the file because it is being used by another process
```

## Root Cause
This is a **Windows file locking issue** that occurs when:
1. A previous Gradle build didn't complete cleanly
2. Gradle daemon is still holding file handles
3. Java/Dart processes are still running in the background
4. The `.dex` file in the build directory is locked

## Solution Applied

### Automated Fix Script: `fix_build.ps1`

I've created a PowerShell script that automatically:

1. ✅ **Stops Gradle daemon** - Releases all Gradle file handles
2. ✅ **Kills Java processes** - Terminates any stuck Gradle processes
3. ✅ **Kills Dart processes** - Cleans up Dart analyzer processes
4. ✅ **Waits for file release** - Gives OS time to release locks
5. ✅ **Cleans build directories** - Removes locked build artifacts
6. ✅ **Runs flutter clean** - Official Flutter cleanup
7. ✅ **Gets dependencies** - Refreshes pub packages
8. ✅ **Cleans Gradle cache** - Removes Gradle build cache

### Manual Fix (If Script Fails)

If the automated script doesn't work, follow these manual steps:

#### Step 1: Stop Gradle Daemon
```powershell
cd android
.\gradlew --stop
cd ..
```

#### Step 2: Kill Locked Processes
```powershell
# Kill Java processes (Gradle)
Get-Process -Name "java" -ErrorAction SilentlyContinue | Stop-Process -Force

# Kill Dart processes
Get-Process -Name "dart" -ErrorAction SilentlyContinue | Stop-Process -Force
```

#### Step 3: Delete Build Directory
```powershell
# Wait a few seconds for file handles to release
Start-Sleep -Seconds 5

# Remove build directory
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue

# Remove Gradle cache
Remove-Item -Path "android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
```

#### Step 4: Clean and Rebuild
```powershell
flutter clean
flutter pub get
cd android
.\gradlew clean
cd ..
```

#### Step 5: Build Again
```powershell
# For APK
flutter build apk --release

# OR for App Bundle
flutter build appbundle --release
```

## Alternative Solutions

### Option 1: Restart Computer
Sometimes the simplest solution:
1. Save all work
2. Restart Windows
3. Try building again

### Option 2: Close IDEs
Close any running IDEs that might be locking files:
- Android Studio
- VS Code
- IntelliJ IDEA

### Option 3: Use Process Explorer
If files are still locked:
1. Download [Process Explorer](https://docs.microsoft.com/en-us/sysinternals/downloads/process-explorer)
2. Search for `classes.dex`
3. Find which process is holding the file
4. Kill that process

### Option 4: Build in Safe Mode
Build with fewer parallel processes:
```powershell
flutter build apk --release --no-tree-shake-icons
```

Or modify `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx2048m
org.gradle.parallel=false
org.gradle.daemon=false
```

## Prevention

To avoid this issue in the future:

1. **Always stop Gradle daemon after builds:**
   ```powershell
   cd android
   .\gradlew --stop
   cd ..
   ```

2. **Close IDEs before building:**
   - Close Android Studio
   - Close VS Code
   - Then run build command

3. **Use clean builds periodically:**
   ```powershell
   flutter clean
   flutter pub get
   ```

4. **Don't interrupt builds:**
   - Let builds complete fully
   - Don't Ctrl+C during build process

## Troubleshooting

### If Build Still Fails

1. **Check disk space:**
   ```powershell
   Get-PSDrive C
   ```
   Ensure you have at least 5GB free

2. **Check antivirus:**
   - Temporarily disable antivirus
   - Add Flutter/Gradle to exclusions

3. **Check file permissions:**
   - Ensure you have write access to project directory
   - Run PowerShell as Administrator if needed

4. **Update Flutter:**
   ```powershell
   flutter upgrade
   ```

5. **Update Gradle:**
   - Edit `android/gradle/wrapper/gradle-wrapper.properties`
   - Update `distributionUrl` to latest version

## Quick Reference Commands

```powershell
# Stop everything and clean
cd android && .\gradlew --stop && cd ..
Get-Process -Name "java","dart" -ErrorAction SilentlyContinue | Stop-Process -Force
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Build release App Bundle
flutter build appbundle --release

# Build debug APK (faster)
flutter build apk --debug
```

## Related Files

- **Fix Script:** `frontend/fix_build.ps1`
- **Gradle Config:** `frontend/android/build.gradle`
- **Gradle Properties:** `frontend/android/gradle.properties`
- **Gradle Wrapper:** `frontend/android/gradle/wrapper/gradle-wrapper.properties`

## Summary

**Problem:** Gradle build fails due to locked `.dex` file  
**Root Cause:** Gradle daemon or Java processes holding file locks  
**Solution:** Stop Gradle daemon, kill processes, clean build directories  
**Prevention:** Always stop Gradle daemon after builds, don't interrupt builds  
**Script:** Run `fix_build.ps1` for automated fix
