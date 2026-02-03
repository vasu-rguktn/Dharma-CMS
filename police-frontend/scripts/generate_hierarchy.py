import json
import os

# Define paths
json_path = r'c:\Users\APSSDC\Desktop\main\Dharma-CMS\police-frontend\assets\Data\ap_police_hierarchy_fir.json'
dart_path = r'c:\Users\APSSDC\Desktop\main\Dharma-CMS\police-frontend\lib\data\revised_police_hierarchy.dart'

def generate_dart_file():
    print(f"Reading JSON from {json_path}...")
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error reading JSON: {e}")
        return

    print(f"Found {len(data.get('districts', []))} districts.")

    # Start building Dart file content
    dart_content = "/// GENERATED FILE FROM ap_police_hierarchy_fir.json\n"
    dart_content += "/// Corresponds to Revised AP Police Organisation 31-01-26.xlsx\n"
    dart_content += "const Map<String, dynamic> kRevisedPoliceHierarchy = {\n"
    dart_content += '  "districts": [\n'

    for district in data.get('districts', []):
        d_name = district.get('name', '').replace("'", "\\'")
        dart_content += '    {\n'
        dart_content += f'      "name": "{d_name}",\n'
        dart_content += '      "sdpos": [\n'
        
        for sdpo in district.get('sdpos', []):
            s_name = sdpo.get('name', '').replace("'", "\\'")
            dart_content += '        {\n'
            dart_content += f'          "name": "{s_name}",\n'
            dart_content += '          "circles": [\n'
            
            for circle in sdpo.get('circles', []):
                c_name = circle.get('name', '').replace("'", "\\'")
                dart_content += '            {\n'
                dart_content += f'              "name": "{c_name}",\n'
                dart_content += '              "police_stations": [\n'
                
                for ps in circle.get('police_stations', []):
                    ps_name = str(ps).replace("'", "\\'")
                    dart_content += f'                "{ps_name}",\n'
                
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
    generate_dart_file()
