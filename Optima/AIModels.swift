import Foundation

// MARK: - Réponses IA génériques

// MARK: - Metadata Structs (Codable)
struct QuizMetadata: Codable {
    let version: String? // Example property
    let difficulty: String?
    let category: String?
    // Add other metadata fields as needed
}

struct FlashCardMetadata: Codable {
    let version: String? // Example property
    let level: String?
    let subject: String?
    // Add other metadata fields as needed
}

struct TermMetadata: Codable {
    let version: String? // Example property
    let source: String?
    let notes: String?
    // Add other metadata fields as needed
}

enum AIError: Error, LocalizedError {
    case networkError(String)
    case parsingError(String)
    case apiKeyMissing
    case invalidResponse
    case pdfFileLoadError(String)
    case pdfTextExtractionError(String)
    case securityScopeError(String)
    case rateLimitExceeded
    case dailyQuotaExceeded // New case for daily limits
    case contentBlockedBySafetySettings // New case for safety blocks
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Erreur réseau: \(message)"
        case .parsingError(let message):
            return "Erreur de traitement: \(message)"
        case .apiKeyMissing:
            return "Clé API manquante. Veuillez la configurer dans les paramètres."
        case .invalidResponse:
            return "Réponse invalide de l'IA."
        case .pdfFileLoadError(let message):
            return "Erreur de chargement du fichier PDF: \(message)"
        case .pdfTextExtractionError(let message):
            return "Erreur d'extraction de texte du PDF: \(message)"
        case .securityScopeError(let message):
            return "Erreur d'accès au fichier PDF: \(message)"
        case .rateLimitExceeded:
            return "Limite de taux d'appels API atteinte. Veuillez réessayer plus tard."
        case .dailyQuotaExceeded:
            return "Quota quotidien de l'API gratuit atteint. Veuillez réessayer demain."
        case .contentBlockedBySafetySettings:
            return "La génération de contenu a été bloquée par les filtres de sécurité de l'IA, probablement à cause du contenu du document source."
        case .apiError(let message):
            return "Erreur API: \(message)"
        }
    }
}

// MARK: - Modèles pour QCM

struct QuizQuestion: Codable, Identifiable {
    let id: UUID
    let question: String
    let options: [String]
    let correctAnswer: String // AI will provide the correct answer string directly
    let explanation: String?
    
    init(id: UUID = UUID(), question: String, options: [String], correctAnswer: String, explanation: String?) {
        self.id = id
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idString = try container.decode(String.self, forKey: .id)
        if let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            self.id = UUID() // Fallback to a new UUID if the string is not a valid UUID
        }
        self.question = try container.decode(String.self, forKey: .question)
        self.options = try container.decode([String].self, forKey: .options)
        self.correctAnswer = try container.decode(String.self, forKey: .correctAnswer)
        self.explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
    }
}

struct QuizResponse: Codable {
    let questions: [QuizQuestion] // This key 'questions' will be used in the prompt
    let metadata: QuizMetadata? // Made metadata optional
}

// MARK: - Modèles pour Flashcards

struct FlashCard: Codable, Identifiable {
    let id: UUID
    let term: String // Changed from front
    let definition: String // Changed from back
    // Removed difficulty and tags for now to simplify AI prompt and parsing
    // let difficulty: FlashCardDifficulty
    // let tags: [String]

    init(id: UUID = UUID(), term: String, definition: String) { // Adjusted init
        self.id = id
        self.term = term
        self.definition = definition
        // self.difficulty = difficulty
        // self.tags = tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idString = try container.decode(String.self, forKey: .id)
        if let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            self.id = UUID() // Fallback
        }
        self.term = try container.decode(String.self, forKey: .term)
        self.definition = try container.decode(String.self, forKey: .definition)
    }
}

// enum FlashCardDifficulty: String, Codable, CaseIterable {
//     case easy = "Facile"
//     case medium = "Moyen"
//     case hard = "Difficile"
// }

struct FlashCardResponse: Codable {
    let flashcards: [FlashCard] // This key 'flashcards' will be used in the prompt
    let metadata: FlashCardMetadata? // Made metadata optional
}

// MARK: - Modèles pour Résumé

