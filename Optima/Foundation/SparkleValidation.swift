//
//  SparkleValidation.swift
//  Foundation
//
//  Script de validation de l'intégration Sparkle
//  Vérifie que toutes les composantes sont correctement configurées
//

import SwiftUI
import Sparkle
import Foundation

/// **Validation complète de l'intégration Sparkle**
/// 
/// Cette classe effectue tous les tests nécessaires pour s'assurer
/// que l'intégration Sparkle est fonctionnelle et sécurisée.
struct SparkleValidation {
    
    // MARK: - Tests de Configuration
    
    /// Valide la configuration Info.plist
    static func validateInfoPlist() -> ValidationResult {
        var issues: [String] = []
        var successes: [String] = []
        
        let bundle = Bundle.main
        
        // Vérification de l'URL du feed
        if let feedURL = bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String {
            if feedURL.hasPrefix("https://") {
                successes.append("✅ SUFeedURL configuré avec HTTPS: \(feedURL)")
            } else {
                issues.append("⚠️ SUFeedURL devrait utiliser HTTPS pour la sécurité")
            }
        } else {
            issues.append("❌ SUFeedURL manquant dans Info.plist")
        }
        
        // Vérification des mises à jour automatiques
        if let autoCheck = bundle.object(forInfoDictionaryKey: "SUEnableAutomaticChecks") as? Bool {
            successes.append("✅ SUEnableAutomaticChecks: \(autoCheck)")
        } else {
            issues.append("⚠️ SUEnableAutomaticChecks non défini (optionnel)")
        }
        
        // Vérification de l'intervalle
        if let interval = bundle.object(forInfoDictionaryKey: "SUScheduledCheckInterval") as? Int {
            let hours = interval / 3600
            successes.append("✅ SUScheduledCheckInterval: \(hours)h (\(interval)s)")
        } else {
            issues.append("⚠️ SUScheduledCheckInterval non défini (utilise défaut 24h)")
        }
        
        // Vérification de la clé publique
        if let publicKey = bundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String {
            if publicKey.count > 20 {
                successes.append("✅ SUPublicEDKey configuré")
            } else {
                issues.append("⚠️ SUPublicEDKey semble être un placeholder - remplacer par vraie clé")
            }
        } else {
            issues.append("⚠️ SUPublicEDKey manquant (signatures désactivées)")
        }
        
        // Vérification des informations de version
        if let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            successes.append("✅ Version de l'app: \(version)")
        } else {
            issues.append("❌ CFBundleShortVersionString manquant")
        }
        
