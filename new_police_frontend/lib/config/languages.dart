/// All Indian languages supported by Dharma CMS.
class AppLanguages {
  AppLanguages._();

  static const List<Map<String, String>> all = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
    {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
    {'code': 'ml', 'name': 'Malayalam', 'native': 'മലയാളം'},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
    {'code': 'gu', 'name': 'Gujarati', 'native': 'ગુજરાતી'},
    {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা'},
    {'code': 'pa', 'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ'},
    {'code': 'ur', 'name': 'Urdu', 'native': 'اردو'},
    {'code': 'or', 'name': 'Odia', 'native': 'ଓଡ଼ିଆ'},
    {'code': 'as', 'name': 'Assamese', 'native': 'অসমীয়া'},
  ];

  static const List<Map<String, String>> supported = all;

  static String displayName(String code) {
    final lang = all.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'name': code, 'native': code},
    );
    if (lang['name'] == lang['native']) return lang['name']!;
    return '${lang['name']} (${lang['native']})';
  }
}
