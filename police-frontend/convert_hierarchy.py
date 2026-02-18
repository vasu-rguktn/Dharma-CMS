import pandas as pd
import json
import os

EXCEL_PATH = r'assets/data/Revised AP Police Organisation 31-01-26.xlsx'
OUTPUT_DART_PATH = r'lib/data/police_hierarchy_data.dart'

def clean_name(name):
    if pd.isna(name) or name == '' or str(name).lower() == 'nan':
        return None
    return str(name).strip()

def main():
    print("Reading Excel file...")
    try:
        # Read the first sheet
        df = pd.read_excel(EXCEL_PATH)
        print(f"Columns found: {df.columns.tolist()}")
        
        # Normalize columns
        df.columns = [str(c).lower().strip() for c in df.columns]
        
        # Identify key columns
        # We need: Range (optional), District, SDPO, Circle, Station
        
        col_district = next((c for c in df.columns if 'district' in c), None)
        col_sdpo = next((c for c in df.columns if 'division' in c or 'sdpo' in c), None)
        col_circle = next((c for c in df.columns if 'circle' in c), None)
        col_station = next((c for c in df.columns if 'station' in c and 'police' in c), None)
        # Fallback for station if just "Station" or "PS"
        if not col_station:
            col_station = next((c for c in df.columns if 'station' in c), None)
        
        col_range = next((c for c in df.columns if 'range' in c or 'zone' in c), None)

        print(f"Mapped Columns: Range={col_range}, District={col_district}, SDPO={col_sdpo}, Circle={col_circle}, Station={col_station}")

        if not (col_district and col_sdpo and col_circle and col_station):
            print("CRITICAL ERROR: Could not map all required columns (District, SDPO, Circle, Station).")
            return

        hierarchy = []
        
        # If Range exists, we group by Range first, else we assume top level is District
        # But wait, looking at existing data, Range is top level. 
        # If Excel has Range, we use it. If not, we might need a dummy mapping or infer it.
        # Let's see if we have Range.
        
        # Iterate row by row
        current_range_data = None
        current_district_data = None
        current_sdpo_data = None
        current_circle_data = None
        
        # Helper to find existing item in list
        def find_item(lst, key, val):
            return next((item for item in lst if item.get(key) == val), None)

        for idx, row in df.iterrows():
            r_name = clean_name(row[col_range]) if col_range else "Andhra Pradesh"
            d_name = clean_name(row[col_district])
            s_name = clean_name(row[col_sdpo])
            c_name = clean_name(row[col_circle])
            st_name = clean_name(row[col_station])

            if not d_name: continue # Skip if no district
            
            # --- RANGE ---
            range_obj = find_item(hierarchy, 'range', r_name)
            if not range_obj:
                range_obj = {'range': r_name, 'districts': []}
                hierarchy.append(range_obj)
            
            # --- DISTRICT ---
            dist_obj = find_item(range_obj['districts'], 'name', d_name)
            if not dist_obj:
                dist_obj = {'name': d_name, 'sdpos': []}
                range_obj['districts'].append(dist_obj)
            
            # --- SDPO ---
            if s_name:
                sdpo_obj = find_item(dist_obj['sdpos'], 'name', s_name)
                if not sdpo_obj:
                    sdpo_obj = {'name': s_name, 'circles': []}
                    dist_obj['sdpos'].append(sdpo_obj)
                
                # --- CIRCLE ---
                if c_name:
                    circle_obj = find_item(sdpo_obj['circles'], 'name', c_name)
                    if not circle_obj:
                        circle_obj = {'name': c_name, 'stations': []}
                        sdpo_obj['circles'].append(circle_obj)
                    
                    # --- STATION ---
                    if st_name and st_name not in circle_obj['stations']:
                        circle_obj['stations'].append(st_name)

        # Generate Dart code
        dart_code = f"""
// Auto-generated from {EXCEL_PATH}
// Do not edit manually.

const List<Map<String, dynamic>> kPoliceHierarchyData = {json.dumps(hierarchy, indent=2)};
""" 
        
        # Write to file
        os.makedirs(os.path.dirname(OUTPUT_DART_PATH), exist_ok=True)
        with open(OUTPUT_DART_PATH, 'w', encoding='utf-8') as f:
            f.write(dart_code)
            
        print(f"Successfully generated {OUTPUT_DART_PATH}")
        print(f"Total Ranges: {len(hierarchy)}")
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
