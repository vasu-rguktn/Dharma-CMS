import json

# Read the English localization file
with open(r'c:\Users\HP\Desktop\SP_Elluru\Dharma-CMS\frontend\lib\l10n\app_en.arb', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Add the new localization string
data['noPetitionsFound'] = 'No Petitions Found'
data['@noPetitionsFound'] = {
    'description': 'Message shown when no petitions are found for the selected filter'
}

# Write back to the file
with open(r'c:\Users\HP\Desktop\SP_Elluru\Dharma-CMS\frontend\lib\l10n\app_en.arb', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Added noPetitionsFound to app_en.arb")
