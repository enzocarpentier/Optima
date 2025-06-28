//
//  PDFProcessingService.swift
//  Foundation
//
//  Service de traitement des PDFs avec PDFKit
//  Extraction intelligente de contenu et métadonnées
//

import Foundation
import PDFKit
import NaturalLanguage

/// Service de traitement avancé des documents PDF
/// Responsabilité : Extraction de texte, analyse de contenu, métadonnées
final class PDFProcessingService {
    
    // MARK: - Types de Résultats
    
    struct PDFInfo {
        let pageCount: Int
        let extractedText: String
        let topics: [String]
        let metadata: PDFMetadata
        let structure: DocumentStructure
    }
    
    struct PDFMetadata {
        let title: String?
        let author: String?
        let subject: String?
        let creator: String?
        let creationDate: Date?
        let modificationDate: Date?
        let keywords: [String]
    }
    
    struct DocumentStructure {
        let chapters: [Chapter]
        let tableOfContents: [TOCEntry]
        let difficulty: DifficultyLevel
        let estimatedReadingTime: TimeInterval
    }
    
    struct Chapter {
        let title: String
        let pageRange: Range<Int>
        let content: String
        let keyTerms: [String]
    }
    
    struct TOCEntry {
        let title: String
        let pageNumber: Int
        let level: Int
    }
    
    // MARK: - Configuration
    private let naturalLanguageProcessor = NLLanguageRecognizer()
    private let textAnalyzer = TextAnalyzer()
    
    // MARK: - Traitement Principal
    
    /// Traite un document PDF de manière complète
    func processDocument(at url: URL) async throws -> PDFInfo {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw PDFError.unableToOpenDocument
        }
        
        // Extraction parallèle des données
        async let pageCount = extractPageCount(from: pdfDocument)
        async let extractedText = extractFullText(from: pdfDocument)
        async let metadata = extractMetadata(from: pdfDocument)
        
        // Attend toutes les extractions de base
        let basePageCount = await pageCount
        let baseText = await extractedText
        let baseMetadata = await metadata
        
        // Analyse du contenu (nécessite le texte)
        async let topics = analyzeTopics(from: baseText)
        async let structure = analyzeStructure(from: pdfDocument, text: baseText)
        
        let finalTopics = await topics
        let finalStructure = await structure
        
