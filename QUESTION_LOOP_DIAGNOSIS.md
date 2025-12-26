# Question Looping Issue - Diagnosis Guide

## 🐛 ISSUE

**Problem:** Questions are being asked repeatedly in a loop even after providing responses.

## 🔍 DIAGNOSIS STEPS

I've added debug logging to help identify the issue. Here's what to check:

### Step 1: Check Flutter Logs

Run the app and watch the console output. You should see:

```
📝 First message set as initial_details: "your first message"
📝 Added to history: "your response"
📚 Current history length: 2
🚀 Sending to backend:
   History items: 2
   Payload: {full_name: ..., chat_history: [...]}
Backend Response: {...}
```

### Step 2: Identify the Problem

**Scenario A: History Not Growing**
```
📝 Added to history: "response 1"
📚 Current history length: 2
📝 Added to history: "response 2"
📚 Current history length: 2  ← PROBLEM: Should be 4!
```
**Cause:** History is being cleared somewhere
**Solution:** Check if `_dynamicHistory.clear()` is being called incorrectly

**Scenario B: Backend Not Receiving History**
```
🚀 Sending to backend:
   History items: 4
   Payload: {chat_history: []}  ← PROBLEM: Empty!
```
**Cause:** History not being serialized properly
**Solution:** Check payload construction

**Scenario C: Backend Ignoring History**
```
Backend Response: {status: 'question', message: 'Same question again'}
```
**Cause:** Backend LLM not considering chat history
**Solution:** Backend issue - check backend logs

## 🔧 COMMON CAUSES & FIXES

### Cause 1: Chat State Being Reset
**Check:** Is `_resetChatState()` being called unexpectedly?

**Fix:** Ensure `_resetChatState()` is only called on:
- Clear Chat button
- Close Chat button
- Screen re-entry (with `clearMessages: true`)

### Cause 2: History Not Persisting
**Check:** Is `_dynamicHistory` a local variable or state variable?

**Current Implementation:**
```dart
final List<Map<String, String>> _dynamicHistory = [];
```

This should persist across messages. If it's being cleared, check for:
```dart
_dynamicHistory.clear();  // Should NOT be in _handleSend
```

### Cause 3: Backend Not Processing History
**Check Backend Logs:** The backend should show it's receiving the history.

**Expected Backend Behavior:**
1. Receive `chat_history` array
2. Use it as context for LLM
3. Generate next question based on what was already asked
4. Return new question (not repeat)

## 📝 WHAT TO LOOK FOR IN LOGS

### Good Flow (No Loop):
```
User: "My complaint is about harassment"
📝 First message set as initial_details: "My complaint is about harassment"
🚀 Sending to backend: History items: 0

Backend asks: "What is your name?"
📝 Added to history: "What is your name?"
📚 Current history length: 1

User: "John Doe"
📝 Added to history: "John Doe"
📚 Current history length: 2
🚀 Sending to backend: History items: 2

Backend asks: "Where did this happen?"  ← NEW QUESTION ✅
```

### Bad Flow (Looping):
```
User: "My complaint is about harassment"
Backend asks: "What is your name?"

User: "John Doe"
📝 Added to history: "John Doe"
📚 Current history length: 2
🚀 Sending to backend: History items: 2

Backend asks: "What is your name?"  ← SAME QUESTION ❌
```

## 🎯 IMMEDIATE ACTIONS

1. **Hot Restart the App:**
   ```
   Press 'R' in Flutter terminal
   ```

2. **Start Fresh Chat:**
   - Clear any existing chat
   - Start from beginning

3. **Watch Console:**
   - Look for the 📝, 📚, and 🚀 emojis
   - Check history length increases
   - Check payload shows history

4. **Test Flow:**
   ```
   1. Give initial complaint
   2. Answer first question
   3. Check if second question is different
   ```

## 🔍 SPECIFIC CHECKS

### Check 1: Is History Growing?
```dart
// After each message, history should grow
Message 1: length = 1 (bot question)
Message 2: length = 2 (user answer)
Message 3: length = 3 (bot question)
Message 4: length = 4 (user answer)
```

### Check 2: Is Payload Correct?
```dart
// Payload should include all history
{
  'chat_history': [
    {'role': 'assistant', 'content': 'What is your name?'},
    {'role': 'user', 'content': 'John Doe'},
    {'role': 'assistant', 'content': 'Where did this happen?'},
    {'role': 'user', 'content': 'At work'}
  ]
}
```

### Check 3: Backend Response
```dart
// Backend should NOT repeat questions
Backend Response: {
  status: 'question',
  message: 'NEW question here'  // Should be different each time
}
```

## 🚀 NEXT STEPS

1. **Run the app** with hot restart
2. **Check console logs** for the debug messages
3. **Share the logs** showing:
   - History length progression
   - Payload being sent
   - Backend response

This will help identify if the issue is:
- **Frontend:** History not being maintained
- **Backend:** LLM not using history properly

## 📊 EXPECTED VS ACTUAL

**Expected:**
```
Q1: "What is your name?" → A1: "John"
Q2: "Where did it happen?" → A2: "At work"
Q3: "When did it happen?" → A3: "Yesterday"
```

**If Looping:**
```
Q1: "What is your name?" → A1: "John"
Q1: "What is your name?" → A1: "John"  ← LOOP
Q1: "What is your name?" → A1: "John"  ← LOOP
```

---

**Status:** Debug logging added
**Action:** Hot restart and check console logs
**Report:** Share the console output showing the 📝📚🚀 messages

The debug logs will help us identify exactly where the problem is! 🔍
