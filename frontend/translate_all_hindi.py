import re
from googletrans import Translator

translator = Translator()

# Read English file
with open('lib/l10n/app_localizations_en.dart', 'r', encoding='utf-8') as f:
    en_content = f.read()

# Extract all string values using regex
pattern = r"=> '([^']+)';"
matches = re.findall(pattern, en_content)

print(f"Found {len(matches)} strings to translate")
print("Translating to Hindi...")

# Translate in batches
translations = {}
batch_size = 50
for i in range(0, len(matches), batch_size):
    batch = matches[i:i+batch_size]
    print(f"Translating batch {i//batch_size + 1}/{(len(matches)//batch_size)+1}...")
    
    for text in batch:
        if text not in translations and len(text.strip()) > 0:
            try:
                result = translator.translate(text, src='en', dest='hi')
                translations[text] = result.text
                print(f"  '{text[:50]}...' => '{result.text[:50]}...'")
            except Exception as e:
                print(f"  Error translating '{text[:30]}': {e}")
                translations[text] = text  # Keep original if translation fails

# Create Hindi file by replacing English strings
hi_content = en_content

# Replace class name
hi_content = hi_content.replace('class AppLocalizationsEn extends AppLocalizations {', 
                               'class AppLocalizationsHi extends AppLocalizations {')
hi_content = hi_content.replace("AppLocalizationsEn([String locale = 'en'])", 
                               "AppLocalizationsHi([String locale = 'hi'])")
hi_content = hi_content.replace("/// The translations for English (`en`).", 
                               "/// The translations for Hindi (`hi`).")

# Replace all translated strings
for english, hindi in translations.items():
    hi_content = hi_content.replace(f"=> '{english}';", f"=> '{hindi}';")

# Write Hindi file
with open('lib/l10n/app_localizations_hi.dart', 'w', encoding='utf-8') as f:
    f.write(hi_content)

print(f"\nCompleted! Translated {len(translations)} strings to Hindi")
print("File saved: lib/l10n/app_localizations_hi.dart")
