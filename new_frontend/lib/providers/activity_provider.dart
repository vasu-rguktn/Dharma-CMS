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

  UserActivity({required this.title, required this.iconCode, this.iconFontFamily, this.iconFontPackage, required this.route, required this.timestamp, this.color});

  IconData get icon {
    if (iconCode == Icons.chat.codePoint) return Icons.chat;
    if (iconCode == Icons.psychology.codePoint) return Icons.psychology;
    if (iconCode == Icons.phone.codePoint) return Icons.phone;
    if (iconCode == Icons.gavel.codePoint) return Icons.gavel;
    if (iconCode == Icons.archive.codePoint) return Icons.archive;
    if (iconCode == Icons.book.codePoint) return Icons.book;
    if (iconCode == Icons.post_add.codePoint) return Icons.post_add;
    return Icons.help_outline;
  }

  Map<String, dynamic> toJson() => {
    'title': title, 'iconCode': iconCode, 'iconFontFamily': iconFontFamily,
    'iconFontPackage': iconFontPackage, 'route': route,
    'timestamp': timestamp.toIso8601String(), 'colorValue': color?.value,
  };

  factory UserActivity.fromJson(Map<String, dynamic> json) => UserActivity(
    title: json['title'], iconCode: json['iconCode'],
    iconFontFamily: json['iconFontFamily'], iconFontPackage: json['iconFontPackage'],
    route: json['route'], timestamp: DateTime.parse(json['timestamp']),
    color: json['colorValue'] != null ? Color(json['colorValue']) : null,
  );
}

class ActivityProvider with ChangeNotifier {
  static const String _storageKey = 'recent_activities';
  final List<UserActivity> _activities = [];
  bool _isLoading = true;
  bool _isInitialized = false;

  ActivityProvider() { _loadFromPrefs(); }

  List<UserActivity> get activities => List.unmodifiable(_activities);
  bool get isLoading => _isLoading;

  Future<void> _loadFromPrefs() async {
    if (_isInitialized) return;
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null && json.isNotEmpty) {
        final decoded = jsonDecode(json) as List;
        _activities.clear();
        _activities.addAll(decoded.map((e) => UserActivity.fromJson(e)));
      } else {
        _prePopulate();
      }
    } catch (_) {
      _prePopulate();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _prePopulate() {
    _activities.clear();
    _activities.addAll([
      UserActivity(title: 'AI Chat', iconCode: Icons.chat.codePoint, iconFontFamily: Icons.chat.fontFamily, route: '/ai-legal-chat', timestamp: DateTime.now().subtract(const Duration(minutes: 5)), color: Colors.blue),
      UserActivity(title: 'Helpline', iconCode: Icons.phone.codePoint, iconFontFamily: Icons.phone.fontFamily, route: '/helpline', timestamp: DateTime.now().subtract(const Duration(minutes: 15)), color: Colors.red.shade800),
    ]);
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_activities.map((e) => e.toJson()).toList()));
  }

  Future<void> logActivity({required String title, required IconData icon, required String route, Color? color}) async {
    if (!_isInitialized) await _loadFromPrefs();
    final idx = _activities.indexWhere((e) => e.route == route);
    if (idx != -1) { _activities.removeAt(idx); } else if (_activities.length >= 10) { _activities.removeLast(); }
    _activities.insert(0, UserActivity(title: title, iconCode: icon.codePoint, iconFontFamily: icon.fontFamily, iconFontPackage: icon.fontPackage, route: route, timestamp: DateTime.now(), color: color));
    notifyListeners();
    _saveToPrefs();
  }
}