struct TextSummary: Codable, Identifiable {
    let id: UUID
    let summaryText: String
    let keyPoints: [String]
    let mainTopics: [String]
    let wordCount: Int
    let originalWordCount: Int

    init(id: UUID = UUID(), summaryText: String, keyPoints: [String], mainTopics: [String], wordCount: Int, originalWordCount: Int) {
        self.id = id
        self.summaryText = summaryText
        self.keyPoints = keyPoints
        self.mainTopics = mainTopics
        self.wordCount = wordCount
        self.originalWordCount = originalWordCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idString = try container.decode(String.self, forKey: .id)
        if let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            self.id = UUID() // Fallback
        }
        self.summaryText = try container.decode(String.self, forKey: .summaryText)
        self.keyPoints = try container.decode([String].self, forKey: .keyPoints)
        self.mainTopics = try container.decode([String].self, forKey: .mainTopics)
        self.wordCount = try container.decode(Int.self, forKey: .wordCount)
        self.originalWordCount = try container.decode(Int.self, forKey: .originalWordCount)
    }

    var compressionRatio: Double {
        guard originalWordCount > 0 else { return 0 }
        return Double(wordCount) / Double(originalWordCount)
    }
}

// No specific SummaryResponse wrapper needed if TextSummary is the top-level object the AI returns,
// or if the prompt asks for a JSON that directly maps to TextSummary.
// If the AI wraps it, e.g., {"summary_data": {...}}, then a SummaryResponse struct would be needed.
// For now, assuming the prompt will ask for the TextSummary structure directly.

struct SummaryResponse: Codable {
    let summary_data: TextSummary
    // Assuming summary does not have separate metadata in the same way as others for now,
    // as DocumentSummary in StudyModels.swift doesn't expect a nested metadata object from SummaryResponse.
    // If it should, it can be added here and StudyModels.swift adjusted.
}

// MARK: - Modèles pour Définitions

struct TermDefinition: Codable, Identifiable {
    let id: UUID
    let term: String
    let definition: String
    let context: String?
    let relatedTerms: [String]
    let importance: TermImportance

    init(id: UUID = UUID(), term: String, definition: String, context: String?, relatedTerms: [String], importance: TermImportance) {
        self.id = id
        self.term = term
        self.definition = definition
        self.context = context
        self.relatedTerms = relatedTerms
        self.importance = importance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idString = try container.decode(String.self, forKey: .id)
        if let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            self.id = UUID() // Fallback
        }
        self.term = try container.decode(String.self, forKey: .term)
        self.definition = try container.decode(String.self, forKey: .definition)
        self.context = try container.decodeIfPresent(String.self, forKey: .context)
        self.relatedTerms = try container.decode([String].self, forKey: .relatedTerms)
        self.importance = try container.decode(TermImportance.self, forKey: .importance)
    }
}

enum TermImportance: String, Codable, CaseIterable {
    case low = "Secondaire"
    case medium = "Moyen"
    case high = "Essentiel"
}

struct TermDefinitionResponse: Codable {
    let definitions: [TermDefinition] // This key 'definitions' will be used in the prompt
    let metadata: TermMetadata? // Made metadata optional
}

// MARK: - Requêtes IA

struct AIRequest {
    let documentText: String
    let documentName: String
    let requestType: AIRequestType
    let parameters: AIParameters
}

enum AIRequestType {
    case quiz(questionCount: Int, difficulty: String)
    case flashcards(cardCount: Int, focus: String)
    case summary(length: SummaryLength)
    case definitions(maxTerms: Int)
}

enum SummaryLength: String, CaseIterable {
    case short = "court"
    case medium = "moyen"
    case long = "détaillé"
}

struct AIParameters {
    let language: String = "fr"
    let tone: String = "académique"
    let includeExamples: Bool = true
}

// MARK: - États de traitement

enum AIProcessingState {
    case idle
    case extractingText
    case generatingContent
    case completed
    case failed(AIError)
}

// MARK: - Réponse unifiée

struct AIGenerationResult<T: Codable> {
    let content: T
    let processingTime: TimeInterval
    let tokenUsage: TokenUsage?
    let sourceDocument: String
}

struct TokenUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
}
