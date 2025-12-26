# AI Chatbot UX Fixes - Implementation Plan

## 🎯 5 CRITICAL FIXES TO IMPLEMENT

### 1️⃣ ASR-TTS Feedback Loop Prevention
**Problem:** ASR recognizes chatbot's own TTS output
**Solution:** 
- Pause ASR when TTS starts
- Resume ASR when TTS finishes
- Use TTS callbacks: `setStartHandler()` and `setCompletionHandler()`

### 2️⃣ Input Box Auto-Clear
**Problem:** Input field retains old text after sending
**Solution:**
- Clear `_controller.text` immediately after capturing message
- Ensure cursor resets
- Independent from ASR state

### 3️⃣ Chat Session Reset on Re-Entry
**Problem:** Chat persists when navigating back
**Solution:**
- Override `didChangeDependencies()` or use route observer
- Clear chat history on screen re-entry
- Reset all ASR/TTS state

### 4️⃣ Close/Clear Chat Confirmation Dialog
**Problem:** No confirmation when leaving mid-chat
**Solution:**
- Implement `WillPopScope` to intercept back button
- Show dialog with 3 options: Clear Chat, Close Chat, Cancel
- Handle navigation interception

### 5️⃣ Navigation Interruption Handling
**Problem:** No protection against accidental navigation
**Solution:**
- Use `WillPopScope` to block navigation
- Show confirmation dialog
- Only navigate after user confirmation

## 📋 IMPLEMENTATION ORDER

1. **Create centralized reset function** - `_resetChatState()`
2. **Fix input box clearing** - Immediate clear after send
3. **Implement ASR-TTS coordination** - TTS handlers
4. **Add WillPopScope** - Navigation interception
5. **Add confirmation dialog** - Clear/Close/Cancel options
6. **Test all scenarios** - Ensure no regressions

## 🔧 KEY FUNCTIONS TO IMPLEMENT

```dart
// 1. Centralized reset
void _resetChatState({bool clearMessages = true, bool stopASR = false})

// 2. ASR-TTS coordination
void _setupTTSHandlers()
void _pauseASRForTTS()
void _resumeASRAfterTTS()

// 3. Navigation handling
Future<bool> _onWillPop()
Future<void> _showExitDialog()

// 4. Clear vs Close
void _clearChat()  // Reset but stay on screen
void _closeChat()  // Reset and navigate away
```

## ✅ SUCCESS CRITERIA

- [ ] ASR never captures TTS output
- [ ] Input box clears immediately after send
- [ ] Chat resets when re-entering screen
- [ ] Confirmation dialog shows on back press
- [ ] All state properly cleaned up
- [ ] Continuous listening maintained
- [ ] No message concatenation
- [ ] No memory leaks
