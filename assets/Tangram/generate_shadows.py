import os
from PIL import Image

source_dir = r"d:\Mestrado\Jogos\Matemática para crianças\assets\tangram"
target_dir = os.path.join(source_dir, "shadows")

if not os.path.exists(target_dir):
    os.makedirs(target_dir)

# Cor da sombra (Cinza Escuro)
shadow_color = (60, 60, 60, 255) # RGBA

for filename in os.listdir(source_dir):
    if filename.endswith(".png"):
        print(f"Processando {filename}...")
        img_path = os.path.join(source_dir, filename)
        img = Image.open(img_path).convert("RGBA")
        
        pixels = img.load()
        width, height = img.size
        
        for y in range(height):
            for x in range(width):
                r, g, b, a = pixels[x, y]
                if a > 0: # Se não for transparente
                    pixels[x, y] = shadow_color
        
        target_path = os.path.join(target_dir, filename)
        img.save(target_path)
        print(f"Sombra salva em {target_path}")
