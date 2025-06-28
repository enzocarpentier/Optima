#!/usr/bin/env swift

import Foundation

// Script pour ajouter un target de tests à Optima.xcodeproj
// Exécuter avec: swift add_test_target.swift

print("🧪 Configuration du target de tests pour Optima")
print("=" * 50)

print("\n📋 ÉTAPES MANUELLES À SUIVRE DANS XCODE :")
print("1. Ouvrir Optima.xcodeproj")
print("2. Sélectionner le projet 'Optima' dans le navigateur")
print("3. Cliquer sur le '+' en bas à gauche pour ajouter un target")
print("4. Choisir 'Unit Testing Bundle' > Next")
print("5. Configurer :")
print("   - Product Name: OptimaTests")
print("   - Target to be Tested: Optima")
print("   - Language: Swift")
print("6. Cliquer 'Finish'")

print("\n🔧 CONFIGURATION ALTERNATIVE VIA COMMAND LINE :")
print("Vous pouvez aussi créer le target avec xcodegen si installé :")

let projectYaml = """
name: Optima
options:
  bundleIdPrefix: com.enzocarpentier
targets:
  Optima:
    type: application
    platform: macOS
    deploymentTarget: "12.0"
    sources:
      - Optima
    dependencies:
      - package: Sparkle
  OptimaTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - OptimaTests
    dependencies:
      - target: Optima
packages:
  Sparkle:
    url: https://github.com/sparkle-project/Sparkle
    from: "2.7.1"
"""

print("\n📝 Fichier project.yml pour xcodegen :")
print(projectYaml)

print("\n✅ APRÈS CRÉATION DU TARGET :")
print("1. Le dossier OptimaTests sera créé automatiquement")
print("2. Un fichier OptimaTests.swift sera généré")
print("3. Vous pourrez ensuite y ajouter vos tests Sparkle")

print("\n🎯 SOLUTION RAPIDE MANUELLE :")
print("1. File > New > Target...")
print("2. macOS > Unit Testing Bundle")
print("3. Next > OptimaTests > Finish")
print("4. Vous aurez XCTest disponible !")

// Fonction utilitaire pour répéter une chaîne
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
} 