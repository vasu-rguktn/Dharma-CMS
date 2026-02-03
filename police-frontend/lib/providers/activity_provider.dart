import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserActivity {
  final String title;
  final int iconCode;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final String route;
  final DateTime timestamp;
  final Color? color;

  UserActivity({
    required this.title,
    required this.iconCode,
    this.iconFontFamily,
    this.iconFontPackage,
    required this.route,
    required this.timestamp,
    this.color,
  });

  IconData get icon {
    // We must return constant IconData instances to satisfy Flutter's icon tree-shaking.
    // Dynamic IconData(iconCode, ...) calls with variables are not allowed in release builds.
    if (iconCode == Icons.chat.codePoint) return Icons.chat;
    if (iconCode == Icons.psychology.codePoint) return Icons.psychology;
    if (iconCode == Icons.phone.codePoint) return Icons.phone;
    if (iconCode == Icons.gavel.codePoint) return Icons.gavel;
    if (iconCode == Icons.call_received.codePoint) return Icons.call_received;
    if (iconCode == Icons.sync.codePoint) return Icons.sync;
    if (iconCode == Icons.task_alt.codePoint) return Icons.task_alt;
    if (iconCode == Icons.report_problem.codePoint) return Icons.report_problem;
    if (iconCode == Icons.edit_document.codePoint) return Icons.edit_document;
    if (iconCode == Icons.file_present.codePoint) return Icons.file_present;
    if (iconCode == Icons.fact_check.codePoint) return Icons.fact_check;
    if (iconCode == Icons.archive.codePoint) return Icons.archive;
    if (iconCode == Icons.book.codePoint) return Icons.book;
    if (iconCode == Icons.rule.codePoint) return Icons.rule;
    if (iconCode == Icons.file_copy_rounded.codePoint) return Icons.file_copy_rounded;
    if (iconCode == Icons.camera_alt.codePoint) return Icons.camera_alt;
    if (iconCode == Icons.person_add.codePoint) return Icons.person_add;
    if (iconCode == Icons.post_add.codePoint) return Icons.post_add;
    if (iconCode == Icons.assignment.codePoint) return Icons.assignment;
    if (iconCode == Icons.image_search.codePoint) return Icons.image_search;
    if (iconCode == Icons.history.codePoint) return Icons.history;
    if (iconCode == Icons.arrow_forward_ios.codePoint) return Icons.arrow_forward_ios;
    
    // Fallback to a safe constant
    return Icons.help_outline;
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'iconCode': iconCode,
      'iconFontFamily': iconFontFamily,
      'iconFontPackage': iconFontPackage,
      'route': route,
      'timestamp': timestamp.toIso8601String(),
      'colorValue': color?.value,
    };
  }

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      title: json['title'],
      iconCode: json['iconCode'],
      iconFontFamily: json['iconFontFamily'],
      iconFontPackage: json['iconFontPackage'],
      route: json['route'],
      timestamp: DateTime.parse(json['timestamp']),
      color: json['colorValue'] != null ? Color(json['colorValue']) : null,
    );
  }
}

class ActivityProvider with ChangeNotifier {
  static const String _storageKey = 'recent_activities';
  final List<UserActivity> _activities = [];
  bool _isLoading = true;
  bool _isInitialized = false;

  ActivityProvider() {
    _loadFromPrefs();
  }

  List<UserActivity> get activities => List.unmodifiable(_activities);
  bool get isLoading => _isLoading;

  Future<void> _loadFromPrefs() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? activitiesJson = prefs.getString(_storageKey);
      
      if (activitiesJson != null && activitiesJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(activitiesJson);
        final loadedActivities = decoded
            .map((item) => UserActivity.fromJson(item))
            .toList();
        
        // Use the loaded activities
        _activities.clear();
        _activities.addAll(loadedActivities);
      } else {
        // Only pre-populate if there's absolutely nothing stored
        _prePopulateDefaultActivities(save: false);
      }
    } catch (e) {
      debugPrint('Error loading activities: $e');
      _prePopulateDefaultActivities(save: false);
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _prePopulateDefaultActivities({bool save = true}) {
    _activities.clear();
    _activities.addAll([
      UserActivity(
        title: "AI Chat",
        iconCode: Icons.chat.codePoint,
        iconFontFamily: Icons.chat.fontFamily,
        iconFontPackage: Icons.chat.fontPackage,
        route: "/ai-legal-chat",
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        color: Colors.blue,
      ),
      UserActivity(
        title: "Legal Queries",
        iconCode: Icons.psychology.codePoint,
        iconFontFamily: Icons.psychology.fontFamily,
        iconFontPackage: Icons.psychology.fontPackage,
        route: "/legal-queries",
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        color: Colors.purple,
      ),
      UserActivity(
        title: "Helpline",
        iconCode: Icons.phone.codePoint,
        iconFontFamily: Icons.phone.fontFamily,
        iconFontPackage: Icons.phone.fontPackage,
        route: "/helpline",
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        color: Colors.red.shade800,
      ),
    ]);
    
    if (save) {
      _saveToPrefs();
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_activities.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving activities: $e');
    }
  }

  Future<void> logActivity({
    required String title,
    required IconData icon,
    required String route,
    Color? color,
  }) async {
    // Ensure we are initialized before logging
    if (!_isInitialized) {
      await _loadFromPrefs();
    }

    // Check if the activity already exists anywhere in the list
    final existingIndex = _activities.indexWhere((element) => element.route == route);
    
    if (existingIndex != -1) {
      // Remove it from its current position
      _activities.removeAt(existingIndex);
    } else {
      // If it's a new activity and we have 10, remove the oldest
      if (_activities.length >= 10) {
        _activities.removeLast();
      }
    }

    // Insert at the top as the most recent
    _activities.insert(0, UserActivity(
      title: title,
      iconCode: icon.codePoint,
      iconFontFamily: icon.fontFamily,
      iconFontPackage: icon.fontPackage,
      route: route,
      timestamp: DateTime.now(),
      color: color,
    ));
    
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> clearActivities() async {
    _activities.clear();
    await _saveToPrefs();
    notifyListeners();
  }
}
