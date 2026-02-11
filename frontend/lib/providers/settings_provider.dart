import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart' as prefs;

class SettingsProvider with ChangeNotifier {
  static const String _languageKey = 'selected_language';
  prefs.SharedPreferences? _prefs;
  Locale? _locale;

  SettingsProvider() {
    init();
  }

  static const String _chatLanguageKey = 'selected_chat_language';
  String? _chatLanguageCode;

  Locale? get locale => _locale;
  String? get chatLanguageCode => _chatLanguageCode;

  Future<void> init() async {
    _prefs = await prefs.SharedPreferences.getInstance();
    final String? languageCode = _prefs?.getString(_languageKey);
    if (languageCode != null) {
      _locale = Locale(languageCode);
    }
    _chatLanguageCode = _prefs?.getString(_chatLanguageKey);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    await _prefs?.setString(_languageKey, languageCode);
    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setChatLanguage(String languageCode) async {
    await _prefs?.setString(_chatLanguageKey, languageCode);
    _chatLanguageCode = languageCode;
    notifyListeners();
  }
}
