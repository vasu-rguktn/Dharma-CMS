package com.dharma.cms

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class NativeSpeechRecognizer(
    private val context: Context,
    private val methodChannel: MethodChannel
) {
    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false
    private var shouldContinueListening = false
    private var currentLanguage = "te-IN"
    private var lastRecognizedText = ""
    
    companion object {
        private const val TAG = "NativeSpeechRecognizer"
    }
    
    fun startListening(language: String) {
        Log.d(TAG, "startListening called with language: $language")
        currentLanguage = language
        shouldContinueListening = true
        lastRecognizedText = ""
        
        if (isListening) {
            Log.d(TAG, "Already listening, restarting...")
            stopListeningInternal()
        }
        
        initializeAndStart()
    }
    
    fun stopListening() {
        Log.d(TAG, "stopListening called")
        shouldContinueListening = false
        stopListeningInternal()
    }
    
    fun destroy() {
        Log.d(TAG, "destroy called")
        shouldContinueListening = false
        stopListeningInternal()
        speechRecognizer?.destroy()
        speechRecognizer = null
    }
    
    private fun initializeAndStart() {
        try {
            // Create speech recognizer if needed
            if (speechRecognizer == null) {
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
                speechRecognizer?.setRecognitionListener(recognitionListener)
            }
            
            // Create intent with configuration
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                // Basic configuration
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, currentLanguage)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)  // Get multiple alternatives
                
                // Configure silence thresholds for continuous listening
                // INCREASED values to prevent word cutoff
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 15000L)  // 15s
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 8000L)  // 8s
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 500L)  // 0.5s
                
                // Language preferences
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, currentLanguage)
                putExtra(RecognizerIntent.EXTRA_ONLY_RETURN_LANGUAGE_PREFERENCE, false)
                
                // SPEECH HINTS - Improve recognition of domain-specific terms
                val hints = ArrayList<String>()
                // Educational institutions
                hints.add("IIIT")
                hints.add("Nuzvid")
                hints.add("IIIT Nuzvid")
                hints.add("RGUKT")
                // Legal/Police terms
                hints.add("harassment")
                hints.add("complaint")
                hints.add("police station")
                hints.add("FIR")
                hints.add("legal")
                hints.add("advocate")
                hints.add("court")
                hints.add("case")
                hints.add("witness")
                hints.add("accused")
                hints.add("victim")
                // Common complaint terms
                hints.add("threatening")
                hints.add("abusive")
                hints.add("distress")
                hints.add("mental")
                hints.add("physical")
                
                putExtra(RecognizerIntent.EXTRA_BIASING_STRINGS, hints)
            }
            
            // Start listening
            speechRecognizer?.startListening(intent)
            isListening = true
            
            // Notify Flutter
            methodChannel.invokeMethod("onListeningStarted", null)
            Log.d(TAG, "Speech recognition started with hints and improved thresholds")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error starting speech recognition", e)
            methodChannel.invokeMethod("onError", mapOf(
                "error" to "START_ERROR",
                "message" to "Failed to start: ${e.message}"
            ))
        }
    }
    
    private fun stopListeningInternal() {
        if (isListening) {
            speechRecognizer?.stopListening()
            isListening = false
            methodChannel.invokeMethod("onListeningStopped", null)
            Log.d(TAG, "Speech recognition stopped")
        }
    }
    
    private fun restartListening() {
        if (shouldContinueListening) {
            Log.d(TAG, "Auto-restarting speech recognition...")
            // Longer delay to ensure system releases resources
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                if (shouldContinueListening) {
                    initializeAndStart()
                }
            }, 1000) // Increased from 300ms to 1000ms
        }
    }
    
    private val recognitionListener = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {
            Log.d(TAG, "onReadyForSpeech")
        }
        
        override fun onBeginningOfSpeech() {
            Log.d(TAG, "onBeginningOfSpeech")
        }
        
        override fun onRmsChanged(rmsdB: Float) {
            // Volume level changed - not used
        }
        
        override fun onBufferReceived(buffer: ByteArray?) {
            // Audio buffer received - not used
        }
        
        override fun onEndOfSpeech() {
            Log.d(TAG, "onEndOfSpeech - will restart if shouldContinue=$shouldContinueListening")
            isListening = false
            // Auto-restart for continuous listening
            restartListening()
        }
        
        override fun onError(error: Int) {
            val errorMessage = when (error) {
                SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                SpeechRecognizer.ERROR_CLIENT -> "Client side error"
                SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
                SpeechRecognizer.ERROR_NETWORK -> "Network error"
                SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                SpeechRecognizer.ERROR_NO_MATCH -> "No speech match"
                SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognition service busy"
                SpeechRecognizer.ERROR_SERVER -> "Server error"
                SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
                else -> "Unknown error: $error"
            }
            
            Log.d(TAG, "onError: $errorMessage (code: $error)")
            
            // Handle different error types
            when (error) {
                SpeechRecognizer.ERROR_NO_MATCH,
                SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> {
                    // Normal during pauses - just restart
                    isListening = false
                    restartListening()
                }
                SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> {
                    // BUSY error - DON'T restart immediately, let it settle
                    Log.w(TAG, "Recognizer busy - stopping auto-restart to prevent loop")
                    isListening = false
                    methodChannel.invokeMethod("onError", mapOf(
                        "error" to "RECOGNITION_ERROR",
                        "message" to errorMessage,
                        "code" to error
                    ))
                    // Don't call restartListening() - prevents infinite loop
                }
                else -> {
                    // Other errors - notify and try restart
                    isListening = false
                    methodChannel.invokeMethod("onError", mapOf(
                        "error" to "RECOGNITION_ERROR",
                        "message" to errorMessage,
                        "code" to error
                    ))
                    restartListening()
                }
            }
        }
        
        override fun onResults(results: Bundle?) {
            Log.d(TAG, "onResults (final)")
            isListening = false
            
            val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            if (!matches.isNullOrEmpty()) {
                val text = matches[0]
                Log.d(TAG, "Final result: $text")
                
                // Check for duplicates
                if (!isDuplicate(text)) {
                    lastRecognizedText = text
                    methodChannel.invokeMethod("onFinalResult", mapOf("text" to text))
                }
            }
            
            // Auto-restart for continuous listening
            restartListening()
        }
        
        override fun onPartialResults(partialResults: Bundle?) {
            val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            if (!matches.isNullOrEmpty()) {
                val text = matches[0]
                Log.d(TAG, "Partial result: $text")
                
                // Send partial results (always replace, never append)
                methodChannel.invokeMethod("onPartialResult", mapOf("text" to text))
            }
        }
        
        override fun onEvent(eventType: Int, params: Bundle?) {
            Log.d(TAG, "onEvent: $eventType")
        }
    }
    
    private fun isDuplicate(newText: String): Boolean {
        // Check if new text is a duplicate or prefix of last recognized text
        if (lastRecognizedText.isEmpty()) return false
        
        // If new text starts with last text, it's likely a duplicate
        if (newText.startsWith(lastRecognizedText)) {
            Log.d(TAG, "Duplicate detected: '$newText' starts with '$lastRecognizedText'")
            return true
        }
        
        // If last text starts with new text, it's also a duplicate
        if (lastRecognizedText.startsWith(newText)) {
            Log.d(TAG, "Duplicate detected: '$lastRecognizedText' starts with '$newText'")
            return true
        }
        
        return false
    }
}
