import os

directories = ['lib/screens', 'lib/widgets', 'lib/services']

for directory in directories:
    if not os.path.exists(directory):
        continue
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                content = content.replace("const Text(AppLocalizations.tr", "Text(AppLocalizations.tr")
                content = content.replace("const pw.Text(AppLocalizations.tr", "pw.Text(AppLocalizations.tr")
                
                if content != original_content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                        
print("Syntax fixed for const Text")
