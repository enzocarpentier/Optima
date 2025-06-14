import Foundation
import PDFKit
import AppKit

// MARK: - Service d'extraction de texte PDF

enum PDFTextExtractorError: Error, LocalizedError {
    case unableToLoadPage
    case noTextFoundInPage
    case documentIsEmpty
    case securityScopedResourceAccessError(String)
    case documentLoadError(String)

    var errorDescription: String? {
        switch self {
        case .unableToLoadPage:
            return "Impossible de charger une page du PDF."
        case .noTextFoundInPage:
            return "Aucun texte n'a été trouvé sur une page du PDF."
        case .documentIsEmpty:
            return "Le document PDF est vide ou ne contient aucun texte extractible."
        case .securityScopedResourceAccessError(let message):
            return "Erreur d'accès à la ressource sécurisée: \(message)"
        case .documentLoadError(let message):
            return "Erreur lors du chargement du document PDF: \(message)"
        }
    }
}

class PDFTextExtractor {
    static let shared = PDFTextExtractor()
    
    private init() {}
    
    // MARK: - Extraction de texte complet
    
    /// Extrait tout le texte d'un document PDF
    func extractFullText(from document: PDFKit.PDFDocument) -> Result<String, PDFTextExtractorError> {
        var fullText = ""
        
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else {
                // return .failure(.extractionFailed) // Remplacé
                return .failure(.unableToLoadPage)
            }
            
            if let pageText = page.string {
                fullText += pageText + "\n\n"
            } else {
                // Optionnel: considérer ceci comme une erreur si chaque page DOIT avoir du texte
                // return .failure(.noTextFoundInPage)
            }
        }
        
        let cleanedText = cleanText(fullText)
        
        guard !cleanedText.isEmpty else {
            // return .failure(.extractionFailed) // Remplacé
            return .failure(.documentIsEmpty)
        }
        
