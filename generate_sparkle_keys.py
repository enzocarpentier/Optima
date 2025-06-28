#!/usr/bin/env python3
"""
Script de génération de clés EdDSA (Ed25519) pour Sparkle
Génère une paire de clés publique/privée compatible avec Sparkle
"""

import base64
import os
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ed25519

def generate_sparkle_keys():
    """Génère une paire de clés EdDSA pour Sparkle"""
    print("🔐 Génération des clés EdDSA pour Sparkle...")
    
    # Générer la clé privée Ed25519
    private_key = ed25519.Ed25519PrivateKey.generate()
    
    # Obtenir la clé publique
    public_key = private_key.public_key()
    
    # Sérialiser la clé privée en format PEM
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    
    # Sérialiser la clé publique en format raw bytes
    public_raw = public_key.public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw
    )
    
    # Encoder la clé publique en base64 pour Sparkle
    public_base64 = base64.b64encode(public_raw).decode('ascii')
    
    # Sauvegarder les clés
    with open('sparkle_private_key.pem', 'wb') as f:
        f.write(private_pem)
    
    with open('sparkle_public_key.txt', 'w') as f:
        f.write(public_base64)
    
    print("✅ Clés générées avec succès !")
    print(f"📁 Clé privée sauvegardée : sparkle_private_key.pem")
    print(f"📁 Clé publique sauvegardée : sparkle_public_key.txt")
    print()
    print("🔧 Configuration pour Xcode :")
    print(f"INFOPLIST_KEY_SUPublicEDKey = {public_base64}")
    print()
    print("⚠️  SÉCURITÉ IMPORTANTE :")
    print("- Gardez sparkle_private_key.pem SECRET et SÉCURISÉ")
    print("- Ajoutez sparkle_private_key.pem à votre .gitignore")
    print("- Utilisez la clé publique dans votre projet Xcode")
    print("- Utilisez la clé privée pour signer vos builds de release")
    
    return public_base64, private_pem.decode('ascii')

if __name__ == "__main__":
    try:
        public_key, private_key = generate_sparkle_keys()
    except ImportError:
        print("❌ Module 'cryptography' manquant")
        print("📦 Installation : pip3 install cryptography")
        exit(1)
    except Exception as e:
        print(f"❌ Erreur lors de la génération : {e}")
        exit(1) 