#!/usr/bin/env python3
import re

with open('frontend/lib/screens/case_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find all method definitions and their bodies to add 'loc' variable
# Pattern: method declaration to method end
pattern = r'(Future<void>|void|Widget)\s+_(\w+)\(\)\s*(?:async\s*)?\{([^}]*(?:\{[^}]*\}[^}]*)*)\}'

def add_loc_initialization(match):
    """Add loc initialization to methods that use localizations"""
    prefix = match.group(1)  # Future<void>, void, Widget
    method_name = match.group(2)  # method name
    body = match.group(3)  # method body
    
    # Check if this method uses 'localizations.' 
    if 'localizations.' not in body:
        return match.group(0)  # No changes needed
    
    # Check if 'loc' is already defined
    if 'final loc = AppLocalizations.of(context)' in body or 'final loc =' in body[:200]:
        return match.group(0)  # Already initialized
    
    # Add loc initialization after the first opening brace
    # Find the first statement after the opening brace
    new_body = body.lstrip()
    if new_body:
        # Add loc initialization at the beginning
        new_body = '\n    final loc = AppLocalizations.of(context)!;\n    ' + new_body
    
    # Replace all 'localizations.' with 'loc.' in this method
    new_body = new_body.replace('localizations.', 'loc.')
    
    return f'{prefix} _{method_name}() async {{{new_body}}}'

# For each match, fix it
matches = list(re.finditer(pattern, content, re.DOTALL))
print(f"Found {len(matches)} methods")

# Process in reverse order to avoid offset issues
offset = 0
for match in matches:
    if 'localizations.' in match.group(0):
        method_name = match.group(2)
        # Replace localizations with loc in this match
        original = match.group(0)
        # Add loc initialization if not already there
        if 'final loc = AppLocalizations.of(context)' not in original:
            # Insert after the opening brace
            body_start = original.find('{') + 1
            new_original = original[:body_start] + '\n    final loc = AppLocalizations.of(context)!;' + original[body_start:]
            new_original = new_original.replace('localizations.', 'loc.')
            
            content = content[:match.start()] + new_original + content[match.end():]
            print(f"Fixed method: _{method_name}")

# Also handle any remaining loose 'const SnackBar' references
content = re.sub(
    r'const SnackBar\(content: Text\(localizations\.',
    'SnackBar(content: Text(loc.',
    content
)

# Fix any remaining const ListView/Column/etc with localizations
content = re.sub(
    r'const Text\(localizations\.',
    'Text(loc.',
    content
)

with open('frontend/lib/screens/case_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Fixed localization references in case_detail_screen.dart")
