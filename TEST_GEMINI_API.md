# Gemini API Key Tester (JavaScript/Node.js)

## 🎯 Purpose

This script tests if your Gemini API key is working correctly before using it in the Crime Scene analysis feature.

## 🚀 Quick Start

### Step 1: Install Dependencies

```bash
cd c:\Users\APSSDC\Desktop\main\Dharma-CMS
npm install
```

This will install `@google/generative-ai` package.

### Step 2: Get Your API Key

1. Visit: https://makersuite.google.com/app/apikey
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated key

### Step 3: Update the Script

Open `test_gemini_api.js` and replace:

```javascript
const API_KEY = 'YOUR_API_KEY_HERE';
```

With your actual key:

```javascript
const API_KEY = 'AIzaSyC...your-actual-key-here';
```

### Step 4: Run the Test

```bash
# Option 1: Direct run
node test_gemini_api.js

# Option 2: Using npm script
npm test

# Option 3: Using npm run
npm run test-api
```

## ✅ Expected Output (Success)

```
🔍 Testing Gemini API Key...

📡 Initializing Gemini AI...
✅ Gemini AI initialized successfully

📝 Test 1: Simple Text Generation
   Prompt: "Say hello in 5 words"
   Response: Hello there, how are you?
   ✅ Text generation works!

📋 Test 2: Available Models
   Your API key can access:
   - gemini-2.0-flash-exp (latest, recommended)
   - gemini-1.5-flash
   - gemini-1.5-pro
   ✅ Models accessible!

📊 Test 3: Streaming Response
   Testing streaming capability...
   Streamed response: 1, 2, 3
   ✅ Streaming works!

💬 Test 4: Multi-turn Conversation
   User: Hello!
   AI: Hello! How can I help you today?
   User: What is 2+2?
   AI: 2 + 2 = 4
   ✅ Conversation works!

═══════════════════════════════════════
✅ ALL TESTS PASSED!
═══════════════════════════════════════
Your Gemini API key is working correctly.
You can now use it in your application.

💡 Usage in your app:
   const { GoogleGenerativeAI } = require('@google/generative-ai');
   const genAI = new GoogleGenerativeAI('AIzaSyC...');
   const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash-exp' });
   const result = await model.generateContent(prompt);
   const response = await result.response;
   const text = response.text();

📊 API Limits (Free Tier):
   - 60 requests per minute
   - 1 million tokens per day
   - Free forever!
```

## ❌ Common Errors

### Error 1: Invalid API Key

```
❌ TEST FAILED!
Error: API key not valid

🔑 API Key Issue:
   - Your API key might be invalid
   - Check if you copied the full key
   - Verify the key at: https://makersuite.google.com/app/apikey
   - Make sure there are no extra spaces
```

**Solution**: 
- Double-check you copied the entire API key
- Make sure there are no extra spaces
- Generate a new key if needed

### Error 2: Module Not Found

```
Error: Cannot find module '@google/generative-ai'
```

**Solution**:
```bash
npm install @google/generative-ai
```

### Error 3: Quota Exceeded

```
❌ TEST FAILED!
Error: RESOURCE_EXHAUSTED

📊 Quota Issue:
   - You might have exceeded your API quota
   - Check your usage at: https://console.cloud.google.com
   - Free tier: 60 requests/min, 1M tokens/day
   - Wait a few minutes and try again
```

**Solution**:
- Wait a few minutes for quota to reset
- Check your usage at Google Cloud Console
- Upgrade to paid plan if needed

### Error 4: Network Error

```
❌ TEST FAILED!
Error: ENOTFOUND

🌐 Network Issue:
   - Check your internet connection
   - Verify firewall settings
   - Try disabling VPN if using one
```

**Solution**:
- Check internet connection
- Disable VPN if using one
- Check firewall/proxy settings

## 📋 What the Script Tests

1. **API Key Validity**: Verifies the key is accepted by Google
2. **Text Generation**: Tests basic AI response generation
3. **Streaming**: Tests real-time streaming responses
4. **Conversation**: Tests multi-turn chat capability

