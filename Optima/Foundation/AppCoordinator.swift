//
//  AppCoordinator.swift
//  Foundation
//
//  Coordinateur central de l'application Optima
//  Gère l'état global et orchestre les interactions entre modules
//

import SwiftUI
import Combine
import Sparkle

/// Coordinateur principal qui orchestre l'ensemble de l'application
/// Responsabilité : État global, navigation, communication inter-modules
@MainActor
final class AppCoordinator: ObservableObject {
    
    // MARK: - État de Navigation
    @Published var selectedView: MainView = .library
    @Published var selectedDocument: DocumentModel?
    @Published var showingImportSheet = false
    @Published var showingAIAssistant = false
    @Published var showingAIConfiguration = false
    @Published var showingSettings = false
    
    // MARK: - État Application
    @Published var isInitialized = false
    @Published var currentUser: UserProfile?
    
    // MARK: - Services Centraux
    private let documentService = DocumentService()
    private let persistenceService = PersistenceService()
    let aiService = AIService() // Public pour accès depuis les vues
    let analyticsService = AnalyticsService() // Public pour accès depuis les vues
    
    // Contrôleur de mise à jour Sparkle
    private let updaterController: SPUStandardUpdaterController
    
    /// Objet `updater` exposé pour les vues SwiftUI
    var updater: SPUUpdater {
        updaterController.updater
    }
    
    // MARK: - Données Applicatives
    @Published var documents: [DocumentModel] = []
    @Published var isProcessingDocument = false
    
    init() {
        // Initialisation du contrôleur de mise à jour Sparkle
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        Task {
            await setupApplication()
        }
    }
    
    // MARK: - Configuration Initiale
    private func setupApplication() async {
        // Chargement initial des documents sauvegardés
        await loadExistingDocuments()
        
        // Chargement des données pour les analytics
        await loadAnalyticsData()
        
        // TODO: Chargement des préférences utilisateur
        // TODO: Configuration analytics
        
        await MainActor.run {
            isInitialized = true
        }
    }
    
    // MARK: - Actions Navigation
    func navigateTo(_ view: MainView) {
        // 🔑 CORRECTION : Fermer automatiquement l'assistant IA si on quitte la vue Lecteur.
        // Cela garantit que l'assistant, qui est contextuel au document,
        // ne reste pas ouvert de manière incohérente dans d'autres vues.
        if selectedView == .reader && view != .reader {
            showingAIAssistant = false
        }
        
        selectedView = view
    }
    
    func selectDocument(_ document: DocumentModel) {
        selectedDocument = document
        navigateTo(.reader)
    }
    
