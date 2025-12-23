package com.example.dharma

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.dharma.sound_control"
    private var originalNotificationVolume = 0
    private var wasMuted = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
    }
}
