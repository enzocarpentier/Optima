#!/usr/bin/env python3
"""
Script pour générer toutes les tailles d'icônes macOS
Usage: python3 generate_macos_icons.py ton_icone_1024.png
"""

import sys
from PIL import Image
import os

def generate_macos_icons(source_path):
    """Génère toutes les tailles d'icônes requises pour macOS"""
    
    # Vérifier que le fichier source existe
    if not os.path.exists(source_path):
        print(f"❌ Erreur: {source_path} n'existe pas")
        return False
    
    # Ouvrir l'image source
    try:
        source_img = Image.open(source_path)
        print(f"✅ Image source chargée: {source_img.size}")
    except Exception as e:
        print(f"❌ Erreur lors du chargement: {e}")
        return False
    
    # Définir les tailles requises pour macOS
    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png")
    ]
    
    # Créer le dossier de sortie
    output_dir = "generated_macos_icons"
    os.makedirs(output_dir, exist_ok=True)
    
    # Générer chaque taille
    for size, filename in sizes:
        try:
            # Redimensionner avec une haute qualité
            resized_img = source_img.resize((size, size), Image.LANCZOS)
            
            # Sauvegarder
            output_path = os.path.join(output_dir, filename)
            resized_img.save(output_path, "PNG", optimize=True)
            
            print(f"✅ Généré: {filename} ({size}x{size})")
            
        except Exception as e:
            print(f"❌ Erreur pour {filename}: {e}")
    
    print(f"\n🎯 Toutes les icônes générées dans: {output_dir}/")
    return True

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 generate_macos_icons.py ton_icone_1024.png")
        sys.exit(1)
    
    source_file = sys.argv[1]
    generate_macos_icons(source_file)
