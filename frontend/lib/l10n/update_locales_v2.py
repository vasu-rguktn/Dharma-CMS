import os

files = [
    'app_localizations_as.dart',
    'app_localizations_bn.dart',
    'app_localizations_gu.dart',
    'app_localizations_hi.dart',
    'app_localizations_kn.dart',
    'app_localizations_ml.dart',
    'app_localizations_mr.dart',
    'app_localizations_or.dart',
    'app_localizations_pa.dart',
    'app_localizations_ta.dart',
    'app_localizations_ur.dart'
]

# Language specific translations
translations = {
    'hi': {
        'statusPending': 'लंबित',
        'statusReceived': 'प्राप्त',
        'statusInProgress': 'प्रगति पर है',
        'statusClosed': 'बंद'
    },
    'kn': {
        'statusPending': 'ಬಾಕಿ ಇದೆ',
        'statusReceived': 'ಸ್ವೀಕರಿಸಲಾಗಿದೆ',
        'statusInProgress': 'ಪ್ರಗತಿಯಲ್ಲಿದೆ',
        'statusClosed': 'ಮುಕ್ತಾಯವಾಗಿದೆ'
    },
    'ta': {
        'statusPending': 'நிலுவையில் உள்ளது',
        'statusReceived': 'பெறப்பட்டது',
        'statusInProgress': 'செயலில் உள்ளது',
        'statusClosed': 'முடிந்துவிட்டது'
    }
}

def get_insertion(lang):
    t = translations.get(lang, {})
    return f"""
  @override
  String get statusPending => '{t.get('statusPending', 'Pending')}';

  @override
  String get statusReceived => '{t.get('statusReceived', 'Received')}';

  @override
  String get statusInProgress => '{t.get('statusInProgress', 'In Progress')}';

  @override
  String get statusClosed => '{t.get('statusClosed', 'Closed')}';
"""

for filename in files:
    path = os.path.join('e:/Dharma-CMS/frontend/lib/l10n', filename)
    if not os.path.exists(path):
        print(f"Skipping {path} (not found)")
        continue
        
    lang = filename.split('_')[-1].split('.')[0]
    
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if "String get statusPending" in content:
        print(f"Skipping {path} (already updated)")
        continue

    # Insert after statusWithdrawn
    search_str = "String get statusWithdrawn => '"
    if search_str in content:
        parts = content.split(search_str)
        val_end = parts[1].find("';") + 2
        insertion_point = content.find(search_str) + len(search_str) + val_end
        new_content = content[:insertion_point] + get_insertion(lang) + content[insertion_point:]
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {path}")
    else:
        print(f"Could not find insertion point in {path}")