    // MARK: - Actions Application
    func showImportSheet() {
        // 🔑 CORRECTION : Navigation automatique vers la bibliothèque + ouverture sheet
        navigateTo(.library)
        // Petit délai pour permettre à la vue de se charger avant d'ouvrir la sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showingImportSheet = true
        }
    }
    
    func hideImportSheet() {
        showingImportSheet = false
    }
    
    func toggleAIAssistant() {
        showingAIAssistant.toggle()
    }
    
    /// 🔑 CORRECTION SIMPLIFIÉE : Ouvre toujours l'assistant IA global
    /// L'assistant gère lui-même la logique conditionnelle (API configurée ou non)
    func openAIAssistant() {
        // Toujours ouvrir l'assistant - il s'adapte automatiquement au contexte
        showingAIAssistant = true
    }
    
    /// 🔑 CORRECTION SIMPLIFIÉE : Toggle simple de l'assistant IA global
    func smartToggleAIAssistant() {
        if showingAIAssistant {
            // Si l'assistant est ouvert → le fermer
            showingAIAssistant = false
        } else if showingAIConfiguration {
            // Si la configuration est ouverte → la fermer et ouvrir l'assistant
            showingAIConfiguration = false
            showingAIAssistant = true
        } else {
            // Sinon → ouvrir l'assistant
            showingAIAssistant = true
        }
    }
    
    func showAIConfiguration() {
        showingAIConfiguration = true
    }
    
    // MARK: - Gestion des Documents
    
    /// Met à jour un document et sauvegarde les changements
    func updateAndSaveDocument(_ document: DocumentModel) async {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index] = document
            await saveDocuments()
        }
    }
    
    func importDocument(from url: URL) async throws {
        isProcessingDocument = true
        defer { isProcessingDocument = false }
        
        let document = try await documentService.importDocument(from: url)
        documents.append(document)
        
        // 🔑 CORRECTION : Sauvegarde immédiate après import
        await saveDocuments()
        
        hideImportSheet()
    }
    
    func loadExistingDocuments() async {
        do {
            // 🔑 CORRECTION : Chargement réel des documents sauvegardés
            let savedDocuments = try await persistenceService.loadDocuments()
            
            await MainActor.run {
                self.documents = savedDocuments
                print("✅ Chargé \(savedDocuments.count) documents sauvegardés")
            }
        } catch {
            print("⚠️ Erreur chargement documents: \(error)")
            // En cas d'erreur, on garde une liste vide
            await MainActor.run {
                self.documents = []
            }
        }
    }
    
    func loadAnalyticsData() async {
        do {
            let sessions = try await persistenceService.loadStudySessions()
            analyticsService.process(sessions: sessions)
            print("✅ Chargé et traité \(sessions.count) sessions d'étude pour les analytics.")
        } catch {
            print("⚠️ Erreur chargement des sessions d'étude: \(error)")
        }
    }
    
    // MARK: - Sauvegarde Privée
    
    /// Sauvegarde tous les documents sur disque
    private func saveDocuments() async {
        do {
            try await persistenceService.saveDocuments(documents)
            print("✅ Documents sauvegardés avec succès (\(documents.count) items)")
        } catch {
            print("❌ Erreur sauvegarde documents: \(error)")
        }
    }
    
    /// Sauvegarde forcée (appelable depuis l'extérieur)
    func saveAllDocuments() async {
        await saveDocuments()
    }
    
    /// Sauvegarde une nouvelle session d'étude
    func saveStudySession(_ session: StudySession) async {
        do {
            try await persistenceService.appendStudySession(session)
            print("✅ Session d'étude sauvegardée.")
            // Recharger les données pour mettre à jour les graphiques
            await loadAnalyticsData()
        } catch {
            print("❌ Erreur sauvegarde session d'étude: \(error)")
        }
    }
    
    // MARK: - Gestion du Cycle de Vie Application
    
    /// Appelé lors de la fermeture de l'application
    func applicationWillTerminate() async {
        print("🔄 Sauvegarde avant fermeture...")
        await saveDocuments()
    }
    
    // MARK: - Nouvelles Actions Menu
    
    /// Démarre une nouvelle session d'étude
    func startNewStudySession() {
        // Navigation vers la vue Étude
        navigateTo(.study)
        
        // Si un document est sélectionné, ouvrir l'assistant IA après un court délai
        if selectedDocument != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.showingAIAssistant = true
            }
        }
    }
    
    /// Affiche l'assistant IA
    func showAIAssistant() {
        showingAIAssistant = true
    }
    
    /// Affiche la fenêtre de préférences
    func showPreferences() {
        showingSettings = true
        print("🔧 Ouverture de la fenêtre Préférences manuelle")
    }
    
    /// Ouvre le guide utilisateur
    func openUserGuide() {
        // Ouvrir une page web d'aide
        if let url = URL(string: "https://github.com/optima-app/guide") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Vérifie les mises à jour manuellement
    func checkForUpdates() {
        // La nouvelle vue de menu appelle directement l'action de l'updater.
        // On peut garder cette fonction pour des appels programmatiques si besoin.
        updaterController.checkForUpdates(nil)
    }
    
    /// Affiche les raccourcis clavier
    func showKeyboardShortcuts() {
        // TODO: Créer une fenêtre dédiée aux raccourcis
        print("📋 Raccourcis clavier d'Optima")
        print("⌘I - Importer un document")
        print("⌘R - Nouvelle session d'étude")
        print("⌘⇧A - Assistant IA")
        print("⌘⇧S - Statistiques")
        print("⌘1-4 - Navigation rapide")
        print("⌘U - Vérifier les mises à jour")
        print("⌘? - Ce guide")
    }
    

}

// MARK: - Types Navigation
enum MainView: String, CaseIterable, Identifiable {
    case library = "Bibliothèque"
    case reader = "Lecteur"
    case generation = "Génération"
    case study = "Étude"
    case analytics = "Analytics"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .library: return "books.vertical"
        case .reader: return "doc.text"
        case .generation: return "wand.and.stars"
        case .study: return "brain.head.profile"
        case .analytics: return "chart.line.uptrend.xyaxis"
        }
    }
} 