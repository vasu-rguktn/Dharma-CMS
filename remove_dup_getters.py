#!/usr/bin/env python3
import re

# These 22 keys were already defined and should NOT be re-added
duplicate_keys = {
    'address', 'analysisComplete', 'analyzing', 'areaMandal', 'beatNumber',
    'cancel', 'cityDistrict', 'dayOfOccurrence', 'delete', 'firDetails',
    'firNumber', 'identifiedElements', 'latitude', 'longitude', 'mobileNumber',
    'pin', 'policeStation', 'priorToDateTimeDetails', 'rank', 'save',
    'streetVillage', 'timePeriod'
}

def remove_duplicate_getters(file_path, keep_later=False):
    """Remove duplicate getter definitions from file.
    keep_later=False means keep first occurrence (original definitions)
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Find all getter definitions with line numbers
    getter_positions = {}  # getter_name -> list of (start_line, end_line)
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Look for @override decorator
        if '@override' in line and i + 1 < len(lines):
            next_line = lines[i + 1]
            match = re.match(r'\s+String get (\w+)\s*=>', next_line)
            
            if match:
                getter_name = match.group(1)
                
                # Find the end of this getter (look for semicolon)
                start = i
                j = i + 1
                while j < len(lines) and ';' not in lines[j]:
                    j += 1
                end = j
                
                if getter_name not in getter_positions:
                    getter_positions[getter_name] = []
                getter_positions[getter_name].append((start, end))
                
                i = end + 1
                continue
        
        i += 1
    
    # Remove duplicate occurrences
    lines_to_remove = set()
    removed_count = 0
    
    for getter_name, positions in getter_positions.items():
        if getter_name in duplicate_keys and len(positions) > 1:
            # Keep the first occurrence, remove the rest
            for start, end in positions[1:]:
                for line_idx in range(start, end + 1):
                    lines_to_remove.add(line_idx)
                print(f"🗑️  Removing duplicate: {getter_name} (lines {start+1}-{end+1})")
                removed_count += 1
    
    # Create new content without removed lines
    new_lines = [line for i, line in enumerate(lines) if i not in lines_to_remove]
    
    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    print(f"✅ Removed {removed_count} duplicate getter definitions")
    return removed_count

# Process both files
print("=== Removing duplicates from English file ===")
en_removed = remove_duplicate_getters('frontend/lib/l10n/app_localizations_en.dart')

print("\n=== Removing duplicates from Telugu file ===")
te_removed = remove_duplicate_getters('frontend/lib/l10n/app_localizations_te.dart')

print(f"\n✅ Total duplicates removed: {en_removed + te_removed}")
