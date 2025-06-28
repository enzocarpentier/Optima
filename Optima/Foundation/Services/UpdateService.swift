//
//  UpdateService.swift
//  Foundation/Services
//
//  Service de gestion des mises à jour automatiques avec Sparkle
//  Architecture robuste avec gestion d'erreurs et configuration flexible
//

import SwiftUI
import Sparkle
import Foundation

/// **Delegate Sparkle pour la gestion des callbacks**
/// 
/// Classe séparée pour gérer les callbacks Sparkle sans conflit MainActor
final class SparkleUpdateDelegate: NSObject, SPUUpdaterDelegate {
    weak var updateService: UpdateService?
    
    init(updateService: UpdateService?) {
        self.updateService = updateService
        super.init()
    }
    
    // Appelé quand une vérification se termine avec succès mais aucune mise à jour trouvée
    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        DispatchQueue.main.async {
            self.updateService?.handleUpdateCycleFinished(error: nil, hasUpdate: false)
        }
    }
    
    // Appelé quand une vérification trouve une mise à jour
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        DispatchQueue.main.async {
            self.updateService?.handleUpdateCycleFinished(error: nil, hasUpdate: true)
        }
    }
    
    // Appelé en cas d'erreur pendant le téléchargement d'une mise à jour
    func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
        DispatchQueue.main.async {
            self.updateService?.handleUpdateCycleFinished(error: error, hasUpdate: false)
        }
    }
    
    // Appelé en cas d'erreur lors de la vérification du feed
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        DispatchQueue.main.async {
            self.updateService?.handleUpdateCycleFinished(error: error, hasUpdate: false)
        }
    }
    
    // Appelé avant qu'une mise à jour soit installée
    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        DispatchQueue.main.async {
            self.updateService?.handleWillInstallUpdate(version: item.versionString)
        }
    }
}

/// **Service central de gestion des mises à jour Optima**
/// 
/// Ce service encapsule toute la logique de mise à jour automatique via Sparkle.
/// Il garantit une expérience utilisateur fluide et une gestion d'erreurs robuste.
/// 
/// **Fonctionnalités principales :**
/// - Vérification automatique au démarrage (configurable)
/// - Vérification manuelle via menu
/// - Gestion des erreurs réseau et serveur
/// - Notifications utilisateur appropriées
/// - Respect des préférences utilisateur
@MainActor
final class UpdateService: ObservableObject {
    
    // MARK: - Configuration
    
    /// Flag pour éviter les logs répétitifs d'initialisation
    private static var hasLoggedInitialization = false
    
    /// Protection contre les vérifications multiples
    private var hasPerformedStartupCheck = false
    private var lastManualCheckTime: Date?
    private var isManualCheck = false
    
    /// Contrôleur Sparkle principal
    private let updaterController: SPUStandardUpdaterController
    
    /// Delegate Sparkle
    private let sparkleDelegate: SparkleUpdateDelegate
    
    /// État de la dernière vérification
    @Published var isCheckingForUpdates = false
    @Published var lastCheckDate: Date?
    @Published var lastError: UpdateError?
    
    // MARK: - Types d'Erreurs
    
    /// Erreurs spécifiques aux mises à jour
    enum UpdateError: LocalizedError {
        case networkUnavailable
        case feedNotFound
        case invalidResponse
        case noUpdatesAvailable
        case downloadFailed
        case installationFailed
        
        var errorDescription: String? {
            switch self {
            case .networkUnavailable:
                return "Impossible de vérifier les mises à jour - pas de connexion internet"
            case .feedNotFound:
                return "Serveur de mises à jour introuvable"
            case .invalidResponse:
                return "Réponse invalide du serveur de mises à jour"
            case .noUpdatesAvailable:
                return "Aucune mise à jour disponible - vous utilisez la dernière version"
            case .downloadFailed:
                return "Échec du téléchargement de la mise à jour"
            case .installationFailed:
                return "Échec de l'installation de la mise à jour"
            }
        }
    }
    
    // MARK: - Initialisation
    
    init() {
        // Initialiser les UserDefaults avec des valeurs par défaut si nécessaire
        Self.initializeUserDefaults()
        
        // Initialiser d'abord les propriétés stockées
        self.sparkleDelegate = SparkleUpdateDelegate(updateService: nil)
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self.sparkleDelegate,
            userDriverDelegate: nil
        )
        
