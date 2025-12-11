# Testing OTP Auto-Fill on Your Android Device

## ✅ Your Device is Connected!
Device: **V2037 (Android 13)**

The app is now running on your physical Android device. Follow these steps to test OTP auto-fill:

---

## 📱 Step-by-Step Testing Guide

### Step 1: Grant SMS Permissions (First Time Only)
When you first try to use OTP auto-fill, Android will ask for SMS permissions:
- Click **"Allow"** when prompted to let the app read SMS
- This is required for auto-fill to work

### Step 2: Navigate to Phone Login
1. Open the app on your Android device
2. Navigate to the **Phone Login** screen
3. You should see a screen with phone number input

### Step 3: Enter Your Phone Number
1. Enter your actual phone number (the one on this device)
2. Make sure it's the same number that will receive the OTP SMS
3. Click **"Send OTP"** button

### Step 4: Wait for OTP SMS
1. You should receive an SMS with a 6-digit OTP code
2. **Keep the app open and in the foreground**
3. Do NOT switch to another app

### Step 5: Watch the Magic! ✨
When the SMS arrives:
- ✅ The OTP should **automatically fill** all 6 boxes
- ✅ After 0.5 seconds, the form should **auto-submit**
- ✅ You should be **logged in** without typing anything!

---

## 🔍 Troubleshooting

### If OTP Doesn't Auto-Fill:

#### Problem 1: Permissions Not Granted
**Solution:**
1. Go to: Settings → Apps → Dharma → Permissions
2. Enable **SMS** permission
3. Restart the app and try again

#### Problem 2: App in Background
**Solution:**
- Make sure the app is **open and visible** when SMS arrives
- Don't minimize or switch apps while waiting for OTP

#### Problem 3: SMS Format Not Recognized
**Solution:**
- Check if the SMS contains a 6-digit number
- The SMS should have keywords like "OTP", "code", "verification"
- Example: "Your OTP is 123456"

#### Problem 4: First Time - Permission Prompt
**Solution:**
- When you first use the feature, Android will ask for SMS permission
- Click **"Allow"** or **"While using the app"**
- Try sending OTP again after granting permission

### Manual Entry (Fallback)
If auto-fill doesn't work, you can still:
- Manually type the 6-digit OTP in the boxes
- The form will auto-submit when you enter the 6th digit

---

## 🎯 What Should Happen

### Expected Behavior:
```
1. Enter phone number → Click "Send OTP"
   ↓
2. OTP screen appears (6 empty boxes)
   ↓
3. SMS arrives with OTP
   ↓
4. 🎯 All 6 boxes fill automatically
   ↓
5. Form auto-submits after 0.5 seconds
   ↓
6. You're logged in!
```

### Debug Logs to Check:
If you want to see what's happening, check the Flutter console for these logs:
- `👂 Starting to listen for OTP SMS...` - Listener started
- `📩 SMS Code detected: XXXXXX` - OTP detected
- `✅ OTP auto-filled: XXXXXX` - OTP filled
- `✅ OTP FORM VALIDATION PASSED` - Form validated
- `✅ OTP verified successfully` - Login successful

---

## 📋 Checklist Before Testing

- [ ] App running on **physical Android device** (not emulator/desktop/web)
- [ ] Device has **SIM card** and can receive SMS
- [ ] **SMS permissions** granted to the app
- [ ] Using **real phone number** that will receive OTP
- [ ] App is **open and in foreground** when SMS arrives
- [ ] Test OTP will be sent to the **same device** running the app

---

## 💡 Pro Tips

1. **Keep App in Foreground**: Don't switch apps while waiting for OTP
2. **Use Real Number**: Test with the phone number of the device you're using
3. **Check Permissions**: If it fails, check SMS permissions first
4. **Look for Logs**: Console logs will tell you if OTP was detected
5. **Try Manual Entry**: If auto-fill fails, you can still type the OTP

---

## ✅ Success Indicators

You'll know it's working when you see:
- ✨ All 6 boxes fill up automatically when SMS arrives
- ✨ No need to type anything
- ✨ Form submits by itself after 0.5 seconds
- ✨ Success message appears
- ✨ You're logged in!

---

## 🚀 Ready to Test!

Your app is now running on your Android device. Follow the steps above to test the OTP auto-fill feature. 

**Remember**: Auto-fill ONLY works on physical Android devices with SMS capability!

Good luck! 🎉
