import json
import os
import urllib.request
import urllib.parse
import time
import sys

def translate_text(text, target_lang):
    if text in ["DentalScan AI", "support@dentalscan.ai", "DentalScan AI v1.0.0"]:
        return text
        
    url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=" + target_lang + "&dt=t&q=" + urllib.parse.quote(text)
    
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    
    retries = 3
    for _ in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=5) as response:
                result = json.loads(response.read().decode('utf-8'))
                translated = "".join([sentence[0] for sentence in result[0]])
                return translated
        except Exception as e:
            time.sleep(1)
            
    print(f"Failed to translate: {text}")
    return f"[{target_lang.upper()}] {text}"

def main():
    with open('assets/i18n/en.json', 'r', encoding='utf-8') as f:
        en_dict = json.load(f)

    languages = ['hi', 'te', 'ta', 'kn', 'ml', 'bn', 'mr', 'gu', 'pa', 'or']

    for lang in languages:
        out_path = f'assets/i18n/{lang}.json'
        
        # Check if already translated (if it doesn't contain "[LANG]")
        if os.path.exists(out_path):
            with open(out_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            # Check a random key like "dashboard"
            if not data.get("dashboard", "").startswith(f"[{lang.upper()}]"):
                print(f"Skipping {lang}, already translated.")
                continue
                
        print(f"Translating to {lang}...")
        
        translated_dict = {}
        for i, (key, text) in enumerate(en_dict.items()):
            translated_dict[key] = translate_text(text, lang)
            if i % 20 == 0 and i > 0:
                print(f"  ... {i}/{len(en_dict)}")
            time.sleep(0.05)
            
        with open(out_path, 'w', encoding='utf-8') as f:
            json.dump(translated_dict, f, ensure_ascii=False, indent=2)
        print(f"Saved {lang}.json")

if __name__ == "__main__":
    main()
