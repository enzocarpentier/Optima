//
//  DocumentModel.swift
//  ContentManagement/Models
//
//  Modèle de données pour les documents PDF de cours
//  Représente un cours importé avec ses métadonnées et état
//

import SwiftUI
import Foundation

/// Modèle représentant un document de cours (PDF)
/// Responsabilité : Structure de données, métadonnées, état du document
struct DocumentModel: Identifiable, Codable {
    
    // MARK: - Identité
    var id = UUID()
    let url: URL
    
    // MARK: - Métadonnées Essentielles
    var title: String
    var subject: String?
    var author: String?
    var dateAdded: Date
    var dateModified: Date
    
    // MARK: - Contenu et Structure
    var pageCount: Int
    var textContent: String?
    var extractedTopics: [String]
    var difficulty: DifficultyLevel
    
    // MARK: - État d'Apprentissage
    var studyProgress: StudyProgress
    var bookmarks: [Bookmark]
    var generatedContent: [GeneratedContentItem]
    
    // MARK: - Statistiques
    var timeSpent: TimeInterval
    var lastAccessed: Date?
    var studySessions: [StudySession]
    
    // MARK: - Initialisation
    init(url: URL, title: String) {
        self.url = url
        self.title = title
        self.dateAdded = Date()
        self.dateModified = Date()
        self.pageCount = 0
        self.extractedTopics = []
        self.difficulty = .intermediate
        self.studyProgress = StudyProgress()
        self.bookmarks = []
        self.generatedContent = []
        self.timeSpent = 0
        self.studySessions = []
    }
}

// MARK: - Types Associés
enum DifficultyLevel: String, CaseIterable, Codable {
    case beginner = "Débutant"
    case intermediate = "Intermédiaire"
    case advanced = "Avancé"
    case expert = "Expert"
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .orange
        case .expert: return .red
        }
    }
}

/// Progression d'étude d'un document
struct StudyProgress: Codable {
    var completionPercentage: Double = 0.0
    var pagesRead: Set<Int> = []
    var conceptsMastered: Set<String> = []
    var weakAreas: Set<String> = []
    
    var isCompleted: Bool {
        completionPercentage >= 1.0
    }
}

/// Marque-page dans un document
struct Bookmark: Identifiable, Codable {
    var id = UUID()
    let pageNumber: Int
    let title: String
    let note: String?
    let dateCreated: Date
    
    init(pageNumber: Int, title: String, note: String? = nil) {
        self.pageNumber = pageNumber
        self.title = title
        self.note = note
        self.dateCreated = Date()
    }
} 