from bing_image_downloader import downloader
import os

print("Starting to collect minimum 500+ images for Oral dataset...")

queries = [
    {"query": "human tongue close up medical photography", "dir": "Tongue"},
    {"query": "human healthy gums teeth close up medical", "dir": "Gums"},
    {"query": "floor of mouth under tongue medical anatomy", "dir": "Floor_of_Mouth"},
    {"query": "buccal mucosa inner cheek mouth medical", "dir": "Buccal_Mucosa"}
]

# 130 images per category to ensure we have over 500 total
limit = 130 

for q in queries:
    print(f"\n--- Downloading {limit} images for {q['dir']} ---")
    downloader.download(
        q["query"],
        limit=limit,
        output_dir='oral_dataset',
        adult_filter_off=False,
        force_replace=False,
        timeout=60,
        verbose=False
    )
    
    # Rename directory to clean names
    old_dir = os.path.join('oral_dataset', q["query"])
    new_dir = os.path.join('oral_dataset', q["dir"])
    if os.path.exists(old_dir):
        os.rename(old_dir, new_dir)

print("\nDataset collection complete! Check the 'oral_dataset' folder.")
