/// All Indian languages supported by Dharma CMS.
/// Used on the welcome screen dropdown, settings screen, and chat language selector.
class AppLanguages {
  AppLanguages._();

  /// Full list — code + English name + native script name.
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
    {'code': 'sa', 'name': 'Sanskrit', 'native': 'संस्कृतम्'},
    {'code': 'ne', 'name': 'Nepali', 'native': 'नेपाली'},
    {'code': 'sd', 'name': 'Sindhi', 'native': 'سنڌي'},
    {'code': 'ks', 'name': 'Kashmiri', 'native': 'कॉशुर'},
    {'code': 'doi', 'name': 'Dogri', 'native': 'डोगरी'},
    {'code': 'kok', 'name': 'Konkani', 'native': 'कोंकणी'},
    {'code': 'mai', 'name': 'Maithili', 'native': 'मैथिली'},
    {'code': 'mni', 'name': 'Manipuri', 'native': 'মৈতৈলোন্'},
    {'code': 'sat', 'name': 'Santali', 'native': 'ᱥᱟᱱᱛᱟᱲᱤ'},
    {'code': 'bo', 'name': 'Bodo', 'native': 'बड़ो'},
  ];

  /// Only the languages that have l10n .arb/.dart translations in the app.
  static const List<Map<String, String>> supported = [
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

  /// Display label for a language code, e.g. "Telugu (తెలుగు)"
  static String displayName(String code) {
    final lang = all.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'name': code, 'native': code},
    );
    if (lang['name'] == lang['native']) return lang['name']!;
    return '${lang['name']} (${lang['native']})';
  }
}