        // Maintenant configurer la référence circulaire
        self.sparkleDelegate.updateService = self
        
        // Configuration des paramètres Sparkle
        configureSparkle()
        
        // Log d'initialisation uniquement la première fois
        if !Self.hasLoggedInitialization {
            print("✅ UpdateService initialisé avec succès")
            Self.hasLoggedInitialization = true
        }
    }
    
    // MARK: - Configuration Privée
    
    /// Initialise les UserDefaults avec des valeurs par défaut appropriées
    private static func initializeUserDefaults() {
        let defaults: [String: Any] = [
            "AutomaticUpdateCheck": true,    // Activé par défaut
            "AutomaticDownload": false       // Désactivé par défaut pour plus de contrôle
        ]
        
        // Ne pas écraser les préférences existantes
        for (key, value) in defaults {
            if UserDefaults.standard.object(forKey: key) == nil {
                UserDefaults.standard.set(value, forKey: key)
            }
        }
        
        UserDefaults.standard.synchronize()
    }
    
    /// Configure les paramètres avancés de Sparkle
    private func configureSparkle() {
        let updater = updaterController.updater
        
        // Le delegate est déjà configuré via le constructeur SPUStandardUpdaterController
        // Pas besoin de le redéfinir ici
        
        // La configuration de l'URL du feed (SUFeedURL) est automatiquement lue
        // depuis le fichier Info.plist par Sparkle. Il n'est pas nécessaire de la définir ici.
        
        // Configuration des vérifications automatiques
        updater.automaticallyChecksForUpdates = UserDefaults.standard.bool(forKey: "AutomaticUpdateCheck")
        
        // Intervalle de vérification (24 heures par défaut)
        updater.updateCheckInterval = 24 * 60 * 60 // 24 heures en secondes
        
        // Téléchargement automatique des mises à jour (optionnel)
        updater.automaticallyDownloadsUpdates = UserDefaults.standard.bool(forKey: "AutomaticDownload")
        
        // Log de configuration uniquement la première fois
        if !Self.hasLoggedInitialization {
            print("🔧 Configuration Sparkle appliquée (URL lue depuis Info.plist)")
            print("   - Vérification auto: \(updater.automaticallyChecksForUpdates)")
            print("   - Téléchargement auto: \(updater.automaticallyDownloadsUpdates)")
        }
    }
    
    // MARK: - Actions Publiques
    
    /// **Vérification manuelle des mises à jour**
    /// 
    /// Cette méthode est appelée depuis le menu "Vérifier les mises à jour"
    /// Elle fournit un feedback immédiat à l'utilisateur
    func checkForUpdatesManually() {
        // Protection contre les appels trop fréquents (minimum 10 secondes)
        if let lastCheck = lastManualCheckTime, 
           Date().timeIntervalSince(lastCheck) < 10 {
            print("⚠️ Vérification trop récente, ignorée (attendez 10 secondes)")
            return
        }
        
        // Éviter les vérifications multiples simultanées
        guard !isCheckingForUpdates else {
            print("⚠️ Vérification déjà en cours, ignorée")
            return
        }
        
        isCheckingForUpdates = true
        isManualCheck = true
        lastError = nil
        lastManualCheckTime = Date()
        
        print("🔍 Vérification manuelle des mises à jour démarrée...")
        
        // Utiliser l'API Sparkle standard
        let updater = updaterController.updater
        updater.checkForUpdates()
        
        // Réinitialisation de l'état après un délai (backup)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self.isCheckingForUpdates {
                self.isCheckingForUpdates = false
                self.isManualCheck = false
                self.lastCheckDate = Date()
            }
        }
    }
    
    /// **Vérification automatique silencieuse au démarrage**
    /// 
    /// Cette méthode est appelée UNE SEULE FOIS au démarrage de l'application
    /// Elle ne dérange pas l'utilisateur sauf si une mise à jour est trouvée
    func checkForUpdatesAutomaticallyOnStartup() {
        // Protection : ne faire qu'une seule vérification au démarrage
        guard !hasPerformedStartupCheck else {
            print("✅ Vérification de démarrage déjà effectuée, ignorée")
            return
        }
        
        let updater = updaterController.updater
        
        // Respecter les préférences utilisateur
        guard updater.automaticallyChecksForUpdates else {
            print("📱 Vérification automatique désactivée par l'utilisateur")
            hasPerformedStartupCheck = true
            return
        }
        
        print("🔄 Vérification automatique unique des mises à jour au démarrage...")
        
        // Marquer comme effectuée AVANT l'appel pour éviter les doublons
        hasPerformedStartupCheck = true
        isManualCheck = false
        
        // Vérification silencieuse en arrière-plan
        updater.checkForUpdatesInBackground()
        lastCheckDate = Date()
    }
    
    /// **Vérification automatique périodique (appelée par Sparkle)**
    /// 
    /// Cette méthode peut être appelée périodiquement par Sparkle selon la configuration
    /// Elle est silencieuse et respecte l'intervalle configuré
    func checkForUpdatesAutomatically() {
        let updater = updaterController.updater
        
        // Respecter les préférences utilisateur
        guard updater.automaticallyChecksForUpdates else {
            return
        }
        
        print("🔄 Vérification automatique périodique des mises à jour...")
        
        isManualCheck = false
        
        // Vérification silencieuse
        updater.checkForUpdatesInBackground()
        lastCheckDate = Date()
    }
    
    /// **Met à jour les préférences de mise à jour**
    /// 
    /// Appelé depuis la fenêtre des préférences
    func updatePreferences(automaticCheck: Bool, automaticDownload: Bool) {
        let updater = updaterController.updater
        
        // Sauvegarde des préférences
        UserDefaults.standard.set(automaticCheck, forKey: "AutomaticUpdateCheck")
        UserDefaults.standard.set(automaticDownload, forKey: "AutomaticDownload")
        
        // Application immédiate
        updater.automaticallyChecksForUpdates = automaticCheck
        updater.automaticallyDownloadsUpdates = automaticDownload
        
        print("⚙️ Préférences mises à jour:")
        print("   - Vérification auto: \(automaticCheck)")
        print("   - Téléchargement auto: \(automaticDownload)")
    }
    
    // MARK: - Gestion des Callbacks Sparkle
    
    /// Appelé par le delegate quand une vérification de mise à jour se termine
    func handleUpdateCycleFinished(error: Error?, hasUpdate: Bool) {
        self.isCheckingForUpdates = false
        self.lastCheckDate = Date()
        
        if let error = error {
            self.handleSparkleError(error, isManual: self.isManualCheck)
        } else {
            // Vérification terminée avec succès
            self.lastError = nil
            
            // Si c'était une vérification manuelle et qu'aucune mise à jour n'a été trouvée,
            // afficher un message informatif
            if self.isManualCheck && !hasUpdate {
                self.showNoUpdateAlert()
            }
            
            // Log du résultat
            if hasUpdate {
                print("✅ Mise à jour disponible trouvée")
            } else {
                print("✅ Aucune mise à jour - application à jour")
            }
        }
        
        self.isManualCheck = false
    }
    
    /// Appelé par le delegate avant qu'une mise à jour soit installée
    func handleWillInstallUpdate(version: String) {
        print("📦 Installation de la mise à jour: \(version)")
    }
    
    // MARK: - Gestion des Résultats
    
    /// Gère les erreurs génériques lors des opérations de mise à jour
    private func handleSparkleError(_ error: Error, isManual: Bool) {
        let updateError: UpdateError
        
        // Log détaillé de l'erreur pour le débogage
        let nsError = error as NSError
        print("❌ Erreur Sparkle détaillée:")
        print("   - Domain: \(nsError.domain)")
        print("   - Code: \(nsError.code)")
        print("   - Description: \(nsError.localizedDescription)")
        print("   - UserInfo: \(nsError.userInfo)")
        
        // Conversion des erreurs courantes en erreurs métier
        switch nsError.domain {
        case NSURLErrorDomain:
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                updateError = .networkUnavailable
            case NSURLErrorFileDoesNotExist, NSURLErrorResourceUnavailable:
                updateError = .feedNotFound
            case NSURLErrorBadURL, NSURLErrorUnsupportedURL:
                updateError = .invalidResponse
            case NSURLErrorServerCertificateHasBadDate, NSURLErrorServerCertificateUntrusted:
                updateError = .feedNotFound
            default:
                updateError = .invalidResponse
            }
        case "SUError":
            // Erreurs spécifiques à Sparkle
            switch nsError.code {
            case 1000: // SUNoUpdateError
                updateError = .noUpdatesAvailable
            case 2000: // SUInstallationError
                updateError = .installationFailed
            default:
                updateError = .invalidResponse
            }
        default:
            updateError = .invalidResponse
        }
        
        handleError(updateError, showAlert: isManual)
    }
    
    /// Gère une erreur de mise à jour
    private func handleError(_ error: UpdateError, showAlert: Bool = false) {
        lastError = error
        
        print("❌ Erreur de mise à jour: \(error.localizedDescription)")
        
        if showAlert {
            Task { @MainActor in
                self.showErrorAlert(error)
            }
        }
    }
    
    // MARK: - Interface Utilisateur
    
    /// Affiche une alerte "Aucune mise à jour"
    private func showNoUpdateAlert() {
        let alert = NSAlert()
        alert.messageText = "Optima est à jour"
        alert.informativeText = "Vous utilisez déjà la dernière version d'Optima."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        if let window = NSApplication.shared.keyWindow {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
    
    /// Affiche une alerte d'erreur
    private func showErrorAlert(_ error: UpdateError) {
        let alert = NSAlert()
        alert.messageText = "Erreur de mise à jour"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        
        // Bouton "Réessayer" pour certaines erreurs
        if case .networkUnavailable = error {
            alert.addButton(withTitle: "Réessayer")
        }
        
        let response = alert.runModal()
        
        // Gérer la réponse "Réessayer"
        if response == .alertSecondButtonReturn {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkForUpdatesManually()
            }
        }
    }
    
    // MARK: - Utilitaires
    
    /// Réinitialise les protections (pour les tests ou le débogage)
    func resetUpdateProtections() {
        hasPerformedStartupCheck = false
        lastManualCheckTime = nil
        isCheckingForUpdates = false
        isManualCheck = false
        print("🔄 Protections de mise à jour réinitialisées")
    }
    
    /// Formate la dernière date de vérification
    var lastCheckFormatted: String {
        guard let lastCheckDate = lastCheckDate else {
            return "Jamais"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        
        return formatter.string(from: lastCheckDate)
    }
    
    /// Retourne l'état actuel des mises à jour
    var currentStatus: String {
        if isCheckingForUpdates {
            return "Vérification en cours..."
        } else if let error = lastError {
            return "Erreur: \(error.localizedDescription)"
        } else {
            return "Dernière vérification: \(lastCheckFormatted)"
        }
    }
    
    /// Retourne les informations de debug
    var debugInfo: String {
        let updater = updaterController.updater
        let feedURL = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String ?? "Non configurée"
        let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? "Non configurée"
        
        return """
        État UpdateService:
        - Startup check effectué: \(hasPerformedStartupCheck)
        - Vérification en cours: \(isCheckingForUpdates)
        - Vérification manuelle: \(isManualCheck)
        - Dernière vérification manuelle: \(lastManualCheckTime?.description ?? "Jamais")
        - Dernière vérification: \(lastCheckFormatted)
        
        Configuration Sparkle:
        - Feed URL: \(feedURL)
        - Clé publique: \(publicKey)
        - Vérification auto: \(updater.automaticallyChecksForUpdates)
        - Téléchargement auto: \(updater.automaticallyDownloadsUpdates)
        """
    }
    
    /// Teste la configuration Sparkle et la connectivité
    func testSparkleConfiguration() {
        print("🔧 Test de la configuration Sparkle...")
        
        let feedURL = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String ?? "Non configurée"
        let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? "Non configurée"
        
        print("   - Feed URL: \(feedURL)")
        print("   - Clé publique: \(publicKey)")
        
        // Test de connectivité basique
        if let url = URL(string: feedURL) {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Erreur de connectivité: \(error.localizedDescription)")
                    } else if let httpResponse = response as? HTTPURLResponse {
                        print("✅ Connectivité OK - Status: \(httpResponse.statusCode)")
                        if let data = data {
                            print("   - Taille des données: \(data.count) bytes")
                        }
                    }
                }
            }
            task.resume()
        }
    }
} 