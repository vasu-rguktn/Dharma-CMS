# Gemini API Key Tester

## 🎯 Purpose

This script tests if your Gemini API key is working correctly before using it in the Crime Scene analysis feature.

## 🚀 How to Use

### Step 1: Get Your API Key

1. Visit: https://makersuite.google.com/app/apikey
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated key

### Step 2: Update the Script

Open `test_gemini_api.dart` and replace:

```dart
const apiKey = 'YOUR_API_KEY_HERE';
```

With your actual key:

```dart
const apiKey = 'AIzaSyC...your-actual-key-here';
```

### Step 3: Run the Test

```bash
cd c:\Users\APSSDC\Desktop\main\Dharma-CMS\frontend
dart run test_gemini_api.dart
```

## ✅ Expected Output (Success)

```
🔍 Testing Gemini API Key...

📡 Initializing Gemini model...
✅ Model initialized successfully

📝 Test 1: Simple Text Generation
   Prompt: "Say hello in 5 words"
   Response: Hello there, how are you?
   ✅ Text generation works!

📋 Test 2: Available Models
   Your API key can access:
   - gemini-2.0-flash-exp (latest)
   - gemini-1.5-flash
   - gemini-1.5-pro
   ✅ Models accessible!

📊 Test 3: Token Counting
   Prompt: "This is a test prompt for counting tokens."
   Token count: 10
   ✅ Token counting works!

═══════════════════════════════════════
✅ ALL TESTS PASSED!
═══════════════════════════════════════
Your Gemini API key is working correctly.
You can now use it in your application.
```

## ❌ Common Errors

### Error 1: Invalid API Key

```
❌ TEST FAILED!
Error: Invalid API key

🔑 API Key Issue:
   - Your API key might be invalid
   - Check if you copied the full key
   - Verify the key at: https://makersuite.google.com/app/apikey
```

**Solution**: 
- Double-check you copied the entire API key
- Make sure there are no extra spaces
- Generate a new key if needed

### Error 2: Quota Exceeded

```
❌ TEST FAILED!
Error: Quota exceeded

📊 Quota Issue:
   - You might have exceeded your API quota
   - Check your usage at: https://console.cloud.google.com
```

**Solution**:
- Check your quota at Google Cloud Console
- Wait for quota to reset (usually daily)
- Upgrade to a paid plan if needed

### Error 3: Network Error

```
❌ TEST FAILED!
Error: Network connection failed

🌐 Network Issue:
   - Check your internet connection
   - Verify firewall settings
```

**Solution**:
- Check internet connection
- Disable VPN if using one
- Check firewall/proxy settings

## 📋 What the Script Tests

1. **API Key Validity**: Verifies the key is accepted by Google
2. **Text Generation**: Tests basic AI response generation
3. **Model Access**: Confirms you can access Gemini models
4. **Token Counting**: Checks token counting functionality

## 🔧 Troubleshooting

### Script Won't Run

**Error**: `dart: command not found`

**Solution**: Make sure Flutter/Dart is installed and in PATH

```bash
flutter doctor
```

### Import Error

**Error**: `Package not found: google_generative_ai`

**Solution**: Run pub get first

```bash
cd frontend
flutter pub get
dart run test_gemini_api.dart
```

### Permission Error

**Error**: `Permission denied`

**Solution**: Run with appropriate permissions or from correct directory

## 💡 After Testing

Once the test passes:

1. **Copy your API key**
2. **Update `case_detail_screen.dart`**:

```dart
// Line ~550
const apiKey = 'YOUR_ACTUAL_KEY_HERE';
```

3. **Test in the app**:
   - Open a case
   - Go to Crime Scene tab
   - Capture evidence
   - Tap "Analyze with AI"
   - Should work! ✅

## 📊 API Limits

### Free Tier

- **Requests**: 60 requests per minute
- **Tokens**: 1 million tokens per day
- **Cost**: Free

### Paid Tier

- **Requests**: Higher limits
- **Tokens**: More tokens
- **Cost**: Pay per use

Check current pricing: https://ai.google.dev/pricing

## 🔒 Security

**⚠️ IMPORTANT**: 

- Never commit API keys to Git
- Don't share your API key publicly
- Use environment variables in production
- Rotate keys regularly

### Better Practice (Production)

Instead of hardcoding the key:

```dart
// Use environment variables
final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
```

## 📞 Support

If tests fail and you can't resolve:

1. Check Gemini API status: https://status.cloud.google.com
2. Review API documentation: https://ai.google.dev/docs
3. Check Google Cloud Console: https://console.cloud.google.com

## ✨ Summary

This test script helps you:
- ✅ Verify API key works
- ✅ Test before integrating
- ✅ Get helpful error messages
- ✅ Avoid runtime errors in app

Run it whenever you:
- Get a new API key
- Change API keys
- Encounter API errors
- Deploy to new environment
