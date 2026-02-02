#!/usr/bin/env python3

with open('frontend/lib/screens/case_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove const from contexts that use dynamic values
replacements = [
    ("ScaffoldMessenger.of(context).showSnackBar(\n                SnackBar(\n                  content: Text(AppLocalizations.of(context)!.documentUploaded),\n                  backgroundColor: Colors.green,\n                ),\n              );", "SnackBar(\n                  content: Text(AppLocalizations.of(context)!.documentUploaded),"),
]

# Simple string replacements to remove const from invalid contexts
content = content.replace(
    "SnackBar(\n                  content: Text(AppLocalizations.of(context)!.documentUploaded),",
    "SnackBar(\n                  content: Text(AppLocalizations.of(context)!.documentUploaded),"
)

# More general: remove const from any Dialog/SnackBar/etc that has AppLocalizations inside
import re

# Remove const from contexts where AppLocalizations.of is used
content = re.sub(
    r"const\s+(SnackBar|AlertDialog|TextField|Text)\(",
    r"\1(",
    content
)

# Remove const from list literals containing AppLocalizations
content = re.sub(
    r"const\s+\[\s+AppLocalizations\.of",
    "[\n                AppLocalizations.of",
    content
)

with open('frontend/lib/screens/case_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Removed const modifiers from dynamic localization contexts")
