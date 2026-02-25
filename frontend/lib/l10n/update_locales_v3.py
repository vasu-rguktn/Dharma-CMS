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
        'statusClosed': 'बंद',
        'statusSubmitted': 'जमा किया गया',
        'statusAcknowledged': 'स्वीकार किया गया',
        'statusInvestigation': 'जांच'
    },
    'kn': {
        'statusPending': 'ಬಾಕಿ ಇದೆ',
        'statusReceived': 'ಸ್ವೀಕರಿಸಲಾಗಿದೆ',
        'statusInProgress': 'ಪ್ರಗತಿಯಲ್ಲಿದೆ',
        'statusClosed': 'ಮುಕ್ತಾಯವಾಗಿದೆ',
        'statusSubmitted': 'ಸಲ್ಲಿಸಲಾಗಿದೆ',
        'statusAcknowledged': 'ಅಂಗೀಕರಿಸಲಾಗಿದೆ',
        'statusInvestigation': 'ತನಿಖೆ'
    },
    'ta': {
        'statusPending': 'நிலுவையில் உள்ளது',
        'statusReceived': 'பெறப்பட்டது',
        'statusInProgress': 'செயலில் உள்ளது',
        'statusClosed': 'முடிந்துவிட்டது',
        'statusSubmitted': 'சமர்ப்பிக்கப்பட்டது',
        'statusAcknowledged': 'ஏற்கப்பட்டது',
        'statusInvestigation': 'விசாரணை'
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

  @override
  String get statusSubmitted => '{t.get('statusSubmitted', 'Submitted')}';

  @override
  String get statusAcknowledged => '{t.get('statusAcknowledged', 'Acknowledged')}';

  @override
  String get statusInvestigation => '{t.get('statusInvestigation', 'Investigation')}';
"""

for filename in files:
    path = os.path.join('e:/Dharma-CMS/frontend/lib/l10n', filename)
    if not os.path.exists(path):
        print(f"Skipping {path} (not found)")
        continue
        
    lang = filename.split('_')[-1].split('.')[0]
    
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check if any new fields are missing
    if "String get statusSubmitted" in content:
         # If already has some, but maybe not all (due to previous run)
         # We'll just replace the block if needed or skip if it's already there
         print(f"Skipping {path} (already has statusSubmitted)")
         continue

    # Insert after statusWithdrawn
    search_str = "String get statusWithdrawn => '"
    if search_str in content:
        # If it already had the 4 statuses from previous run, remove them first to avoid duplicates
        if "String get statusPending" in content:
             # Find the block start and end
             start_idx = content.find("  @override\n  String get statusPending")
             end_idx = content.find("  @override", content.find("String get statusClosed"))
             if end_idx == -1: # It might be the last one before petitionNumber
                 end_idx = content.find("  @override\n  String get petitionNumber")
             
             if start_idx != -1 and end_idx != -1:
                 content = content[:start_idx] + content[end_idx:]

        # Now insert the full block
        parts = content.split(search_str)
        val_end = parts[1].find("';") + 2
        insertion_point = content.find(search_str) + len(search_str) + val_end
        new_content = content[:insertion_point] + get_insertion(lang) + content[insertion_point:]
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {path}")
    else:
        print(f"Could not find insertion point in {path}")
