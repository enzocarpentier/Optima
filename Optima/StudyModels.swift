import Foundation

// Un protocole commun pour tous les éléments générés
protocol StudyMaterial {
    var id: UUID { get }
    var documentId: UUID { get }
    var documentName: String { get }
    var dateCreated: Date { get }
}

// MARK: - Enum for FlashCardDifficulty (Codable)
enum FlashCardDifficulty: String, Codable, CaseIterable {
    case easy = "Facile"
    case medium = "Moyen"
    case hard = "Difficile"
}

// Modèle pour un QCM
struct QCMTest: StudyMaterial, Identifiable, Codable {
    let id: UUID
    let documentId: UUID
    var documentName: String
    let dateCreated: Date
    
    // Contenu du QCM
    let questions: [QuizQuestion]
    let metadata: QuizMetadata
    let score: Int? // Score obtenu lors du dernier passage
    let attempts: Int // Nombre de tentatives
    
    init(documentId: UUID, documentName: String, quizResponse: QuizResponse) {
        self.id = UUID()
        self.documentId = documentId
        self.documentName = documentName
        self.dateCreated = Date()
        self.questions = quizResponse.questions
        self.metadata = quizResponse.metadata ?? QuizMetadata(version: nil, difficulty: nil, category: nil)
        self.score = nil
        self.attempts = 0
    }
}

// Modèle pour un ensemble de Flashcards
struct FlashcardSet: StudyMaterial, Identifiable, Codable {
    let id: UUID
    let documentId: UUID
    var documentName: String
    let dateCreated: Date
    
    // Contenu des flashcards
    let cards: [FlashCard]
    let metadata: FlashCardMetadata
    var studyProgress: [UUID: FlashCardProgress] // Progrès par carte
    
    init(documentId: UUID, documentName: String, flashcardResponse: FlashCardResponse) {
        self.id = UUID()
        self.documentId = documentId
        self.documentName = documentName
        self.dateCreated = Date()
        self.cards = flashcardResponse.flashcards // Corrected from flashcardResponse.cards
        self.metadata = flashcardResponse.metadata ?? FlashCardMetadata(version: nil, level: nil, subject: nil) // Assuming FlashCardResponse has metadata
        self.studyProgress = [:]
    }
}

// Modèle pour le progrès d'une flashcard
struct FlashCardProgress: Codable {
    var reviewCount: Int = 0
    var correctCount: Int = 0
    var lastReviewed: Date?
    var nextReview: Date?
    var difficulty: FlashCardDifficulty
    
    var successRate: Double {
        guard reviewCount > 0 else { return 0 }
        return Double(correctCount) / Double(reviewCount)
    }
}

// Modèle pour un résumé
struct DocumentSummary: StudyMaterial, Identifiable, Codable {
    let id: UUID
    let documentId: UUID
    var documentName: String
    let dateCreated: Date
    
    // Contenu du résumé
    let summary: TextSummary
    var isBookmarked: Bool
    var notes: String
    
    init(documentId: UUID, documentName: String, textSummary: TextSummary) {
        self.id = UUID()
        self.documentId = documentId
        self.documentName = documentName
        self.dateCreated = Date()
        self.summary = textSummary
        self.isBookmarked = false
        self.notes = ""
    }
}

// Modèle pour une liste de termes clés
struct KeyTermList: StudyMaterial, Identifiable, Codable {
    let id: UUID
    let documentId: UUID
    var documentName: String
    let dateCreated: Date
    
    // Contenu des termes
    let terms: [TermDefinition]
    let metadata: TermMetadata
    var studiedTerms: Set<UUID> // Termes déjà étudiés
    
    init(documentId: UUID, documentName: String, termResponse: TermDefinitionResponse) {
        self.id = UUID()
        self.documentId = documentId
        self.documentName = documentName
        self.dateCreated = Date()
        self.terms = termResponse.definitions // Corrected from termResponse.terms
        self.metadata = termResponse.metadata ?? TermMetadata(version: nil, source: nil, notes: nil) // Assuming TermDefinitionResponse has metadata
        self.studiedTerms = []
    }
    
    var studyProgress: Double {
        guard !terms.isEmpty else { return 0 }
        return Double(studiedTerms.count) / Double(terms.count)
    }
}
