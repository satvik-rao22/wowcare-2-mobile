import os
import glob
from PIL import Image

def compress_and_replace():
    assets_dir = 'assets'
    search_patterns = ['**/*.jpg', '**/*.jpeg', '**/*.png']
    files_to_compress = []
    
    for pattern in search_patterns:
        files_to_compress.extend(glob.glob(os.path.join(assets_dir, pattern), recursive=True))
        
    replacements = []

    for filepath in files_to_compress:
        size_mb = os.path.getsize(filepath) / (1024 * 1024)
        if size_mb > 0.5: # compress if > 500KB
            try:
                with Image.open(filepath) as img:
                    if img.mode in ('RGBA', 'LA') or (img.mode == 'P' and 'transparency' in img.info):
                        img = img.convert('RGBA')
                    else:
                        img = img.convert('RGB')
                        
                    max_dim = 1920
                    if img.width > max_dim or img.height > max_dim:
                        img.thumbnail((max_dim, max_dim), Image.Resampling.LANCZOS)
                        
                    base_name, _ = os.path.splitext(filepath)
                    new_filepath = base_name + '.webp'
                    
                    img.save(new_filepath, 'webp', quality=80)
                
                os.remove(filepath)
                
                old_rel = filepath
                new_rel = new_filepath
                replacements.append((old_rel, new_rel))
                print(f"Compressed {filepath} -> {new_filepath}")
            except Exception as e:
                print(f"Failed to compress {filepath}: {e}")

    if not replacements:
        print("No files compressed.")
        return

    dart_files = glob.glob('lib/**/*.dart', recursive=True)
    pubspec = ['pubspec.yaml']
    
    for fpath in dart_files + pubspec:
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        new_content = content
        for old, new in replacements:
            old_base = os.path.basename(old)
            new_base = os.path.basename(new)
            # Replace exact paths first
            new_content = new_content.replace(old, new)
            # Then replace just the filenames if they used basenames
            new_content = new_content.replace(old_base, new_base)
            
        if new_content != content:
            with open(fpath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Updated references in {fpath}")

if __name__ == '__main__':
    compress_and_replace()
