import os

def generate_yaml() -> None:
    dirs_with_files = set()
    
    # Crawl the assets directory
    for root, dirs, files in os.walk('assets'):
        # Only include folders that actually contain files (ignoring hidden files)
        if any(f for f in files if not f.startswith('.')):
            # Normalize Windows backslashes to standard forward slashes
            folder = root.replace('\\', '/')
            dirs_with_files.add(f"    - {folder}/")

    print("Copy and paste this under your 'flutter:' section\n")
    print("  assets:")
    for folder in sorted(dirs_with_files):
        print(folder)

if __name__ == "__main__":
    print("Generating the assets...")
    generate_yaml()