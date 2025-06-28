//
//  DataManager.swift
//  Foundation/Services
//
//  Gestionnaire central des données d'Optima
//  Coordination entre persistance, PDF et services IA
//

import Foundation
import SwiftUI

/// Gestionnaire central des données de l'application
/// Responsabilité : Coordination des services, cache intelligent, synchronisation
@MainActor
final class DataManager: ObservableObject {
    
    // MARK: - État Observable
    @Published var documents: [DocumentModel] = []
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0.0
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let persistenceService = PersistenceService()
    private let pdfProcessingService = PDFProcessingService()
    private let documentService = DocumentService()
    
    // MARK: - Cache et Performance
    private var documentCache: [UUID: DocumentModel] = [:]
    private var processingQueue = TaskQueue()
    
    // MARK: - Initialisation
    init() {
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Gestion des Documents
    
    /// Importe un nouveau document PDF
    func importDocument(from url: URL) async throws -> DocumentModel {
        isLoading = true
        loadingProgress = 0.0
        errorMessage = nil
        
        defer { 
            isLoading = false
            loadingProgress = 1.0
        }
        
        do {
            // Étape 1: Validation et copie (20%)
            loadingProgress = 0.2
            let document = try await documentService.importDocument(from: url)
            
            // Étape 2: Traitement PDF (60%)
            loadingProgress = 0.6
            let enhancedDocument = try await enhanceDocumentWithPDFInfo(document)
            
            // Étape 3: Sauvegarde (20%)
            loadingProgress = 0.8
            try await saveDocument(enhancedDocument)
            
            // Mise à jour de l'état
            documents.append(enhancedDocument)
            documentCache[enhancedDocument.id] = enhancedDocument
            loadingProgress = 1.0
            
            return enhancedDocument
            
        } catch {
            errorMessage = "Erreur d'import: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Récupère un document par ID
    func getDocument(by id: UUID) -> DocumentModel? {
        return documentCache[id] ?? documents.first { $0.id == id }
    }
    
    /// Met à jour un document existant
    func updateDocument(_ document: DocumentModel) async throws {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index] = document
            documentCache[document.id] = document
            
            try await saveDocument(document)
        }
    }
    
    /// Supprime un document
    func deleteDocument(_ document: DocumentModel) async throws {
        try await documentService.deleteDocument(document)
        
        documents.removeAll { $0.id == document.id }
        documentCache.removeValue(forKey: document.id)
    }
    
    /// Recherche intelligente dans les documents
    func searchDocuments(query: String) -> [DocumentModel] {
        return documentService.searchDocuments(query: query)
    }
    
    // MARK: - Chargement Initial
    
    private func loadInitialData() async {
        do {
            isLoading = true
            
            // Chargement des documents existants
            let savedDocuments = try await persistenceService.loadDocuments()
            
            await MainActor.run {
                self.documents = savedDocuments
                // Construction du cache
                for document in savedDocuments {
                    self.documentCache[document.id] = document
                }
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Erreur de chargement: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Amélioration PDF
    
    private func enhanceDocumentWithPDFInfo(_ document: DocumentModel) async throws -> DocumentModel {
        var enhancedDocument = document
        
        do {
            let pdfInfo = try await pdfProcessingService.processDocument(at: document.url)
            
            // Enrichissement avec les données PDF
            enhancedDocument.pageCount = pdfInfo.pageCount
            enhancedDocument.textContent = pdfInfo.extractedText
            enhancedDocument.extractedTopics = pdfInfo.topics
            enhancedDocument.difficulty = pdfInfo.structure.difficulty
            enhancedDocument.dateModified = Date()
            
            // Estimation du temps de lecture
            enhancedDocument.estimatedReadingTime = pdfInfo.structure.estimatedReadingTime
            
            return enhancedDocument
            
        } catch {
            // Si le traitement PDF échoue, on garde le document de base
            print("Avertissement: Traitement PDF échoué pour \(document.title): \(error)")
            return enhancedDocument
        }
    }
    
    // MARK: - Sauvegarde
    
    private func saveDocument(_ document: DocumentModel) async throws {
        try await persistenceService.saveDocuments(documents)
    }
    
    private func saveAllDocuments() async throws {
        try await persistenceService.saveDocuments(documents)
    }
    
    // MARK: - Analytics et Statistiques
    
    var totalDocuments: Int {
        documents.count
    }
    
    var totalPages: Int {
        documents.reduce(0) { $0 + $1.pageCount }
    }
    
    var completedDocuments: Int {
        documents.filter { $0.studyProgress.isCompleted }.count
    }
    
    var averageProgress: Double {
        guard !documents.isEmpty else { return 0.0 }
        let totalProgress = documents.reduce(0.0) { $0 + $1.studyProgress.completionPercentage }
        return totalProgress / Double(documents.count)
    }
    
    // MARK: - Nettoyage et Maintenance
    
    /// Nettoie les fichiers orphelins et optimise le stockage
    func performMaintenance() async throws {
        // TODO: Implémentation du nettoyage automatique
        // - Suppression des fichiers PDF orphelins
        // - Optimisation du cache
        // - Compression des anciennes données
    }
    
    /// Sauvegarde tous les changements en attente
    func saveAllPendingChanges() async throws {
        try await saveAllDocuments()
    }
}

// MARK: - Extensions DocumentModel

private extension DocumentModel {
    var estimatedReadingTime: TimeInterval {
        get {
            // Stockage temporaire dans timeSpent pour Phase 2
            return timeSpent
        }
        set {
            // Simulation pour Phase 2
        }
    }
}

// MARK: - Queue de Traitement

/// Queue de tâches pour le traitement asynchrone
private actor TaskQueue {
    private var tasks: [Task<Void, Never>] = []
    
    func add<T>(_ operation: @escaping () async throws -> T) async -> T? {
        let task = Task<T?, Never> {
            do {
                return try await operation()
            } catch {
                print("Erreur dans la queue: \(error)")
                return nil
            }
        }
        
        tasks.append(Task { _ = await task.value })
        return await task.value
    }
    
    func waitForAll() async {
        for task in tasks {
            await task.value
        }
        tasks.removeAll()
    }
} 