        return .success(cleanedText)
    }
    
    /// Extrait le texte d'un PDF depuis une URL
    func extractText(from url: URL) -> Result<String, PDFTextExtractorError> {
        // Tenter de démarrer l'accès pour les ressources sécurisées (ex: depuis un picker)
        // Si l'URL n'est pas une ressource sécurisée (ex: fichier interne à l'app),
        // cet appel retourne false, mais ce n'est pas une erreur.
        // L'accès direct au fichier peut toujours être possible.
        let accessGranted = url.startAccessingSecurityScopedResource()

        defer {
            // Arrêter l'accès uniquement si on l'a démarré avec succès
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let document = PDFKit.PDFDocument(url: url) else {
            // Si le chargement échoue ici, c'est une vraie erreur (fichier non trouvé, corrompu, ou permissions manquantes)
            return .failure(.documentLoadError("Impossible de charger le PDF depuis l'URL: \(url.path)"))
        }
        
        return extractFullText(from: document)
    }
    
    // MARK: - Extraction par pages
    
    /// Extrait le texte de pages spécifiques
    func extractText(from document: PDFKit.PDFDocument, pageRange: Range<Int>) -> Result<String, PDFTextExtractorError> { // Modifié pour retourner PDFTextExtractorError
        var extractedText = ""
        
        let safeRange = max(0, pageRange.lowerBound)..<min(document.pageCount, pageRange.upperBound)
        
        if safeRange.isEmpty && !(0..<document.pageCount).isEmpty {
            // La plage demandée est en dehors des pages valides du document
            return .failure(.documentLoadError("La plage de pages spécifiée (\\(pageRange.lowerBound)-\\(pageRange.upperBound)) est invalide pour un document de \\(document.pageCount) pages."))
        }

        for pageIndex in safeRange {
            guard let page = document.page(at: pageIndex) else {
                // return .failure(.extractionFailed) // Remplacé
                return .failure(.unableToLoadPage)
            }
            
            if let pageText = page.string {
                extractedText += "=== Page \\(pageIndex + 1) ===\\n"
                extractedText += pageText + "\\n\\n"
            } else {
                // Optionnel: considérer comme une erreur si une page spécifique ne contient pas de texte
                // return .failure(.noTextFoundInPage)
            }
        }
        
        let cleanedText = cleanText(extractedText)
        
        guard !cleanedText.isEmpty else {
            // return .failure(.extractionFailed) // Remplacé
            return .failure(.documentIsEmpty) // Ou un cas plus spécifique si la plage était valide mais vide de texte
        }
        
        return .success(cleanedText)
    }
    
    // MARK: - Analyse du contenu
    
    /// Analyse les métadonnées du document
    func analyzeDocument(_ document: PDFKit.PDFDocument) -> DocumentAnalysis {
        let pageCount = document.pageCount
        let textResult = extractFullText(from: document)
        
        guard case .success(let text) = textResult else {
            return DocumentAnalysis(
                pageCount: pageCount,
                wordCount: 0,
                estimatedReadingTime: 0,
                language: "fr",
                complexity: .unknown,
                hasImages: false,
                hasTables: false
            )
        }
        
        let wordCount = countWords(in: text)
        let readingTime = estimateReadingTime(wordCount: wordCount)
        let complexity = assessComplexity(text: text)
        let hasImages = detectImages(in: document)
        let hasTables = detectTables(in: text)
        
        return DocumentAnalysis(
            pageCount: pageCount,
            wordCount: wordCount,
            estimatedReadingTime: readingTime,
            language: detectLanguage(text: text),
            complexity: complexity,
            hasImages: hasImages,
            hasTables: hasTables
        )
    }
    
    // MARK: - Utilitaires privés
    
    private func cleanText(_ text: String) -> String {
        var cleaned = text
        
        // Supprimer les caractères de contrôle indésirables
        cleaned = cleaned.replacingOccurrences(of: "\u{00A0}", with: " ") // Non-breaking space
        cleaned = cleaned.replacingOccurrences(of: "\u{2000}...\u{200F}", with: " ", options: .regularExpression)
        
        // Normaliser les espaces et sauts de ligne
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "\\n\\s*\\n", with: "\n\n", options: .regularExpression)
        
        // Supprimer les espaces en début et fin
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
    
    private func countWords(in text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    private func estimateReadingTime(wordCount: Int) -> Int {
        // Moyenne de 200 mots par minute pour la lecture
        return max(1, wordCount / 200)
    }
    
    private func detectLanguage(text: String) -> String {
        // Détection simple basée sur des mots courants français
        let frenchWords = ["le", "la", "les", "de", "du", "des", "et", "ou", "pour", "dans", "avec", "sur", "par", "est", "sont", "que", "qui", "une", "un"]
        let lowercaseText = text.lowercased()
        
        let frenchWordCount = frenchWords.reduce(0) { count, word in
            count + lowercaseText.components(separatedBy: " \(word) ").count - 1
        }
        
        return frenchWordCount > 10 ? "fr" : "en"
    }
    
    private func assessComplexity(text: String) -> DocumentComplexity {
        let wordCount = countWords(in: text)
        let sentenceCount = text.components(separatedBy: CharacterSet(charactersIn: ".!?")).count
        let avgWordsPerSentence = wordCount / max(1, sentenceCount)
        
        // Comptage des mots complexes (plus de 6 caractères)
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let complexWords = words.filter { $0.count > 6 }.count
        let complexWordRatio = Double(complexWords) / Double(wordCount)
        
        if avgWordsPerSentence > 20 || complexWordRatio > 0.3 {
            return .high
        } else if avgWordsPerSentence > 15 || complexWordRatio > 0.2 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func detectImages(in document: PDFKit.PDFDocument) -> Bool {
        // Détection simple - vérifier si des pages contiennent des annotations d'image
        for pageIndex in 0..<min(5, document.pageCount) { // Vérifier les 5 premières pages
            guard let page = document.page(at: pageIndex) else { continue }
            
            if page.annotations.contains(where: { $0.type == "Stamp" || $0.type == "FreeText" }) {
                return true
            }
        }
        return false
    }
    
    private func detectTables(in text: String) -> Bool {
        // Détection simple basée sur des patterns de tableaux
        let tablePatterns = [
            "\\|.*\\|", // Lignes avec pipes
            "\\t.*\\t.*\\t", // Plusieurs tabulations
            "\\d+\\s+\\d+\\s+\\d+" // Colonnes de nombres
        ]
        
        for pattern in tablePatterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Modèles d'analyse

struct DocumentAnalysis {
    let pageCount: Int
    let wordCount: Int
    let estimatedReadingTime: Int // en minutes
    let language: String
    let complexity: DocumentComplexity
    let hasImages: Bool
    let hasTables: Bool
}

enum DocumentComplexity: String, CaseIterable {
    case low = "Facile"
    case medium = "Moyen"
    case high = "Complexe"
    case unknown = "Inconnu"
}
