import json
import os

def main():
    with open('assets/i18n/en.json', 'r', encoding='utf-8') as f:
        en_dict = json.load(f)

    languages = ['hi', 'te', 'ta', 'kn', 'ml', 'bn', 'mr', 'gu', 'pa', 'or']

    for lang in languages:
        out_path = f'assets/i18n/{lang}.json'
        
        translated_dict = {}
        for key, text in en_dict.items():
            if text == "DentalScan AI" or text == "support@dentalscan.ai":
                translated_dict[key] = text
            else:
                translated_dict[key] = f"[{lang.upper()}] {text}"
                
        with open(out_path, 'w', encoding='utf-8') as f:
            json.dump(translated_dict, f, ensure_ascii=False, indent=2)
        print(f"Saved {lang}.json")

if __name__ == "__main__":
    main()
