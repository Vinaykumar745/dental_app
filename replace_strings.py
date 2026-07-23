import os
import re
import json

directories = ['lib/screens', 'lib/widgets', 'lib/services']

with open('assets/i18n/en.json', 'r', encoding='utf-8') as f:
    en_dict = json.load(f)

# Sort by length descending to replace longer strings first (prevents partial matches)
sorted_items = sorted(en_dict.items(), key=lambda x: len(x[1]), reverse=True)

# Function to safely replace occurrences inside dart files
def replace_in_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    # Simple strategy: look for Text('...'), Text("..."), label: '...', hintText: '...', tooltip: '...'
    for key, text in sorted_items:
        if "'" not in text:
            content = content.replace(f"Text('{text}'", f"Text(AppLocalizations.tr('{key}')")
            content = content.replace(f"label: '{text}'", f"label: AppLocalizations.tr('{key}')")
            content = content.replace(f"hintText: '{text}'", f"hintText: AppLocalizations.tr('{key}')")
            content = content.replace(f"tooltip: '{text}'", f"tooltip: AppLocalizations.tr('{key}')")
            content = content.replace(f"title: Text('{text}')", f"title: Text(AppLocalizations.tr('{key}'))")
            content = content.replace(f"content: Text('{text}')", f"content: Text(AppLocalizations.tr('{key}'))")
            content = content.replace(f"pw.Text('{text}'", f"pw.Text(AppLocalizations.tr('{key}')")
        if '"' not in text:
            content = content.replace(f'Text("{text}"', f"Text(AppLocalizations.tr('{key}')")
            content = content.replace(f'label: "{text}"', f"label: AppLocalizations.tr('{key}')")
            content = content.replace(f'hintText: "{text}"', f"hintText: AppLocalizations.tr('{key}')")
            content = content.replace(f'tooltip: "{text}"', f"tooltip: AppLocalizations.tr('{key}')")
            content = content.replace(f'title: Text("{text}")', f"title: Text(AppLocalizations.tr('{key}'))")
            content = content.replace(f'content: Text("{text}")', f"content: Text(AppLocalizations.tr('{key}'))")
            content = content.replace(f'pw.Text("{text}"', f"pw.Text(AppLocalizations.tr('{key}')")
            
        # specifically for known strings without prefix (like in switch statements or bare usages)
        if text in ['Preferences', 'Push Notifications', 'Dark Mode', 'Language', 'Account & Security', 'Privacy Policy', 'Support', 'Log Out']:
            # Replace bare string if it's assigned to a variable or something? Too risky, we will skip bare strings
            pass

    if content != original_content:
        # Add import if missing
        if "import '../services/localization_service.dart';" not in content and "import 'package:dental_app/services/localization_service.dart';" not in content:
            # try to add it after flutter/material.dart
            if "import 'package:flutter/material.dart';" in content:
                content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../services/localization_service.dart';")
            else:
                content = "import '../services/localization_service.dart';\n" + content
                
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

for directory in directories:
    if not os.path.exists(directory):
        continue
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                replace_in_file(filepath)

print("Replacement complete.")
