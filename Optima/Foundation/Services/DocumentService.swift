//
//  DocumentService.swift
//  Foundation/Services
//
//  Service de gestion des documents PDF
//  Import, stockage, métadonnées et organisation intelligente
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Service central pour la gestion des documents
/// Responsabilité : CRUD documents, import/export, métadonnées, stockage
@MainActor
final class DocumentService: ObservableObject {
    
    // MARK: - État Publique
    @Published var documents: [DocumentModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Configuration Stockage
    private let documentsDirectory: URL
    private let metadataDirectory: URL
    
    // MARK: - Services Collaborateurs
    private let persistenceService = PersistenceService()
    private let pdfProcessingService = PDFProcessingService()
    
    // MARK: - Initialisation
    init() {
        // Configuration des répertoires de stockage
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                 in: .userDomainMask).first!
        let optiMaDirectory = appSupport.appendingPathComponent("Optima")
        
        self.documentsDirectory = optiMaDirectory.appendingPathComponent("Documents")
        self.metadataDirectory = optiMaDirectory.appendingPathComponent("Metadata")
        
        setupDirectories()
        loadDocuments()
    }
    
    // MARK: - Gestion Documents
    
    /// Importe un nouveau document PDF
    func importDocument(from url: URL) async throws -> DocumentModel {
        isLoading = true
        defer { isLoading = false }
        
        // Validation du fichier
        guard url.pathExtension.lowercased() == "pdf" else {
            throw DocumentError.invalidFileType
        }
        
        // Copie sécurisée du fichier
        let fileName = generateUniqueFileName(from: url.lastPathComponent)
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)
        
        try FileManager.default.copyItem(at: url, to: destinationURL)
        
        // Création du modèle document
        var document = DocumentModel(
            url: destinationURL,
            title: extractTitle(from: url.lastPathComponent)
        )
        
        // Traitement asynchrone du PDF
        do {
            let pdfInfo = try await pdfProcessingService.processDocument(at: destinationURL)
            document.pageCount = pdfInfo.pageCount
            document.textContent = pdfInfo.extractedText
            document.extractedTopics = pdfInfo.topics
        } catch {
            // Le document est ajouté même si le traitement échoue
            print("Erreur traitement PDF: \(error)")
        }
        
        // Sauvegarde
        documents.append(document)
        try await saveDocuments()
        
        return document
    }
    
    /// Supprime un document
    func deleteDocument(_ document: DocumentModel) async throws {
        // Suppression du fichier
        try FileManager.default.removeItem(at: document.url)
        
        // Suppression des métadonnées
        documents.removeAll { $0.id == document.id }
        
        try await saveDocuments()
    }
    
    /// Met à jour un document
    func updateDocument(_ document: DocumentModel) async throws {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index] = document
            try await saveDocuments()
        }
    }
    
    /// Recherche dans les documents
    func searchDocuments(query: String) -> [DocumentModel] {
        guard !query.isEmpty else { return documents }
        
        return documents.filter { document in
            document.title.localizedCaseInsensitiveContains(query) ||
            document.subject?.localizedCaseInsensitiveContains(query) == true ||
            document.extractedTopics.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    // MARK: - Configuration Privée
    
    private func setupDirectories() {
        let directories = [documentsDirectory, metadataDirectory]
        
        for directory in directories {
            if !FileManager.default.fileExists(atPath: directory.path) {
                try? FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
            }
        }
    }
    
    private func loadDocuments() {
        Task {
            do {
                documents = try await persistenceService.loadDocuments()
            } catch {
                errorMessage = "Erreur chargement documents: \(error.localizedDescription)"
            }
        }
    }
    
    private func saveDocuments() async throws {
        try await persistenceService.saveDocuments(documents)
    }
    
    private func generateUniqueFileName(from originalName: String) -> String {
        let baseName = originalName.deletingPathExtension
        let timestamp = Int(Date().timeIntervalSince1970)
        return "\(baseName)_\(timestamp).pdf"
    }
    
    private func extractTitle(from fileName: String) -> String {
        let baseName = fileName.deletingPathExtension
        
        // Nettoyage basique du nom de fichier
        return baseName
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Erreurs
enum DocumentError: LocalizedError {
    case invalidFileType
    case importFailed(String)
    case processingFailed(String)
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFileType:
            return "Type de fichier non supporté. Seuls les PDFs sont acceptés."
        case .importFailed(let message):
            return "Échec d'import: \(message)"
        case .processingFailed(let message):
            return "Échec de traitement: \(message)"
        case .saveFailed(let message):
            return "Échec de sauvegarde: \(message)"
        }
    }
}

// MARK: - Extensions
private extension String {
    var deletingPathExtension: String {
        (self as NSString).deletingPathExtension
    }
} 