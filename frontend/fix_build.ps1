# Flutter Build Fix Script
# This script resolves file locking issues during Flutter builds on Windows

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "FLUTTER BUILD FIX - File Lock Resolution" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Step 1: Stop Gradle daemon
Write-Host "`n1. Stopping Gradle daemon..." -ForegroundColor Yellow
cd android
.\gradlew --stop
cd ..
Write-Host "   Done!" -ForegroundColor Green

# Step 2: Kill any Java processes (Gradle)
Write-Host "`n2. Killing Java/Gradle processes..." -ForegroundColor Yellow
$javaProcesses = Get-Process -Name "java" -ErrorAction SilentlyContinue
if ($javaProcesses) {
    $javaProcesses | Stop-Process -Force
    Write-Host "   Killed $($javaProcesses.Count) Java process(es)" -ForegroundColor Green
} else {
    Write-Host "   No Java processes found" -ForegroundColor Gray
}

# Step 3: Kill any Dart processes
Write-Host "`n3. Killing Dart processes..." -ForegroundColor Yellow
$dartProcesses = Get-Process -Name "dart" -ErrorAction SilentlyContinue
if ($dartProcesses) {
    $dartProcesses | Stop-Process -Force
    Write-Host "   Killed $($dartProcesses.Count) Dart process(es)" -ForegroundColor Green
} else {
    Write-Host "   No Dart processes found" -ForegroundColor Gray
}

# Step 4: Wait for file handles to release
Write-Host "`n4. Waiting for file handles to release..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
Write-Host "   Done!" -ForegroundColor Green

# Step 5: Clean build directories manually
Write-Host "`n5. Cleaning build directories..." -ForegroundColor Yellow

# Remove build directory
if (Test-Path "build") {
    try {
        Remove-Item -Path "build" -Recurse -Force -ErrorAction Stop
        Write-Host "   Removed build directory" -ForegroundColor Green
    } catch {
        Write-Host "   Warning: Could not remove build directory (files may be locked)" -ForegroundColor Yellow
        Write-Host "   Trying to remove specific subdirectories..." -ForegroundColor Yellow
        
        # Try to remove specific problematic directories
        $problematicDirs = @(
            "build\app\intermediates\dex",
            "build\app\intermediates\merged_dex",
            "build\app\intermediates\classes"
        )
        
        foreach ($dir in $problematicDirs) {
            if (Test-Path $dir) {
                try {
                    Remove-Item -Path $dir -Recurse -Force -ErrorAction Stop
                    Write-Host "   Removed $dir" -ForegroundColor Green
                } catch {
                    Write-Host "   Could not remove $dir" -ForegroundColor Red
                }
            }
        }
    }
}

# Remove .gradle directory in android folder
if (Test-Path "android\.gradle") {
    try {
        Remove-Item -Path "android\.gradle" -Recurse -Force -ErrorAction Stop
        Write-Host "   Removed android\.gradle directory" -ForegroundColor Green
    } catch {
        Write-Host "   Warning: Could not remove android\.gradle directory" -ForegroundColor Yellow
    }
}

# Step 6: Run flutter clean
Write-Host "`n6. Running flutter clean..." -ForegroundColor Yellow
flutter clean
Write-Host "   Done!" -ForegroundColor Green

# Step 7: Get dependencies
Write-Host "`n7. Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "   Done!" -ForegroundColor Green

# Step 8: Clean Gradle cache
Write-Host "`n8. Cleaning Gradle cache..." -ForegroundColor Yellow
cd android
.\gradlew clean
cd ..
Write-Host "   Done!" -ForegroundColor Green

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "CLEANUP COMPLETE!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

Write-Host "`nYou can now try building again with:" -ForegroundColor Yellow
Write-Host "  flutter build apk --release" -ForegroundColor White
Write-Host "  OR" -ForegroundColor Gray
Write-Host "  flutter build appbundle --release" -ForegroundColor White

Write-Host "`nIf the issue persists, try:" -ForegroundColor Yellow
Write-Host "  1. Restart your computer" -ForegroundColor White
Write-Host "  2. Close Android Studio / VS Code" -ForegroundColor White
Write-Host "  3. Run this script again" -ForegroundColor White
Write-Host "`n============================================================" -ForegroundColor Cyan
