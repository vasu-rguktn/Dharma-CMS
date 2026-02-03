package com.example.dharma

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SOUND_CHANNEL = "com.dharma.sound_control"
    private val ASR_CHANNEL = "com.dharma.native_asr"
    
    private var originalNotificationVolume = 0
    private var wasMuted = false
    private var nativeSpeechRecognizer: NativeSpeechRecognizer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Sound control channel (existing)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SOUND_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "muteSystemSounds" -> {
                    try {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        // Save original volume
                        originalNotificationVolume = audioManager.getStreamVolume(AudioManager.STREAM_NOTIFICATION)
                        wasMuted = audioManager.getStreamVolume(AudioManager.STREAM_NOTIFICATION) == 0
                        
                        // Mute notification stream (where ASR sounds are played)
                        if (!wasMuted) {
                            audioManager.setStreamVolume(AudioManager.STREAM_NOTIFICATION, 0, 0)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("MUTE_ERROR", "Failed to mute system sounds: ${e.message}", null)
                    }
                }
                "unmuteSystemSounds" -> {
                    try {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        // Restore original volume if it wasn't muted before
                        if (!wasMuted && originalNotificationVolume > 0) {
                            audioManager.setStreamVolume(AudioManager.STREAM_NOTIFICATION, originalNotificationVolume, 0)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNMUTE_ERROR", "Failed to unmute system sounds: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Native ASR channel (new)
        val asrChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ASR_CHANNEL)
        nativeSpeechRecognizer = NativeSpeechRecognizer(this, asrChannel)
        
        asrChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    try {
                        val language = call.argument<String>("language") ?: "te-IN"
                        nativeSpeechRecognizer?.startListening(language)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("START_ERROR", "Failed to start listening: ${e.message}", null)
                    }
                }
                "stopListening" -> {
                    try {
                        nativeSpeechRecognizer?.stopListening()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STOP_ERROR", "Failed to stop listening: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    override fun onDestroy() {
        nativeSpeechRecognizer?.destroy()
        nativeSpeechRecognizer = null
        super.onDestroy()
    }
}
