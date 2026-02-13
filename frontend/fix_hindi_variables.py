import re

# Read the Hindi file
with open('lib/l10n/app_localizations_hi.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix translated variable names - map Hindi variable names back to English
variable_fixes = {
    '$गायब': '$missing',
    '$वर्गीकरण': '$classification',
    '$त्रुटि': '$error',
    '$दिनांक': '$date',
    '$तारीख': '$date',
    '$गिनती': '$count',
    '$नाम': '$name',
    '$फ़ाइल': '$file',
    '$फ़ाइलनाम': '$fileName',
}

# Apply fixes
for hindi_var, english_var in variable_fixes.items():
    content = content.replace(hindi_var, english_var)

# Write back
with open('lib/l10n/app_localizations_hi.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print(f"Fixed {len(variable_fixes)} variable placeholder errors")
print("Variable fixes applied:")
for hindi, english in variable_fixes.items():
    print(f"  {hindi} -> {english}")
