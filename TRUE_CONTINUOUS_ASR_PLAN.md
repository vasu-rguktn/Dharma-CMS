# TRUE CONTINUOUS ASR - Plan of Action

## 🎯 OBJECTIVE
Implement truly continuous speech recognition that:
- ✅ Stays active until user manually stops (tap mic button or send)
- ✅ Handles pauses gracefully without auto-stopping
- ✅ Accumulates text across multiple utterances
- ✅ NO manual restarts needed
- ✅ NO character-by-character repetition
- ✅ Matches browser continuous speech behavior

## 🔍 CURRENT PROBLEM ANALYSIS

### Issue 1: SDK Auto-Stops After Silence
**Problem:** The `speech_to_text` SDK on mobile detects silence and sends `finalResult=true`, which causes the SDK to stop listening.

**Evidence:**
- User speaks "hello" → SDK recognizes → Sends final result → **STOPS**
- User speaks again → Nothing happens (mic is dead)
- User must manually restart mic

**Root Cause:** The SDK's default behavior is to treat `finalResult=true` as "end of session"

### Issue 2: Current Implementation Relies on finalResult
**Problem:** Our current code uses `result.finalResult` to detect pauses:
```dart
if (result.finalResult) {
  // Finalize and add to transcript
  // BUT: SDK stops listening after this!
}
```

**This causes:**
- SDK stops after each pause
- User must manually restart
- Terrible UX

### Issue 3: Auto-Restart Logic Exists But Doesn't Work Well
**Current code has:**
- `_safeRestartListening()` function
- Monitoring timers
- Status handlers

**But:**
- Creates gaps in listening
- Causes repetition issues
- Not seamless for user

## 📋 PLAN OF ACTION

### PHASE 1: Disable Auto-Stop Behavior ✅

**Goal:** Prevent SDK from stopping after silence/pauses

**Actions:**
1. **Remove finalResult-based logic**
   - Stop using `result.finalResult` to finalize text
   - Treat all results as partial/ongoing
   
2. **Aggressive pause tolerance**
   - Already set: `pauseFor: Duration(hours: 1)`
   - Already set: `listenFor: Duration(hours: 1)`
   - Keep these settings

3. **Disable silence detection**
   - Set `onSoundLevelChange` to ignore silence
   - Don't react to sound level drops

### PHASE 2: Implement True Continuous Accumulation ✅

**Goal:** Accumulate text without relying on finalResult

**Strategy:**
Instead of using `finalResult` to finalize, we'll:
- **Always treat results as partial**
- **Detect new utterances by comparing text**
- **Accumulate when new text appears after a gap**

**Logic:**
```dart
onResult: (result) {
  final newWords = result.recognizedWords.trim();
  
  // Strategy: Compare with current transcript
  if (newWords.isEmpty) {
    // Silence - do nothing, keep listening
    return;
  }
  
  // Check if this is a NEW utterance (doesn't start with current)
  if (!newWords.startsWith(_currentTranscript)) {
    // New utterance detected!
    // Finalize previous and start new
    if (_currentTranscript.isNotEmpty) {
      _finalizedTranscript += ' $_currentTranscript';
    }
    _currentTranscript = newWords;
  } else {
    // Continuation of current utterance
    _currentTranscript = newWords;
  }
  
  // Display: finalized + current
  _controller.text = '$_finalizedTranscript $_currentTranscript'.trim();
}
```

### PHASE 3: Auto-Restart on Actual Stop ✅

**Goal:** Detect when SDK actually stops and restart seamlessly

**Actions:**
1. **Monitor `onStatus` for 'done' or 'notListening'**
   - When detected, immediately restart
   - Preserve accumulated text
   
2. **Implement seamless restart**
   ```dart
   onStatus: (status) {
     if (status == 'done' || status == 'notListening') {
       if (_isRecording && mounted) {
         // SDK stopped - restart immediately
         _seamlessRestart();
       }
     }
   }
   ```

3. **Preserve state during restart**
   - Keep `_finalizedTranscript` intact
   - Keep `_currentTranscript` intact
   - Don't clear text field

### PHASE 4: Remove Manual Restart Requirement ✅

**Goal:** User never needs to manually restart mic

**Actions:**
1. **Remove any UI that suggests manual restart**
2. **Keep mic button as simple toggle:**
   - Tap once → Start (stays on)
   - Tap again → Stop
3. **No intermediate states**

### PHASE 5: Handle Edge Cases ✅

**Goal:** Robust behavior in all scenarios

**Edge Cases:**
1. **Long silence (5+ seconds)**
   - Action: Keep listening, don't stop
   - Display: Show last recognized text
   
2. **Background noise**
   - Action: Ignore, keep listening
   - Display: Don't update text
   
3. **SDK errors**
   - Action: Auto-restart with same state
   - Display: Keep existing text
   
4. **User manually stops**
   - Action: Finalize all text
   - Display: Show complete transcript

## 🔧 IMPLEMENTATION DETAILS

### Key Changes Needed

