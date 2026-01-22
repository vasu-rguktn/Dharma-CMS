import 'package:flutter/material.dart';

class UserActivity {
  final String title;
  final IconData icon;
  final String route;
  final DateTime timestamp;
  final Color? color;

  UserActivity({
    required this.title,
    required this.icon,
    required this.route,
    required this.timestamp,
    this.color,
  });
}

class ActivityProvider with ChangeNotifier {
  // Pre-populate with user's requested top activities so it's not empty initially
  final List<UserActivity> _activities = [
    UserActivity(
      title: "AI Chat",
      icon: Icons.chat,
      route: "/ai-legal-chat",
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      color: Colors.blue,
    ),
    UserActivity(
      title: "Helpline",
      icon: Icons.phone,
      route: "/helpline",
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      color: Colors.red.shade800,
    ),
    UserActivity(
      title: "Legal Suggestion",
      icon: Icons.gavel,
      route: "/legal-suggestion",
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      color: Colors.red.shade700,
    ),
  ];

  List<UserActivity> get activities => List.unmodifiable(_activities);

  void logActivity({
    required String title,
    required IconData icon,
    required String route,
    Color? color,
  }) {
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
      icon: icon,
      route: route,
      timestamp: DateTime.now(),
      color: color,
    ));
    
    notifyListeners();
  }

  void clearActivities() {
    _activities.clear();
    notifyListeners();
  }
}