## 🔧 Installation Troubleshooting

### Node.js Not Installed

**Error**: `node: command not found`

**Solution**: Install Node.js from https://nodejs.org

```bash
# Check if Node.js is installed
node --version

# Check if npm is installed
npm --version
```

### Permission Error

**Error**: `EACCES: permission denied`

**Solution**: Run with appropriate permissions

```bash
# Windows (as Administrator)
npm install

# Or use --force flag
npm install --force
```

### Old Node.js Version

**Error**: `Unsupported engine`

**Solution**: Update Node.js to latest LTS version

```bash
# Check current version
node --version

# Should be v18.0.0 or higher
```

## 💡 After Testing

Once the test passes:

1. **Your API key is confirmed working** ✅
2. **You can use it in your Flutter app**
3. **Update `case_detail_screen.dart`**:

```dart
// Line ~550
const apiKey = 'YOUR_ACTUAL_KEY_HERE';
```

## 📊 API Limits

### Free Tier (Default)

| Limit | Value |
|-------|-------|
| Requests per minute | 60 |
| Tokens per day | 1,000,000 |
| Cost | **FREE** |

### Paid Tier

| Limit | Value |
|-------|-------|
| Requests per minute | Higher |
| Tokens per day | More |
| Cost | Pay per use |

Check pricing: https://ai.google.dev/pricing

## 🔒 Security Best Practices

**⚠️ IMPORTANT**: 

- ❌ Never commit API keys to Git
- ❌ Don't share your API key publicly
- ✅ Use environment variables in production
- ✅ Rotate keys regularly

### Better Practice (Production)

Create a `.env` file:

```bash
GEMINI_API_KEY=your-actual-key-here
```

Update script:

```javascript
require('dotenv').config();
const API_KEY = process.env.GEMINI_API_KEY;
```

Install dotenv:

```bash
npm install dotenv
```

## 📞 Support Resources

### Official Documentation
- Gemini API Docs: https://ai.google.dev/docs
- Node.js SDK: https://ai.google.dev/tutorials/node_quickstart
- API Reference: https://ai.google.dev/api

### Troubleshooting
- API Status: https://status.cloud.google.com
- Google Cloud Console: https://console.cloud.google.com
- Stack Overflow: https://stackoverflow.com/questions/tagged/google-gemini

## 🎯 Usage Examples

### Basic Text Generation

```javascript
const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(API_KEY);
const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash-exp' });

const result = await model.generateContent('Explain quantum physics in simple terms');
const response = await result.response;
console.log(response.text());
```

### Streaming Response

```javascript
const result = await model.generateContentStream('Write a short story');

for await (const chunk of result.stream) {
  const chunkText = chunk.text();
  process.stdout.write(chunkText);
}
```

### Multi-turn Chat

```javascript
const chat = model.startChat({
  history: [],
});

const msg1 = await chat.sendMessage('Hello!');
console.log(msg1.response.text());

const msg2 = await chat.sendMessage('Tell me a joke');
console.log(msg2.response.text());
```

### With Image (Crime Scene Analysis)

```javascript
const fs = require('fs');

function fileToGenerativePart(path, mimeType) {
  return {
    inlineData: {
      data: Buffer.from(fs.readFileSync(path)).toString('base64'),
      mimeType
    },
  };
}

const imagePart = fileToGenerativePart('crime_scene.jpg', 'image/jpeg');

const result = await model.generateContent([
  'Analyze this crime scene image',
  imagePart
]);

console.log(result.response.text());
```

## ✨ Summary

This test script helps you:
- ✅ Verify API key works
- ✅ Test before integrating
- ✅ Get helpful error messages
- ✅ Avoid runtime errors in app
- ✅ Learn API usage patterns

Run it whenever you:
- Get a new API key
- Change API keys
- Encounter API errors
- Deploy to new environment
- Update to new model version

## 🚀 Next Steps

After successful test:

1. ✅ API key confirmed working
2. ✅ Copy key to Flutter app
3. ✅ Test crime scene analysis
4. ✅ Deploy with confidence!
