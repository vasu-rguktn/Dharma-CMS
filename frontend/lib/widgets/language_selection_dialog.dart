import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/settings_provider.dart';
import 'package:Dharma/l10n/app_localizations.dart';

class LanguageSelectionDialog extends StatelessWidget {
  const LanguageSelectionDialog({super.key});

  final List<Map<String, String>> languages = const [
    {'code': 'en', 'name': 'English'},
    {'code': 'te', 'name': 'తెలుగు'}, // Telugu
    {'code': 'hi', 'name': 'हिंदी'}, // Hindi
    {'code': 'mr', 'name': 'मराठी'}, // Marathi
    {'code': 'ta', 'name': 'தமிழ்'}, // Tamil
    {'code': 'kn', 'name': 'ಕನ್ನಡ'}, // Kannada
    {'code': 'ml', 'name': 'മലയാളം'}, // Malayalam
    {'code': 'gu', 'name': 'ગુજરાતી'}, // Gujarati
    {'code': 'bn', 'name': 'বাংলা'}, // Bengali
    {'code': 'pa', 'name': 'ਪੰਜਾਬੀ'}, // Punjabi
    {'code': 'ur', 'name': 'اردو'}, // Urdu
    {'code': 'or', 'name': 'ଓଡ଼ିଆ'}, // Odia
    {'code': 'as', 'name': 'অসমীয়া'}, // Assamese
  ];

  @override
  Widget build(BuildContext context) {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.7, // Increased height
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 14),

              // Drag handle
              Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[350],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 18),

              // Title
              Text(
                localizations.language,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 24),

              // Language buttons list
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  itemCount: languages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final language = languages[index];
                    return _LanguageButton(
                      name: language['name']!,
                      languageCode: language['code']!,
                      isSelected: settingsProvider.locale?.languageCode ==
                          language['code'],
                      onTap: () => _selectLanguage(context, language['code']!),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _selectLanguage(BuildContext context, String languageCode) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.setLanguage(languageCode);
    Navigator.of(context).pop();
  }
}

// --------------------------------------------------------
// Language button widget
// --------------------------------------------------------

class _LanguageButton extends StatelessWidget {
  final String name;
  final String languageCode;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.name,
    required this.languageCode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color(0xFFFC633C).withOpacity(0.15)
              : Colors.transparent,
          foregroundColor:
              isSelected ? const Color(0xFFFC633C) : Colors.black87,
          elevation: 0,
          side: BorderSide(
            color: isSelected ? const Color(0xFFFC633C) : Colors.grey[300]!,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              const Icon(Icons.check, size: 26, color: Color(0xFFFC633C)),
            ],
          ],
        ),
      ),
    );
  }
}
