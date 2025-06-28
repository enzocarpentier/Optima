#!/usr/bin/env python3
import base64
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ed25519
import sys

def sign_file_with_ed25519(file_path, private_key_path):
    # Lire la clé privée
    with open(private_key_path, 'rb') as f:
        private_key = serialization.load_pem_private_key(f.read(), password=None)
    
    # Lire le fichier à signer
    with open(file_path, 'rb') as f:
        file_data = f.read()
    
    # Créer la signature
    signature = private_key.sign(file_data)
    
    # Encoder en base64
    signature_b64 = base64.b64encode(signature).decode('ascii')
    
    return signature_b64, len(file_data)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 sign_dmg.py <dmg_file> <private_key_file>")
        sys.exit(1)
    
    dmg_file = sys.argv[1]
    key_file = sys.argv[2]
    
    try:
        signature, size = sign_file_with_ed25519(dmg_file, key_file)
        print(f"📄 Fichier: {dmg_file}")
        print(f"📏 Taille: {size} bytes")
        print(f"🔐 Signature EdDSA: {signature}")
        print()
        print("🔄 Configuration pour appcast.xml:")
        print(f"length=\"{size}\"")
        print(f"sparkle:edSignature=\"{signature}\"")
    except Exception as e:
        print(f"❌ Erreur: {e}")
