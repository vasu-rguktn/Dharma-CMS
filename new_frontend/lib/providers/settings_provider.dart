import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart' as prefs;

class SettingsProvider with ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _chatLanguageKey = 'selected_chat_language';
  prefs.SharedPreferences? _prefs;
  Locale? _locale;
  String? _chatLanguageCode;

  Locale? get locale => _locale;
  String? get chatLanguageCode => _chatLanguageCode;

  SettingsProvider() { init(); }

  Future<void> init() async {
    _prefs = await prefs.SharedPreferences.getInstance();
    final code = _prefs?.getString(_languageKey);
    if (code != null) _locale = Locale(code);
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
    await _prefs?.setString(_languageKey, languageCode);
    _locale = Locale(languageCode);
    notifyListeners();
  }
}
