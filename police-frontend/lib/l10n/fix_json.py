#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Fix JSON formatting in .arb files"""

import re

# Read the file
with open('app_en.arb', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix patterns where } is missing comma before next key
# Pattern 1: }  followed by newlines and key
content = re.sub(r'(\})\s*\n\s*\n\s*"', r'\1,\n  "', content)
# Pattern 2: } immediately followed by key (after newlines)
content = re.sub(r'(\})\s*\n\s*"', r'\1,\n  "', content)
# Remove carriage returns
content = content.replace('\r', '')

# Write back
with open('app_en.arb', 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed JSON formatting in app_en.arb')

# Now do the same for Telugu
with open('app_te.arb', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r'(\})\s*\n\s*\n\s*"', r'\1,\n  "', content)
content = re.sub(r'(\})\s*\n\s*"', r'\1,\n  "', content)
content = content.replace('\r', '')

with open('app_te.arb', 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed JSON formatting in app_te.arb')
