import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var originalAudioSessionCategory: AVAudioSession.Category?
  private var originalAudioSessionOptions: AVAudioSession.CategoryOptions = []
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let soundChannel = FlutterMethodChannel(
      name: "com.dharma.sound_control",
      binaryMessenger: controller.binaryMessenger
    )
    
    soundChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else {
        result(FlutterError(code: "ERROR", message: "AppDelegate is nil", details: nil))
        return
      }
      
      switch call.method {
      case "muteSystemSounds":
        do {
          let audioSession = AVAudioSession.sharedInstance()
          // Save original category and options
          self.originalAudioSessionCategory = audioSession.category
          self.originalAudioSessionOptions = audioSession.categoryOptions
          
          // Set category to playAndRecord with option to mix with others (but suppress system sounds)
          try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
          try audioSession.setActive(true)
          result(true)
        } catch {
          result(FlutterError(code: "MUTE_ERROR", message: "Failed to mute system sounds: \(error.localizedDescription)", details: nil))
        }
        
      case "unmuteSystemSounds":
        do {
          let audioSession = AVAudioSession.sharedInstance()
          // Restore original category and options if available
          if let originalCategory = self.originalAudioSessionCategory {
            try audioSession.setCategory(originalCategory, mode: .default, options: self.originalAudioSessionOptions)
          }
          try audioSession.setActive(true)
          result(true)
        } catch {
          result(FlutterError(code: "UNMUTE_ERROR", message: "Failed to unmute system sounds: \(error.localizedDescription)", details: nil))
        }
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
