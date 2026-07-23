import os
import re
import json

directories = ['lib/screens', 'lib/widgets', 'lib/services']
strings_to_translate = set()

# Regex to match strings inside Text(), label:, hintText:, tooltip:, Title:
regexes = [
    re.compile(r"Text\(\s*'([^'\$]+)'"),
    re.compile(r'Text\(\s*"([^"\$]+)"'),
    re.compile(r"label:\s*'([^'\$]+)'"),
    re.compile(r'label:\s*"([^"\$]+)"'),
    re.compile(r"hintText:\s*'([^'\$]+)'"),
    re.compile(r'hintText:\s*"([^"\$]+)"'),
    re.compile(r"tooltip:\s*'([^'\$]+)'"),
    re.compile(r'tooltip:\s*"([^"\$]+)"'),
    re.compile(r"title:\s*Text\(\s*'([^'\$]+)'"),
    re.compile(r'title:\s*Text\(\s*"([^"\$]+)"')
]

for directory in directories:
    if not os.path.exists(directory):
        continue
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                    for regex in regexes:
                        matches = regex.findall(content)
                        for match in matches:
                            if len(match.strip()) > 1 and not match.startswith('assets/') and not match.startswith('http'):
                                strings_to_translate.add(match)

# Also need to manually add some known ones from our previous localization
known_strings = [
    'Preferences', 'Push Notifications', 'Get alerts for new scans', 'Dark Mode',
    'Switch to dark theme', 'Language', 'Select your language', 'Account & Security',
    'Change Password', 'Update your credentials', 'Privacy Policy', 'Read our policies',
    'Support', 'Help Center', 'FAQ and support', 'About App', 'Log Out'
]

for s in known_strings:
    strings_to_translate.add(s)

strings_list = sorted(list(strings_to_translate))

en_dict = {}
for i, s in enumerate(strings_list):
    # create a key by lowercasing, replacing spaces with underscores, and removing special chars
    key = re.sub(r'[^a-z0-9_]', '', s.lower().replace(' ', '_')).strip('_')
    # if key is empty or duplicate, make it unique
    if not key:
        key = f'string_{i}'
    
    # handle duplicates
    original_key = key
    counter = 1
    while key in en_dict and en_dict[key] != s:
        key = f'{original_key}_{counter}'
        counter += 1
        
    en_dict[key] = s

with open('assets/i18n/en.json', 'w', encoding='utf-8') as f:
    json.dump(en_dict, f, indent=2, ensure_ascii=False)

print(f"Extracted {len(en_dict)} strings to assets/i18n/en.json")
