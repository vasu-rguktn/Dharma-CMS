#!/usr/bin/env python3
import re

with open('frontend/lib/screens/case_detail_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Replace all remaining 'localizations.' with 'AppLocalizations.of(context)!.'
new_lines = []
for line in lines:
    # Skip the import line
    if "import 'package:Dharma/l10n/app_localizations.dart'" in line:
        new_lines.append(line)
        continue
    
    # Replace localizations. references (but not Localizations. which is from Flutter)
    if 'localizations.' in line and 'Localizations.' not in line:
        # Don't replace if it's in a comment or already uses AppLocalizations.of
        if 'AppLocalizations.of(context)' not in line:
            line = line.replace('localizations.', 'AppLocalizations.of(context)!.')
            # Remove const if it's before Text or SnackBar now
            line = line.replace('const Text(AppLocalizations', 'Text(AppLocalizations')
            line = line.replace('const SnackBar', 'SnackBar')
    
    new_lines.append(line)

# Write back
with open('frontend/lib/screens/case_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("✅ Fixed all remaining localization references")