#### 1. Modify `onResult` Handler
**Current:** Uses `finalResult` to finalize
**New:** Uses text comparison to detect new utterances

#### 2. Modify `onStatus` Handler
**Current:** Ignores 'done' status
**New:** Detects 'done' and auto-restarts

#### 3. Add Seamless Restart Function
**New function:**
```dart
Future<void> _seamlessRestart() async {
  if (!_isRecording || !mounted) return;
  
  print('SDK stopped - seamlessly restarting...');
  
  // Don't clear state!
  // Just restart listening
  await _speech.listen(
    localeId: _currentSttLang,
    listenFor: const Duration(hours: 1),
    pauseFor: const Duration(hours: 1),
    partialResults: true,
    cancelOnError: false,
    onResult: _handleResult,
    onStatus: _handleStatus,
  );
}
```

#### 4. Remove finalResult Logic
**Remove:**
- All `if (result.finalResult)` checks
- Finalization based on SDK signals

**Replace with:**
- Text comparison-based detection
- Manual finalization only on user action (stop/send)

### State Management

**Variables:**
- `_finalizedTranscript` - Accumulated finalized text
- `_currentTranscript` - Current utterance being spoken
- `_lastRecognizedText` - Last text from SDK (for comparison)
- `_isRecording` - Mic is active
- `_currentSttLang` - Language for restarts

**Flow:**
1. User taps mic → `_isRecording = true`
2. SDK sends results → Accumulate in `_currentTranscript`
3. New utterance detected → Move to `_finalizedTranscript`
4. SDK stops → Auto-restart seamlessly
5. User taps stop/send → Finalize all text

## 📊 EXPECTED BEHAVIOR

### Scenario 1: Continuous Speech with Pauses
```
User: "hello" [pause 3s] "how are you" [pause 2s] "I need help"

Timeline:
0s: User says "hello"
1s: Display: "hello"
3s: [pause - SDK might stop]
3.1s: [auto-restart - seamless]
4s: User says "how are you"
5s: Display: "hello how are you"
7s: [pause - SDK might stop]
7.1s: [auto-restart - seamless]
8s: User says "I need help"
9s: Display: "hello how are you I need help"

User taps stop
Final: "hello how are you I need help" ✅
```

### Scenario 2: Long Pauses (Elderly User)
```
User: "yesterday" [pause 10s thinking] "around 3 PM" [pause 8s thinking] "near market"

Result: "yesterday around 3 PM near market" ✅
No manual restart needed ✅
```

### Scenario 3: Background Noise
```
User: "someone stolen" [car horn] "my purse"

Result: "someone stolen my purse" ✅
Noise ignored ✅
```

## ✅ SUCCESS CRITERIA

1. **No Manual Restart**
   - User taps mic once
   - Speaks with any number of pauses
   - Never needs to tap mic again until done

2. **No Repetition**
   - Text displays cleanly
   - No character-by-character repetition
   - No duplicate words

3. **Seamless Accumulation**
   - All utterances accumulated
   - Pauses handled gracefully
   - No lost text

4. **Robust Error Handling**
   - SDK errors don't break flow
   - Auto-recovery from stops
   - User never sees errors

5. **Matches Browser Behavior**
   - Same UX as web continuous speech
   - No mobile-specific quirks
   - Consistent experience

## 🚀 IMPLEMENTATION ORDER

1. **Step 1:** Modify `onResult` to remove finalResult logic
2. **Step 2:** Implement text comparison-based accumulation
3. **Step 3:** Add seamless restart on SDK stop
4. **Step 4:** Test with various pause lengths
5. **Step 5:** Test with background noise
6. **Step 6:** Test with elderly user scenarios
7. **Step 7:** Polish and optimize

## 📝 FILES TO MODIFY

**Primary:**
- `frontend/lib/screens/ai_legal_chat_screen.dart`
  - `_toggleRecording()` function (lines 872-1122)
  - `onResult` handler (lines 1043-1085)
  - `onStatus` handler (lines 983-1014)
  - Add `_seamlessRestart()` function
  - Add `_handleResult()` function
  - Add `_handleStatus()` function

**Testing:**
- Test on Android device
- Test on iOS device
- Test with various pause lengths
- Test with background noise

## 🎯 FINAL OUTCOME

**User Experience:**
1. User taps mic button → Mic turns on (visual indicator)
2. User speaks naturally with pauses
3. Text accumulates in real-time
4. User taps stop or send → Mic turns off
5. Complete transcript is ready

**No:**
- ❌ Manual restarts
- ❌ Text repetition
- ❌ Lost text after pauses
- ❌ Confusing UI states

**Yes:**
- ✅ Truly continuous listening
- ✅ Natural pause handling
- ✅ Clean text accumulation
- ✅ Simple, intuitive UX

---

## 🤔 DECISION POINT

**Do you approve this plan?**

If yes, I will proceed with implementation in this order:
1. Remove finalResult-based logic
2. Implement text comparison accumulation
3. Add seamless auto-restart
4. Test and refine

**Any modifications needed to the plan?**