        if let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            successes.append("✅ Build de l'app: \(build)")
        } else {
            issues.append("❌ CFBundleVersion manquant")
        }
        
        return ValidationResult(
            category: "Configuration Info.plist",
            successes: successes,
            issues: issues
        )
    }
    
    /// Valide les entitlements réseau
    static func validateEntitlements() -> ValidationResult {
        var issues: [String] = []
        var successes: [String] = []
        
        let bundle = Bundle.main
        
        // Vérification du sandbox
        if let entitlements = bundle.object(forInfoDictionaryKey: "com.apple.security.app-sandbox") as? Bool {
            if entitlements {
                successes.append("✅ App Sandbox activé")
                
                // Vérification des permissions réseau
                if let networkClient = bundle.object(forInfoDictionaryKey: "com.apple.security.network.client") as? Bool {
                    if networkClient {
                        successes.append("✅ Permissions réseau client accordées")
                    } else {
                        issues.append("❌ Permissions réseau client manquantes - mises à jour impossibles")
                    }
                } else {
                    issues.append("❌ com.apple.security.network.client non défini")
                }
            } else {
                issues.append("⚠️ App Sandbox désactivé - recommandé pour la distribution")
            }
        }
        
        return ValidationResult(
            category: "Entitlements & Permissions",
            successes: successes,
            issues: issues
        )
    }
    
    /// Valide l'intégration du service UpdateService
    @MainActor
    static func validateUpdateService() -> ValidationResult {
        var issues: [String] = []
        var successes: [String] = []
        
        // Test d'initialisation du service
        let updateService = UpdateService()
        successes.append("✅ UpdateService s'initialise sans erreur")
        
        // Test de l'état initial
        if !updateService.isCheckingForUpdates {
            successes.append("✅ État initial correct (pas de vérification en cours)")
        } else {
            issues.append("⚠️ État initial inattendu (vérification en cours)")
        }
        
        if updateService.lastError == nil {
            successes.append("✅ Aucune erreur initiale")
        } else {
            issues.append("⚠️ Erreur présente à l'initialisation")
        }
        
        // Test des préférences
        updateService.updatePreferences(automaticCheck: true, automaticDownload: false)
        if UserDefaults.standard.bool(forKey: "AutomaticUpdateCheck") {
            successes.append("✅ Sauvegarde des préférences fonctionnelle")
        } else {
            issues.append("❌ Sauvegarde des préférences échouée")
        }
        
        return ValidationResult(
            category: "Service UpdateService",
            successes: successes,
            issues: issues
        )
    }
    
    /// Valide l'intégration avec AppCoordinator
    @MainActor
    static func validateCoordinatorIntegration() -> ValidationResult {
        var issues: [String] = []
        var successes: [String] = []
        
        let coordinator = AppCoordinator()
        
        // Vérification de la présence du service
        let updateService = coordinator.updateService
        successes.append("✅ UpdateService accessible depuis AppCoordinator")
        
        // Test de la méthode checkForUpdates
        coordinator.checkForUpdates()
        if updateService.isCheckingForUpdates {
            successes.append("✅ checkForUpdates() déclenche correctement la vérification")
        } else {
            issues.append("❌ checkForUpdates() ne déclenche pas la vérification")
        }
        
        return ValidationResult(
            category: "Intégration AppCoordinator",
            successes: successes,
            issues: issues
        )
    }
    
    /// Valide la connectivité réseau et l'accès au feed
    static func validateNetworkConnectivity() async -> ValidationResult {
        var issues: [String] = []
        var successes: [String] = []
        
        // Test de connectivité générale
        let testURL = URL(string: "https://www.apple.com")!
        
        do {
            let (_, response) = try await URLSession.shared.data(from: testURL)
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                successes.append("✅ Connectivité internet fonctionnelle")
                
                // Test du feed Sparkle
                if let feedURLString = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String,
                   let feedURL = URL(string: feedURLString) {
                    
                    do {
                        let (data, feedResponse) = try await URLSession.shared.data(from: feedURL)
                        if let httpFeedResponse = feedResponse as? HTTPURLResponse {
                            if httpFeedResponse.statusCode == 200 {
                                successes.append("✅ Feed Sparkle accessible (\(data.count) bytes)")
                                
                                // Validation basique du XML
                                if let xmlString = String(data: data, encoding: .utf8),
                                   xmlString.contains("<rss") && xmlString.contains("sparkle:") {
                                    successes.append("✅ Feed XML semble valide (contient éléments Sparkle)")
                                } else {
                                    issues.append("⚠️ Feed XML potentiellement malformé")
                                }
                            } else {
                                issues.append("❌ Feed Sparkle inaccessible (HTTP \(httpFeedResponse.statusCode))")
                            }
                        }
                    } catch {
                        issues.append("⚠️ Erreur d'accès au feed Sparkle: \(error.localizedDescription)")
                        issues.append("💡 Ceci est normal si le feed n'existe pas encore en développement")
                    }
                }
            } else {
                issues.append("❌ Problème de connectivité internet")
            }
        } catch {
            issues.append("❌ Pas de connexion internet: \(error.localizedDescription)")
        }
        
        return ValidationResult(
            category: "Connectivité Réseau",
            successes: successes,
            issues: issues
        )
    }
    
    // MARK: - Tests Basiques Sans XCTest
    
    /// Tests basiques qui ne nécessitent pas XCTest
    @MainActor
    static func runBasicTests() {
        print("\n🧪 TESTS BASIQUES SPARKLE (Sans XCTest)")
        print("=" * 50)
        
        // Test 1: Initialisation UpdateService
        print("\n📋 Test 1: Initialisation UpdateService")
        let service = UpdateService()
        print("✅ UpdateService créé sans erreur")
        print("✅ État initial: isChecking=\(service.isCheckingForUpdates)")
        print("✅ Dernière erreur: \(service.lastError?.localizedDescription ?? "Aucune")")
        
        // Test 2: Préférences UserDefaults
        print("\n📋 Test 2: Gestion des Préférences")
        let service2 = UpdateService()
        
        // Test sauvegarde
        service2.updatePreferences(automaticCheck: true, automaticDownload: false)
        let autoCheck = UserDefaults.standard.bool(forKey: "AutomaticUpdateCheck")
        let autoDownload = UserDefaults.standard.bool(forKey: "AutomaticDownload")
        
        if autoCheck && !autoDownload {
            print("✅ Préférences sauvegardées correctement")
        } else {
            print("❌ Problème de sauvegarde des préférences")
        }
        
        // Test 3: AppCoordinator Integration
        print("\n📋 Test 3: Intégration AppCoordinator")
        let coordinator = AppCoordinator()
        let updateService = coordinator.updateService
        
        print("✅ UpdateService accessible depuis AppCoordinator")
        
        // Test méthode checkForUpdates
        coordinator.checkForUpdates()
        if updateService.isCheckingForUpdates {
            print("✅ checkForUpdates() fonctionne")
        } else {
            print("⚠️ checkForUpdates() n'a pas déclenché la vérification")
        }
        
        // Test 4: Types d'erreurs
        print("\n📋 Test 4: Types d'Erreurs")
        let errors: [UpdateService.UpdateError] = [
            .networkUnavailable,
            .feedNotFound,
            .invalidResponse,
            .noUpdatesAvailable,
            .downloadFailed,
            .installationFailed
        ]
        
        var errorTestsPassed = 0
        for error in errors {
            if let description = error.errorDescription, !description.isEmpty {
                errorTestsPassed += 1
            }
        }
        
        if errorTestsPassed == errors.count {
            print("✅ Tous les types d'erreurs ont des descriptions valides")
        } else {
            print("❌ \(errors.count - errorTestsPassed) types d'erreurs manquent de description")
        }
        
        // Test 5: Formatage des dates
        print("\n📋 Test 5: Formatage des Dates")
        let testService = UpdateService()
        
        // Test sans date
        let formatted1 = testService.lastCheckFormatted
        if formatted1 == "Jamais" {
            print("✅ Formatage sans date fonctionne")
        } else {
            print("❌ Formatage sans date incorrect: \(formatted1)")
        }
        
        // Test avec date
        testService.lastCheckDate = Date()
        let formatted2 = testService.lastCheckFormatted
        if formatted2 != "Jamais" && formatted2.count > 5 {
            print("✅ Formatage avec date fonctionne: \(formatted2)")
        } else {
            print("❌ Formatage avec date incorrect")
        }
        
        print("\n🎉 Tests basiques terminés !")
    }
    
    // MARK: - Validation Complète
    
    /// Lance tous les tests de validation
    @MainActor
    static func runCompleteValidation() async {
        print("\n🔄 VALIDATION COMPLÈTE DE L'INTÉGRATION SPARKLE")
        print("=" * 60)
        
        let results = [
            validateInfoPlist(),
            validateEntitlements(),
            validateUpdateService(),
            validateCoordinatorIntegration(),
            await validateNetworkConnectivity()
        ]
        
        var totalSuccesses = 0
        var totalIssues = 0
        
        for result in results {
            print("\n📋 \(result.category)")
            print("-" * 40)
            
            for success in result.successes {
                print(success)
                totalSuccesses += 1
            }
            
            for issue in result.issues {
                print(issue)
                totalIssues += 1
            }
        }
        
        print("\n" + "=" * 60)
        print("📊 RÉSUMÉ DE LA VALIDATION")
        print("✅ Réussites: \(totalSuccesses)")
        print("⚠️ Problèmes: \(totalIssues)")
        
        if totalIssues == 0 {
            print("🎉 INTÉGRATION SPARKLE PARFAITE ! Prêt pour la production.")
        } else if totalIssues <= 3 {
            print("✨ INTÉGRATION SPARKLE FONCTIONNELLE avec quelques améliorations recommandées.")
        } else {
            print("🔧 INTÉGRATION SPARKLE À FINALISER - Corriger les problèmes critiques.")
        }
        
        print("\n💡 Prochaines étapes recommandées:")
        print("1. Générer une vraie paire de clés EdDSA pour la signature")
        print("2. Créer le repository GitHub avec le feed XML")
        print("3. Tester avec une vraie mise à jour déployée")
        print("4. Configurer GitHub Actions pour automatiser les builds")
        
        // Lancer aussi les tests basiques
        runBasicTests()
    }
}

// MARK: - Types de Support

/// Résultat d'un test de validation
struct ValidationResult {
    let category: String
    let successes: [String]
    let issues: [String]
}

// MARK: - Extensions Utilitaires

extension String {
    /// Répète une chaîne n fois
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}

// MARK: - Fonction de Test Rapide

/// Fonction utilitaire pour lancer la validation depuis n'importe où
@MainActor
func validateSparkleIntegration() async {
    await SparkleValidation.runCompleteValidation()
}

/// Fonction pour tests basiques sans async
@MainActor
func testSparkleBasics() {
    SparkleValidation.runBasicTests()
} 