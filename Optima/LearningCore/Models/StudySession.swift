//
//  StudySession.swift
//  LearningCore/Models
//
//  Modèle pour les sessions d'étude et analytics d'apprentissage
//  Suivi granulaire de l'activité et performance d'apprentissage
//

import Foundation

/// Session d'étude individuelle
/// Responsabilité : Enregistrement détaillé d'une session d'apprentage
struct StudySession: Identifiable, Codable {
    
    // MARK: - Identité et Timing
    var id = UUID()
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval {
        endTime?.timeIntervalSince(startTime) ?? Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Contexte Session
    let documentID: UUID
    let sessionType: SessionType
    let contentIDs: [UUID] // Quiz, flashcards utilisées
    
    // MARK: - Performance et Résultats
    var activitiesCompleted: [ActivityResult]
    var overallScore: Double?
    var conceptsStudied: Set<String>
    var difficultiesEncountered: [StudyDifficulty]
    
    // MARK: - Métadonnées Comportementales
    var focusInterruptions: Int = 0
    var pauseDuration: TimeInterval = 0
    var devicesSwitched: Int = 0
    
    // MARK: - Auto-évaluation
    var userRating: SessionRating?
    var userNotes: String?
    
    init(documentID: UUID, sessionType: SessionType) {
        self.documentID = documentID
        self.sessionType = sessionType
        self.contentIDs = []
        self.activitiesCompleted = []
        self.conceptsStudied = []
        self.difficultiesEncountered = []
        self.startTime = Date()
    }
    
    init(documentID: UUID, sessionType: SessionType, startTime: Date) {
        self.documentID = documentID
        self.sessionType = sessionType
        self.contentIDs = []
        self.activitiesCompleted = []
        self.conceptsStudied = []
        self.difficultiesEncountered = []
        self.startTime = startTime
    }
    
    // MARK: - Session Management
    mutating func endSession() {
        endTime = Date()
    }
    
    mutating func addActivity(_ result: ActivityResult) {
        activitiesCompleted.append(result)
        conceptsStudied.formUnion(result.conceptsCovered)
        updateOverallScore()
    }
    
    private mutating func updateOverallScore() {
        let scores = activitiesCompleted.compactMap { $0.score }
        overallScore = scores.isEmpty ? nil : scores.reduce(0, +) / Double(scores.count)
    }
}

// MARK: - Types de Session
enum SessionType: String, CaseIterable, Codable {
    case reading = "Lecture"
    case quiz = "Quiz"
    case flashcards = "Flashcards"
    case generation = "Génération"
    case review = "Révision"
    case freeStudy = "Étude Libre"
    
    var systemImage: String {
        switch self {
        case .reading: return "book.open"
        case .quiz: return "questionmark.circle.fill"
        case .flashcards: return "rectangle.stack.fill"
        case .generation: return "wand.and.stars"
        case .review: return "arrow.clockwise"
        case .freeStudy: return "brain.head.profile"
        }
    }
}

/// Résultat d'une activité dans la session
struct ActivityResult: Identifiable, Codable {
    var id = UUID()
    let activityType: ActivityType
    let contentID: UUID?
    let startTime: Date
    let endTime: Date
    let score: Double?
    let conceptsCovered: Set<String>
    let errorsBy: [ErrorAnalysis]
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

enum ActivityType: String, Codable {
    case quizQuestion = "Question Quiz"
    case flashcardReview = "Révision Flashcard"
    case conceptExplanation = "Explication Concept"
    case contentGeneration = "Génération Contenu"
    case pdfReading = "Lecture PDF"
}

/// Analyse d'erreur pour amélioration
struct ErrorAnalysis: Identifiable, Codable {
    var id = UUID()
    let errorType: ErrorType
    let concept: String
    let description: String
    let suggestedReview: String?
    
    enum ErrorType: String, Codable {
        case conceptual = "Erreur Conceptuelle"
        case procedural = "Erreur Procédurale"
        case attention = "Erreur d'Attention"
        case memory = "Erreur de Mémoire"
    }
}

/// Difficulté rencontrée pendant l'étude
struct StudyDifficulty: Identifiable, Codable {
    var id = UUID()
    let concept: String
    let difficultyType: DifficultyType
    let severity: SeverityLevel
    let timestamp: Date
    let userDescription: String?
    
    enum DifficultyType: String, Codable {
        case understanding = "Compréhension"
        case memory = "Mémorisation"
        case application = "Application"
        case attention = "Concentration"
    }
    
    enum SeverityLevel: String, Codable {
        case minor = "Mineure"
        case moderate = "Modérée"
        case major = "Majeure"
        case blocking = "Bloquante"
    }
}

/// Évaluation de session par l'utilisateur
struct SessionRating: Codable {
    let effectiveness: Int // 1-5
    let difficulty: Int // 1-5
    let enjoyment: Int // 1-5
    let concentration: Int // 1-5
    let comprehension: Int // 1-5
    
    var averageRating: Double {
        Double(effectiveness + difficulty + enjoyment + concentration + comprehension) / 5.0
    }
} 