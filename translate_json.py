import json
import os
import time
from deep_translator import GoogleTranslator

def main():
    with open('assets/i18n/en.json', 'r', encoding='utf-8') as f:
        en_dict = json.load(f)

    languages = ['hi', 'te', 'ta', 'kn', 'ml', 'bn', 'mr', 'gu', 'pa', 'or']

    # Keep DentalScan AI identical
    ignore_translation = ["DentalScan AI", "support@dentalscan.ai", "DentalScan AI v1.0.0"]

    for lang in languages:
        out_path = f'assets/i18n/{lang}.json'
        print(f"Translating to {lang}...")
        
        translator = GoogleTranslator(source='en', target=lang)
        translated_dict = {}
        
        keys = list(en_dict.keys())
        texts = list(en_dict.values())
        
        # Batch translate in chunks of 50
        batch_size = 50
        
        try:
            for i in range(0, len(keys), batch_size):
                batch_keys = keys[i:i+batch_size]
                batch_texts = texts[i:i+batch_size]
                
                # identify which ones to translate vs ignore
                to_translate_indices = []
                to_translate_texts = []
                for j, text in enumerate(batch_texts):
                    if text in ignore_translation:
                        translated_dict[batch_keys[j]] = text
                    else:
                        to_translate_indices.append(j)
                        to_translate_texts.append(text)
                
                if to_translate_texts:
                    results = translator.translate_batch(to_translate_texts)
                    for j, res in zip(to_translate_indices, results):
                        translated_dict[batch_keys[j]] = res
                        
                time.sleep(1) # Be nice
                
            with open(out_path, 'w', encoding='utf-8') as f:
                json.dump(translated_dict, f, ensure_ascii=False, indent=2)
            print(f"Saved {lang}.json")
            
        except Exception as e:
            print(f"Failed to translate to {lang}: {e}")
            
if __name__ == "__main__":
    main()
