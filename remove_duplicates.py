#!/usr/bin/env python3
import re

def remove_duplicate_getters(file_path):
    """Remove duplicate getter definitions, keeping the first occurrence"""
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Track getter names we've seen
    seen_getters = set()
    new_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Check if this is a getter definition
        getter_match = re.match(r'\s+(?:@override\s+)?(?:String|\/\/)?\s+get\s+(\w+)\s*=>', line)
        
        if getter_match:
            getter_name = getter_match.group(1)
            
            # Check if we've seen this getter before
            if getter_name in seen_getters:
                # Skip this entire getter definition (can be multi-line)
                print(f"🗑️  Removing duplicate getter: {getter_name}")
                
                # Skip the @override decorator if present
                if i > 0 and '@override' in lines[i-1]:
                    new_lines.pop()  # Remove the @override we just added
                
                # Skip until we find the next getter or closing brace
                while i < len(lines):
                    if re.match(r'\s+(@override|String get|}\s*$)', lines[i]):
                        if '@override' not in lines[i]:
                            break
                    i += 1
                continue
            else:
                seen_getters.add(getter_name)
        
        new_lines.append(line)
        i += 1
    
    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    return len(seen_getters)

# Process both files
print("Processing English file...")
en_count = remove_duplicate_getters('frontend/lib/l10n/app_localizations_en.dart')
print(f"✅ English file: {en_count} unique getters")

print("\nProcessing Telugu file...")
te_count = remove_duplicate_getters('frontend/lib/l10n/app_localizations_te.dart')
print(f"✅ Telugu file: {te_count} unique getters")

print("\n✅ Duplicate removal complete!")
