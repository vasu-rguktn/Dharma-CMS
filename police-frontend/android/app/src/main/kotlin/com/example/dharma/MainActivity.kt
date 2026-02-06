package com.example.dharma

import android.content.Context
import android.media.AudioManager
import android.os.Environment
import android.content.ContentValues
import android.provider.MediaStore
import android.os.Build
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SOUND_CHANNEL = "com.dharma.sound_control"
    private val ASR_CHANNEL = "com.dharma.native_asr"
    private val DOWNLOAD_CHANNEL = "com.dharma.file_download"
    
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
        
        // File download channel with logging for Android 9
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOWNLOAD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDownloads" -> {
                    try {
                        Log.d("DharmaDownload", "=== Starting file download ===")
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName")
                        
                        if (bytes == null || fileName == null) {
                            Log.e("DharmaDownload", "ERROR: Missing bytes or fileName")
                            result.error("INVALID_ARGS", "Missing bytes or fileName", null)
                            return@setMethodCallHandler
                        }
                        
                        Log.d("DharmaDownload", "File: $fileName, Size: ${bytes.size} bytes, Android: ${Build.VERSION.SDK_INT}")
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            // Android 10+ - Use MediaStore (won't execute on user's Android 9)
                            Log.d("DharmaDownload", "Using MediaStore API (Android 10+)")
                            val contentValues = ContentValues().apply {
                                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                                put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
                                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                            }
                            
                            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                            if (uri != null) {
                                Log.d("DharmaDownload", "Created MediaStore entry: $uri")
                                contentResolver.openOutputStream(uri)?.use { outputStream ->
                                    outputStream.write(bytes)
                                    Log.d("DharmaDownload", "Successfully wrote ${bytes.size} bytes to MediaStore")
                                }
                                result.success(uri.toString())
                            } else {
                                Log.e("DharmaDownload", "ERROR: Failed to create MediaStore entry")
                                result.error("SAVE_ERROR", "Failed to create file in Downloads", null)
                            }
                        } else {
                            // Android 9 and below - Legacy approach
                            Log.d("DharmaDownload", "Using legacy storage (Android 9 and below)")
                            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                            
                            if (!downloadsDir.exists()) {
                                Log.d("DharmaDownload", "Downloads directory doesn't exist, creating it")
                                downloadsDir.mkdirs()
                            }
                            
                            Log.d("DharmaDownload", "Downloads path: ${downloadsDir.absolutePath}")
                            val file = File(downloadsDir, fileName)
                            
                            FileOutputStream(file).use { outputStream ->
                                outputStream.write(bytes)
                                Log.d("DharmaDownload", "Successfully wrote ${bytes.size} bytes to ${file.absolutePath}")
                            }
                            
                            // Trigger media scanner to make file visible
                            Log.d("DharmaDownload", "Triggering media scanner for file visibility")
                            val mediaScanIntent = android.content.Intent(android.content.Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                            mediaScanIntent.data = android.net.Uri.fromFile(file)
                            sendBroadcast(mediaScanIntent)
                            Log.d("DharmaDownload", "Media scan broadcast sent")
                            
                            Log.d("DharmaDownload", "=== Download complete: ${file.absolutePath} ===")
                            result.success(file.absolutePath)
                        }
                    } catch (e: Exception) {
                        Log.e("DharmaDownload", "ERROR: Exception during download", e)
                        result.error("SAVE_ERROR", "Failed to save file: ${e.message}", e.stackTraceToString())
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