        return PDFInfo(
            pageCount: basePageCount,
            extractedText: baseText,
            topics: finalTopics,
            metadata: baseMetadata,
            structure: finalStructure
        )
    }
    
    /// Extraction rapide pour aperçu
    func quickAnalysis(at url: URL) async throws -> (pageCount: Int, title: String, estimatedSize: String) {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw PDFError.unableToOpenDocument
        }
        
        let pageCount = pdfDocument.pageCount
        let title = pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? 
                   url.deletingPathExtension().lastPathComponent
        
        // Estimation taille basée sur le nombre de pages
        let estimatedSize = formatEstimatedSize(pageCount: pageCount)
        
        return (pageCount, title, estimatedSize)
    }
    
    // MARK: - Extraction de Contenu
    
    private func extractPageCount(from document: PDFDocument) async -> Int {
        return document.pageCount
    }
    
    private func extractFullText(from document: PDFDocument) async -> String {
        var fullText = ""
        
        for pageIndex in 0..<document.pageCount {
            if let page = document.page(at: pageIndex),
               let pageText = page.string {
                fullText += pageText + "\n\n"
            }
        }
        
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractMetadata(from document: PDFDocument) async -> PDFMetadata {
        let attributes = document.documentAttributes ?? [:]
        
        return PDFMetadata(
            title: attributes[PDFDocumentAttribute.titleAttribute] as? String,
            author: attributes[PDFDocumentAttribute.authorAttribute] as? String,
            subject: attributes[PDFDocumentAttribute.subjectAttribute] as? String,
            creator: attributes[PDFDocumentAttribute.creatorAttribute] as? String,
            creationDate: attributes[PDFDocumentAttribute.creationDateAttribute] as? Date,
            modificationDate: attributes[PDFDocumentAttribute.modificationDateAttribute] as? Date,
            keywords: extractKeywords(from: attributes[PDFDocumentAttribute.keywordsAttribute] as? String)
        )
    }
    
    // MARK: - Analyse de Contenu
    
    private func analyzeTopics(from text: String) async -> [String] {
        return await textAnalyzer.extractTopics(from: text)
    }
    
    private func analyzeStructure(from document: PDFDocument, text: String) async -> DocumentStructure {
        let chapters = await extractChapters(from: document, fullText: text)
        let toc = await extractTableOfContents(from: document)
        let difficulty = await assessDifficulty(from: text)
        let readingTime = estimateReadingTime(from: text)
        
        return DocumentStructure(
            chapters: chapters,
            tableOfContents: toc,
            difficulty: difficulty,
            estimatedReadingTime: readingTime
        )
    }
    
    private func extractChapters(from document: PDFDocument, fullText: String) async -> [Chapter] {
        // Détection des chapitres basée sur les patterns typiques
        let _ = [
            #"Chapitre\s+\d+"#,
            #"Chapter\s+\d+"#,
            #"CHAPITRE\s+\d+"#,
            #"\d+\.\s+[A-Z][^.]*$"#
        ] // TODO: Utiliser ces patterns dans une implémentation future
        
        var chapters: [Chapter] = []
        
        // Pour l'instant, création d'un chapitre par défaut
        // TODO: Implémentation complète de détection de structure
        if !fullText.isEmpty {
            let defaultChapter = Chapter(
                title: "Contenu Principal",
                pageRange: 0..<document.pageCount,
                content: String(fullText.prefix(1000)), // Aperçu
                keyTerms: await textAnalyzer.extractKeyTerms(from: fullText)
            )
            chapters.append(defaultChapter)
        }
        
        return chapters
    }
    
    private func extractTableOfContents(from document: PDFDocument) async -> [TOCEntry] {
        // Utilisation de l'outline PDF si disponible
        var tocEntries: [TOCEntry] = []
        
        if let outline = document.outlineRoot {
            tocEntries = extractTOCRecursive(from: outline, level: 0)
        }
        
        return tocEntries
    }
    
    private func extractTOCRecursive(from outline: PDFOutline, level: Int) -> [TOCEntry] {
        var entries: [TOCEntry] = []
        
        if let label = outline.label,
           let destination = outline.destination,
           let page = destination.page {
            let pageIndex = page.document?.index(for: page) ?? 0
            entries.append(TOCEntry(title: label, pageNumber: pageIndex + 1, level: level))
        }
        
        for i in 0..<outline.numberOfChildren {
            if let child = outline.child(at: i) {
                entries.append(contentsOf: extractTOCRecursive(from: child, level: level + 1))
            }
        }
        
        return entries
    }
    
    private func assessDifficulty(from text: String) async -> DifficultyLevel {
        return await textAnalyzer.assessDifficulty(from: text)
    }
    
    private func estimateReadingTime(from text: String) -> TimeInterval {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let wordsPerMinute = 200.0 // Vitesse de lecture moyenne
        let minutes = Double(wordCount) / wordsPerMinute
        return minutes * 60 // En secondes
    }
    
    // MARK: - Utilitaires
    
    private func extractKeywords(from keywordsString: String?) -> [String] {
        guard let keywords = keywordsString else { return [] }
        return keywords.components(separatedBy: .punctuationCharacters)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func formatEstimatedSize(pageCount: Int) -> String {
        switch pageCount {
        case 0...10: return "Court (≤ 30 min)"
        case 11...50: return "Moyen (30min - 2h)"
        case 51...100: return "Long (2h - 4h)"
        default: return "Très long (> 4h)"
        }
    }
}

// MARK: - Analyseur de Texte
private actor TextAnalyzer {
    
    func extractTopics(from text: String) async -> [String] {
        // Utilisation de NaturalLanguage pour extraire les entités nommées
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var topics: Set<String> = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, 
                           unit: .word, 
                           scheme: .nameType) { tag, tokenRange in
            if tag != nil {
                let word = String(text[tokenRange])
                if word.count > 3 { // Filtrer les mots trop courts
                    topics.insert(word)
                }
            }
            return true
        }
        
        return Array(topics).prefix(20).map { String($0) } // Top 20
    }
    
    func extractKeyTerms(from text: String) async -> [String] {
        // Extraction de termes clés basée sur la fréquence et l'importance
        let words = text.lowercased()
            .components(separatedBy: .punctuationCharacters.union(.whitespacesAndNewlines))
            .filter { $0.count > 4 } // Mots significatifs
        
        let wordFrequency = Dictionary(grouping: words, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return Array(wordFrequency.prefix(15).map { $0.key })
    }
    
    func assessDifficulty(from text: String) async -> DifficultyLevel {
        // Analyse de complexité basée sur plusieurs facteurs
        let sentences = text.components(separatedBy: .punctuationCharacters)
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        let averageWordsPerSentence = Double(words.count) / Double(max(sentences.count, 1))
        let averageWordLength = words.reduce(0) { $0 + $1.count } / max(words.count, 1)
        
        // Heuristique de difficulté
        switch (averageWordsPerSentence, averageWordLength) {
        case (..<10, ..<5):
            return .beginner
        case (10..<20, 5..<7):
            return .intermediate
        case (20..<30, 7..<9):
            return .advanced
        default:
            return .expert
        }
    }
}

// MARK: - Erreurs PDF
enum PDFError: LocalizedError {
    case unableToOpenDocument
    case corruptedDocument
    case unsupportedFormat
    case extractionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .unableToOpenDocument:
            return "Impossible d'ouvrir le document PDF"
        case .corruptedDocument:
            return "Le document PDF est corrompu"
        case .unsupportedFormat:
            return "Format PDF non supporté"
        case .extractionFailed(let reason):
            return "Échec d'extraction: \(reason)"
        }
    }
}

// MARK: - Extensions
private extension String {
    var deletingPathExtension: String {
        (self as NSString).deletingPathExtension
    }
} 