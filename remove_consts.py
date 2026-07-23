import os
import re

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
                
                # Remove const from common widgets and lists
                widgets = ['Text', 'Column', 'Row', 'Padding', 'SizedBox', 'Center', 'Container', 'Align', 
                           'Positioned', 'Expanded', 'Flexible', 'RichText', 'pw\.Text', 'pw\.Column', 
                           'pw\.Row', 'pw\.Container', 'pw\.SizedBox', 'pw\.Padding', 'pw\.Center']
                
                for w in widgets:
                    content = re.sub(r'const\s+' + w + r'\(', w + '(', content)
                    
                content = content.replace('children: const [', 'children: [')
                content = content.replace('const [', '[')
                
                if content != original_content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                        
print("Consts removed")
