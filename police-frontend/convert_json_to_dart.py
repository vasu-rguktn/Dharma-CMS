import json
import os

JSON_PATH = r'assets/Data/ap_police_hierarchy_fir.json'
OUTPUT_DART_PATH = r'lib/data/police_hierarchy_data.dart'

def main():
    print("Reading JSON file...")
    try:
        with open(JSON_PATH, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        # The JSON structure is {"districts": [...]}
        # We want the Dart variable to be directly the list of districts/ranges?
        # The Data has "districts" at root.
        # But wait, does it have Ranges? 
        # Looking at snippet: {"districts": [{"name": "Alluri...", "sdpos": ...}]}
        # It seems it starts at District level.
        # The user's Excel had "Range".
        # If FIR json lacks Range, we might need to wrap it or just stick to District root.
        # The current app uses Ranges.
        # Let's check api_police_hierarchy_complete.json again? 
        # No, let's look at fir json again. It has no "range" key in the snippet I saw.
        
        # We will wrap it in a structure or just export the list of districts.
        # But the AssignPetitionDialog needs Ranges?
        # If the JSON data lacks ranges, I'll group them if I can? No mapping available.
        # I'll output the data as is, and the UI will have to handle "No Range" or I'll add a dummy "Andhra Pradesh" range?
        
        # Let's inspect the keys of the json root.
        print(f"Keys: {data.keys()}")
        
        hierarchy = data.get('districts', [])
        
        # Dart code
        dart_code = f"""
// Auto-generated from {JSON_PATH}
// Used as fallback for Excel: Revised AP Police Organisation 31-01-26.xlsx

const Map<String, dynamic> kPoliceHierarchyData = {json.dumps(data, indent=2)};
""" 
        
        os.makedirs(os.path.dirname(OUTPUT_DART_PATH), exist_ok=True)
        with open(OUTPUT_DART_PATH, 'w', encoding='utf-8') as f:
            f.write(dart_code)
            
        print(f"Successfully generated {OUTPUT_DART_PATH}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
