import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/settings_provider.dart';
import 'package:Dharma/l10n/app_localizations.dart';

class LanguageSelectionDialog extends StatelessWidget {
  const LanguageSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.language, // Localized
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            _LanguageOption(
              name: 'English',
              languageCode: 'en',
              isSelected: settingsProvider.locale?.languageCode == 'en',
              onSelect: () => _selectLanguage(context, 'en'),
            ),
            const SizedBox(height: 12),
            _LanguageOption(
              name: 'తెలుగు',
              languageCode: 'te',
              isSelected: settingsProvider.locale?.languageCode == 'te',
              onSelect: () => _selectLanguage(context, 'te'),
            ),
          ],
        ),
      ),
    );
  }

  void _selectLanguage(BuildContext context, String languageCode) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.setLanguage(languageCode);
    Navigator.of(context).pop();
  }
}

class _LanguageOption extends StatelessWidget {
  final String name;
  final String languageCode;
  final bool isSelected;
  final VoidCallback onSelect;

  const _LanguageOption({
    required this.name,
    required this.languageCode,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: 2,
          ),
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected ? Theme.of(context).primaryColor : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(Icons.check, color: Theme.of(context).primaryColor),
            ],
          ],
        ),
      ),
    );
  }
}