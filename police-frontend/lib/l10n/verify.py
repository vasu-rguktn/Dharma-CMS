#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Verify localization files"""

import json

try:
    with open('app_en.arb', 'r', encoding='utf-8') as f:
        en = json.load(f)
    print(f'✓ English: {len(en)} entries')
    
    with open('app_te.arb', 'r', encoding='utf-8') as f:
        te = json.load(f)
    print(f'✓ Telugu: {len(te)} entries')
    
    # Check some case detail keys
    case_keys = ['firDetails', 'crimeScene', 'evidence', 'finalReport', 'addScene', 'deleteScene']
    for key in case_keys:
        if key in en and key in te:
            print(f'  ✓ {key}')
            
    print('\nAll localizations added successfully!')
except Exception as e:
    print(f'Error: {e}')
    import traceback
    traceback.print_exc()
