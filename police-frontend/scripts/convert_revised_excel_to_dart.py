import pandas as pd
import re
import json

# List of known districts to identify District rows
DISTRICTS = [
    "Srikakulam", "Vizianagaram", "Parvathipuram Manyam", "Alluri Sitharama Raju", 
    "Visakhapatnam", "Anakapalli", "Kakinada", "Dr. B.R. Ambedkar Konaseema", 
    "East Godavari", "West Godavari", "Eluru", "Krishna", "NTR", "Guntur", 
    "Palnadu", "Bapatla", "Prakasam", "Nellore", "Tirupati", "Chittoor", 
    "Annamayya", "YSR Kadapa", "Nandyal", "Kurnool", "Anantapur", "Ananthapuram", "Sri Sathya Sai"
]

excel_path = r'c:\Users\APSSDC\Desktop\main\Dharma-CMS\police-frontend\assets\Data\Revised AP Police Organisation 31-01-26.xlsx'
dart_path = r'c:\Users\APSSDC\Desktop\main\Dharma-CMS\police-frontend\lib\data\revised_police_hierarchy.dart'

def clean_name(name):
    if pd.isna(name): return ""
    return str(name).strip().replace("'", "\\'").replace('"', '\\"')

def parse_excel():
    print(f"Reading {excel_path}...")
    try:
        df = pd.read_excel(excel_path)
    except Exception as e:
        print(f"Error reading Excel: {e}")
        return

    hierarchy = {"districts": []}
    
    current_range = None
    current_district = None
    current_sdpo = None
    current_circle = None
    
    # Track the current object to append to
    district_obj = None
    sdpo_obj = None
    circle_obj = None

    print("Parsing rows...")
    for index, row in df.iterrows():
        # Get cell values
        col0 = clean_name(row.iloc[0]) # Likely descriptive or Range
        col1 = clean_name(row.iloc[1]) # Hierarchy Nodes
        col2 = clean_name(row.iloc[2]) # Stations

        # 1. Identify Range
        if "Range" in col1:
            current_range = col1
            print(f"Found Range: {current_range}")
            continue

        # 2. Identify District
        is_district = False
        # Exact match
        if col1 in DISTRICTS or col1.replace("SP ", "") in DISTRICTS:
            is_district = True
        # Partial match heuristic
        elif any(d in col1 for d in DISTRICTS) and (
            "District" in col1 or 
            col1.startswith("SP ") or 
            "Commissionerate" in col1
        ):
             is_district = True
        
        # Exclusions: Ensure it's not an officer rank being mistaken for a district
        if "SDPO" in col1 or "DSP" in col1 or "CI " in col1 or "Inspector" in col1:
            is_district = False
        
        if is_district:
            current_district = col1
            # Clean district name (remove SP prefix if purely for display?)
            # User wants "Select District", so "SP Chittoor" is technically the Officer, 
            # but the hierarchy node is "Chittoor".
            # If the user says "Assign to District (SP)", keeping "SP Chittoor" is fine.
            # But for consistency let's keep it as the Excel has it, or strip "SP ".
            # Excel has "SP Chittoor".
            
            district_obj = {
                "name": current_district,
                "range": current_range,
                "sdpos": []
            }
            hierarchy["districts"].append(district_obj)
            current_sdpo = None
            current_circle = None
            sdpo_obj = None
            circle_obj = None
            print(f"  Found District: {current_district}")
            continue

        # 3. Identify SDPO
        if "SDPO" in col1 or "DSP" in col1:
            current_sdpo = col1
            if district_obj is None:
                # Fallback: Create a dummy district if missing
                print(f"    Warning: SDPO {current_sdpo} found without District")
                continue
            
            sdpo_obj = {
                "name": current_sdpo,
                "circles": []
            }
            district_obj["sdpos"].append(sdpo_obj)
            current_circle = None
            circle_obj = None
            # print(f"    Found SDPO: {current_sdpo}")
            continue

        # 4. Identify Circle
        if "CI " in col1 or "Circle" in col1 or "UPS" in col1 or "Traffic" in col1:
            current_circle = col1
            if sdpo_obj is None:
                # Could be a direct circle under district or loose data
                # print(f"      Warning: Circle {current_circle} found without SDPO")
                 continue

            circle_obj = {
                "name": current_circle,
                "police_stations": []
            }
            sdpo_obj["circles"].append(circle_obj)
            # print(f"      Found Circle: {current_circle}")
            
            # Note: Sometimes Station is on the NEXT row, but sometimes SAME row (Col 2)
        
        # 5. Identify Station (Col 2)
        if col2:
            station_name = col2
            # Clean up "SHO " prefix if present, as requested user wants "Select SHO (Station)"
            # but the data file has "SHO ..." so we can keep it or strip it.
            # User example: "Select SHO (Station)" -> assignments says "Assigned to SHO, Eluru I Town"
            # If data is "SHO Eluru I Town", then "Assigned to SHO, SHO Eluru I Town" looks doubled?
            # User said: "Confirm assignment says 'Assigned to SHO, Eluru I Town'".
            # So likely we should strip "SHO " from the name.
            if station_name.startswith("SHO "):
                station_name = station_name[4:]
            
            if circle_obj:
                circle_obj["police_stations"].append(station_name)
    
    print(f"Parsed {len(hierarchy['districts'])} districts.")
    
    # Generate Dart File
    generate_dart(hierarchy)

def generate_dart(data):
    dart_content = "/// GENERATED FILE FROM Revised AP Police Organisation 31-01-26.xlsx\n"
    dart_content += "const Map<String, dynamic> kRevisedPoliceHierarchy = {\n"
    dart_content += '  "districts": [\n'

    for district in data['districts']:
        dart_content += '    {\n'
        dart_content += f'      "name": "{district["name"]}",\n'
        if district.get("range"):
             dart_content += f'      "range": "{district["range"]}",\n'
        dart_content += '      "sdpos": [\n'
        
        for sdpo in district.get('sdpos', []):
            dart_content += '        {\n'
            dart_content += f'          "name": "{sdpo["name"]}",\n'
            dart_content += '          "circles": [\n'
            
            for circle in sdpo.get('circles', []):
                dart_content += '            {\n'
                dart_content += f'              "name": "{circle["name"]}",\n'
                dart_content += '              "police_stations": [\n'
                
                for ps in circle.get('police_stations', []):
                    dart_content += f'                "{ps}",\n'
                
                dart_content += '              ]\n'
                dart_content += '            },\n'
            
            dart_content += '          ]\n'
            dart_content += '        },\n'
        
        dart_content += '      ]\n'
        dart_content += '    },\n'

    dart_content += '  ]\n'
    dart_content += '};\n'

    print(f"Writing Dart file to {dart_path}...")
    try:
        with open(dart_path, 'w', encoding='utf-8') as f:
            f.write(dart_content)
        print("Success!")
    except Exception as e:
        print(f"Error writing Dart file: {e}")

if __name__ == "__main__":
    parse_excel()
