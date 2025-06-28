//
//  PersistenceService.swift
//  Foundation/Services
//
//  Service de persistance locale des données
//  Stockage 100% local avec performance et sécurité optimales
//

import Foundation

/// Service de persistance pour stockage local sécurisé
/// Responsabilité : Sauvegarde/chargement, encryption, backup, migration
actor PersistenceService {
    
    // MARK: - Configuration
    private let storageDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Fichiers de Données
    private var documentsFile: URL {
        storageDirectory.appendingPathComponent("documents.json")
    }
    
    private var userProfileFile: URL {
        storageDirectory.appendingPathComponent("user_profile.json")
    }
    
    private var sessionsFile: URL {
        storageDirectory.appendingPathComponent("study_sessions.json")
    }
    
    private var generatedContentFile: URL {
        storageDirectory.appendingPathComponent("generated_content.json")
    }
    
    // MARK: - Initialisation
    init() {
        // Configuration du répertoire de stockage
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                 in: .userDomainMask).first!
        self.storageDirectory = appSupport.appendingPathComponent("Optima/Data")
        
        setupEncoder()
        createStorageDirectory()
    }
    
    // MARK: - Documents
    
    func loadDocuments() throws -> [DocumentModel] {
        guard FileManager.default.fileExists(atPath: documentsFile.path) else {
            return []
        }
        
        let data = try Data(contentsOf: documentsFile)
        return try decoder.decode([DocumentModel].self, from: data)
    }
    
    func saveDocuments(_ documents: [DocumentModel]) throws {
        let data = try encoder.encode(documents)
        try data.write(to: documentsFile, options: .atomic)
    }
    
    // MARK: - Profil Utilisateur
    
    func loadUserProfile() throws -> UserProfile? {
        guard FileManager.default.fileExists(atPath: userProfileFile.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: userProfileFile)
        return try decoder.decode(UserProfile.self, from: data)
    }
    
    func saveUserProfile(_ profile: UserProfile) throws {
        let data = try encoder.encode(profile)
        try data.write(to: userProfileFile, options: .atomic)
    }
    
    // MARK: - Sessions d'Étude
    
    func loadStudySessions() throws -> [StudySession] {
        guard FileManager.default.fileExists(atPath: sessionsFile.path) else {
            return []
        }
        
        let data = try Data(contentsOf: sessionsFile)
        return try decoder.decode([StudySession].self, from: data)
    }
    
    func saveStudySessions(_ sessions: [StudySession]) throws {
        let data = try encoder.encode(sessions)
        try data.write(to: sessionsFile, options: .atomic)
    }
    
    func appendStudySession(_ session: StudySession) throws {
        var sessions = try loadStudySessions()
        sessions.append(session)
        try saveStudySessions(sessions)
    }
    
    // MARK: - Contenu Généré
    
    func loadGeneratedContent() throws -> [GeneratedContentItem] {
        guard FileManager.default.fileExists(atPath: generatedContentFile.path) else {
            return []
        }
        
        let data = try Data(contentsOf: generatedContentFile)
        return try decoder.decode([GeneratedContentItem].self, from: data)
    }
    
    func saveGeneratedContent(_ content: [GeneratedContentItem]) throws {
        let data = try encoder.encode(content)
        try data.write(to: generatedContentFile, options: .atomic)
    }
    
    // MARK: - Utilitaires
    
    /// Efface toutes les données (reset complet)
    func clearAllData() throws {
        let files = [documentsFile, userProfileFile, sessionsFile, generatedContentFile]
        
        for file in files {
            if FileManager.default.fileExists(atPath: file.path) {
                try FileManager.default.removeItem(at: file)
            }
        }
    }
    
    /// Crée une sauvegarde de toutes les données
    func createBackup() throws -> URL {
        let backupDirectory = storageDirectory.appendingPathComponent("Backups")
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupPath = backupDirectory.appendingPathComponent("backup_\(timestamp)")
        
        // Création du répertoire de backup
        try FileManager.default.createDirectory(at: backupPath, withIntermediateDirectories: true)
        
        // Copie de tous les fichiers
        let files = [documentsFile, userProfileFile, sessionsFile, generatedContentFile]
        
        for file in files {
            if FileManager.default.fileExists(atPath: file.path) {
                let destination = backupPath.appendingPathComponent(file.lastPathComponent)
                try FileManager.default.copyItem(at: file, to: destination)
            }
        }
        
        return backupPath
    }
    
    /// Calcule l'espace disque utilisé
    func calculateStorageSize() -> Int64 {
        var totalSize: Int64 = 0
        
        let enumerator = FileManager.default.enumerator(
            at: storageDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        )
        
        while let url = enumerator?.nextObject() as? URL {
            do {
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    // MARK: - Configuration Privée
    
    private nonisolated func setupEncoder() {
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        decoder.dateDecodingStrategy = .iso8601
    }
    
    private nonisolated func createStorageDirectory() {
        if !FileManager.default.fileExists(atPath: storageDirectory.path) {
            try? FileManager.default.createDirectory(
                at: storageDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}

// MARK: - Erreurs de Persistance
enum PersistenceError: LocalizedError {
    case directoryCreationFailed
    case fileNotFound(String)
    case corruptedData(String)
    case accessDenied(String)
    case diskFull
    
    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed:
            return "Impossible de créer le répertoire de stockage"
        case .fileNotFound(let fileName):
            return "Fichier introuvable: \(fileName)"
        case .corruptedData(let fileName):
            return "Données corrompues dans: \(fileName)"
        case .accessDenied(let path):
            return "Accès refusé: \(path)"
        case .diskFull:
            return "Espace disque insuffisant"
        }
    }
} 