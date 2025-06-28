//
//  GeneratedContentModel.swift
//  ContentManagement/Models
//
//  Modèles pour le contenu généré par l'IA
//  Quiz, flashcards, résumés et autres éléments d'apprentissage
//

import Foundation

/// Item de contenu généré par l'IA
/// Responsabilité : Structure polymorphe pour tous types de contenu généré
struct GeneratedContentItem: Identifiable, Codable {
    var id = UUID()
    let type: ContentType
    let title: String
    let sourceDocument: UUID
    let sourcePage: Int?
    let dateGenerated: Date
    let content: ContentData
    
    // MARK: - Métadonnées Génération
    var difficulty: DifficultyLevel
    var estimatedDuration: TimeInterval
    var tags: [String]
    
    // MARK: - Statistiques Usage
    var timesUsed: Int = 0
    var averageScore: Double = 0.0
    var lastUsed: Date?
    
    init(type: ContentType, title: String, sourceDocument: UUID, content: ContentData) {
        self.type = type
        self.title = title
        self.sourceDocument = sourceDocument
        self.sourcePage = nil
        self.dateGenerated = Date()
        self.content = content
        self.difficulty = .intermediate
        self.estimatedDuration = 300 // 5 minutes par défaut
        self.tags = []
    }
}

// MARK: - Types de Contenu
enum ContentType: String, CaseIterable, Codable {
    case quiz = "Quiz"
    case flashcards = "Flashcards"
    case summary = "Résumé"
    case explanation = "Explication"
    case exercise = "Exercice"
    case mindMap = "Carte Mentale"
    
    var systemImage: String {
        switch self {
        case .quiz: return "questionmark.circle"
        case .flashcards: return "rectangle.stack"
        case .summary: return "doc.text"
        case .explanation: return "lightbulb"
        case .exercise: return "pencil.and.outline"
        case .mindMap: return "brain"
        }
    }
}

// MARK: - Contenu Polymorphe
enum ContentData: Codable {
    case quiz(QuizContent)
    case flashcards(FlashcardsContent)
    case summary(SummaryContent)
    case explanation(ExplanationContent)
    
    // Implémentation manuelle de Codable pour gérer l'énumération avec valeurs associées
    
    private enum CodingKeys: String, CodingKey {
        case type, payload
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)
        
        switch type {
        case .quiz:
            let payload = try container.decode(QuizContent.self, forKey: .payload)
            self = .quiz(payload)
        case .flashcards:
            let payload = try container.decode(FlashcardsContent.self, forKey: .payload)
            self = .flashcards(payload)
        case .summary:
            let payload = try container.decode(SummaryContent.self, forKey: .payload)
            self = .summary(payload)
        case .explanation:
            let payload = try container.decode(ExplanationContent.self, forKey: .payload)
            self = .explanation(payload)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Type de contenu non supporté pour le décodage")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .quiz(let payload):
            try container.encode(ContentType.quiz, forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .flashcards(let payload):
            try container.encode(ContentType.flashcards, forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .summary(let payload):
            try container.encode(ContentType.summary, forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .explanation(let payload):
            try container.encode(ContentType.explanation, forKey: .type)
            try container.encode(payload, forKey: .payload)
        }
    }
}

/// Contenu de quiz
struct QuizContent: Codable {
    let questions: [QuizQuestion]
    let timeLimit: TimeInterval?
    let passingScore: Double
    
    var totalPoints: Int {
        questions.reduce(0) { $0 + $1.points }
    }
}

/// Question de quiz
struct QuizQuestion: Identifiable, Codable {
    var id = UUID()
    let question: String
    let type: QuestionType
    let options: [String]
    let correctAnswers: [Int]
    let explanation: String?
    let points: Int
    
    enum QuestionType: String, Codable {
        case multipleChoice = "QCM"
        case trueFalse = "Vrai/Faux"
        case shortAnswer = "Réponse Courte"
        case essay = "Dissertation"
    }
}

/// Contenu de flashcards
struct FlashcardsContent: Codable {
    let cards: [Flashcard]
    let categories: [String]
}

/// Flashcard individuelle
struct Flashcard: Identifiable, Codable {
    var id = UUID()
    let front: String
    let back: String
    let category: String?
    let difficulty: DifficultyLevel
    
    // État d'apprentissage Leitner
    var leitnerBox: Int = 1
    var nextReview: Date?
    var successCount: Int = 0
    var failureCount: Int = 0
}

/// Contenu de résumé
struct SummaryContent: Codable {
    let text: String
    let keyPoints: [String]
    let concepts: [ConceptSummary]
}

/// Résumé de concept
struct ConceptSummary: Identifiable, Codable {
    var id = UUID()
    let name: String
    let definition: String
    let importance: ImportanceLevel
    let relatedConcepts: [String]
    
    enum ImportanceLevel: String, Codable {
        case low = "Faible"
        case medium = "Moyenne"
        case high = "Élevée"
        case critical = "Critique"
    }
}

/// Contenu d'explication
struct ExplanationContent: Codable {
    let text: String
    let examples: [String]
    let analogies: [String]
    let visualDescriptions: [String]
} 