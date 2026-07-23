import json
import os

missing_keys = {
    'get_alerts': 'Get alerts for new scans',
    'switch_dark': 'Switch to dark theme',
    'account_security': 'Account & Security',
    'update_credentials': 'Update your credentials',
    'read_policies': 'Read our policies',
    'support': 'Support',
    'faq_support': 'FAQ and support',
    'about_app': 'About App',
    'log_out': 'Log Out',
    'preferences': 'Preferences',
    'push_notifications': 'Push Notifications',
    'dark_mode': 'Dark Mode',
    'language': 'Language',
    'change_password': 'Change Password',
    'privacy_policy': 'Privacy Policy',
    'help_center': 'Help Center'
}

languages = ['en', 'hi', 'te', 'ta', 'kn', 'ml', 'bn', 'mr', 'gu', 'pa', 'or']

for lang in languages:
    path = f'assets/i18n/{lang}.json'
    if not os.path.exists(path):
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    for k, v in missing_keys.items():
        if lang == 'en':
            data[k] = v
        else:
            data[k] = f"[{lang.upper()}] {v}"
            
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        
print("Updated all json files with missing keys.")
