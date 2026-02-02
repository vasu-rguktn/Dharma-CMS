import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:Dharma/router/app_router.dart';

// ============================================
// FCM Backend API URL Configuration
// ============================================
// CHANGE THIS to your deployed backend URL if testing on physical device
// Examples:
//   - Local testing (emulator): 'http://localhost:8000'
//   - Local testing (physical device): 'http://192.168.1.5:8000' (your PC's IP)
//   - Production: 'https://your-backend.onrender.com' or your deployed URL
const String FCM_API_URL = 'http://10.5.47.114:8000';
// ============================================
// 'http://10.5.47.114:8000'
/// FCM Notification Service for Citizen Users
/// 
/// This service handles Firebase Cloud Messaging integration for citizen users only.
/// Police users are NOT registered for notifications.
/// 
/// Features:
/// - Request notification permissions
/// - Get and register FCM tokens with backend
/// - Handle foreground, background, and terminated state notifications
/// - Deep-link to petition/case detail screens
/// - Multi-device support
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _currentUserId;

  /// Initialize FCM for citizen users
  /// Call this after citizen login, NOT for police users
  Future<void> initialize(String userId, {bool isCitizen = true}) async {
    if (_initialized) {
      debugPrint('[NotificationService] Already initialized');
      return;
    }

    // IMPORTANT: Only initialize for citizen users
    if (!isCitizen) {
      debugPrint('[NotificationService] Skipping FCM for police user');
      return;
    }

    try {
      _currentUserId = userId;

      // Request permissions
      final permissionGranted = await requestPermissions();
      if (!permissionGranted) {
        debugPrint('[NotificationService] Permission denied, skipping FCM setup');
        return;
      }

      // Initialize local notifications (for foreground messages)
      await _initializeLocalNotifications();

      // Get and register token
      await _registerToken(userId);

      // Setup message handlers
      _setupMessageHandlers();

      // Handle token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('[NotificationService] Token refreshed');
        _registerTokenWithBackend(userId, newToken, _getPlatform());
      });

      _initialized = true;
      debugPrint('[NotificationService] ✅ Successfully initialized for citizen user');
    } catch (e) {
      debugPrint('[NotificationService] ❌ Initialization failed: $e');
      // Don't throw - app should work even if FCM fails
    }
  }

  /// Request notification permissions (iOS/Android 13+)
  Future<bool> requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized;
      debugPrint('[NotificationService] Permission status: ${settings.authorizationStatus}');
      return granted;
    } catch (e) {
      debugPrint('[NotificationService] Permission request failed: $e');
      return false;
    }
  }

  /// Initialize flutter_local_notifications for foreground messages
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    if (!kIsWeb) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel', // Must match backend and AndroidManifest
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Get FCM token and register with backend
  Future<void> _registerToken(String userId) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null) {
        debugPrint('[NotificationService] Failed to get FCM token');
        return;
      }

      debugPrint('[NotificationService] FCM Token: ${token.substring(0, 20)}...');
      
      final success = await _registerTokenWithBackend(userId, token, _getPlatform());
      if (success) {
        debugPrint('[NotificationService] ✅ Token registered with backend');
      } else {
        debugPrint('[NotificationService] ❌ Failed to register token with backend');
      }
    } catch (e) {
      debugPrint('[NotificationService] Token registration failed: $e');
    }
  }

  /// Register FCM token with backend API
  Future<bool> _registerTokenWithBackend(
    String userId,
    String token,
    String platform,
  ) async {
    try {
      final dio = Dio();

      final response = await dio.post(
        '$FCM_API_URL/api/fcm/register',
        data: {
          'userId': userId,
          'token': token,
          'platform': platform,
        },
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('[NotificationService] Backend registration error: $e');
      return false;
    }
  }

  /// Setup message handlers for different app states
  void _setupMessageHandlers() {
    // Foreground messages (app is open and active)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background messages (app is in background, user taps notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // Check if app was opened from terminated state via notification
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('[NotificationService] App opened from notification (terminated)');
        _handleNotificationClick(message);
      }
    });
  }

  /// Handle foreground message - show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[NotificationService] Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Show local notification
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: _encodePayload(message.data),
    );
  }

  /// Handle notification click - navigate to appropriate screen
  void _handleNotificationClick(RemoteMessage message) {
    debugPrint('[NotificationService] Notification clicked: ${message.data}');
    _navigateFromPayload(message.data);
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;
    
    final data = _decodePayload(response.payload!);
    _navigateFromPayload(data);
  }

  /// Navigate to petition or case based on notification data
  void _navigateFromPayload(Map<String, dynamic> data) {
    try {
      final type = data['type'];
      
      if (type == 'petition_update' || type == 'case_update') {
        final petitionId = data['petitionId'];
        if (petitionId != null) {
          debugPrint('[NotificationService] Navigating to petition details: $petitionId');
          
          // Navigate to petitions screen with petitionId query param
          // The petitions screen will auto-open this petition's details
          AppRouter.router.go('/petitions?petitionId=$petitionId');
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Navigation failed: $e');
    }
  }

  /// Get current platform
  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'unknown';
  }

  /// Encode payload for local notifications
  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// Decode payload from local notifications
  Map<String, dynamic> _decodePayload(String payload) {
    final map = <String, dynamic>{};
    for (final pair in payload.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }
    return map;
  }

  /// Unregister token when user logs out
  Future<void> unregister() async {
    if (_currentUserId == null) return;

    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null) return;

      final dio = Dio();

      await dio.delete(
        '$FCM_API_URL/api/fcm/unregister',
        data: {
          'userId': _currentUserId,
          'token': token,
          'platform': _getPlatform(),
        },
      );

      debugPrint('[NotificationService] Token unregistered');
    } catch (e) {
      debugPrint('[NotificationService] Unregister failed: $e');
    }

    _initialized = false;
    _currentUserId = null;
  }
}

/// Top-level background message handler
/// Required by Firebase Messaging - must be outside of any class
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[NotificationService] Background message: ${message.notification?.title}');
  // Don't do heavy work here - just log
}
