import Foundation
import Combine
import SwiftUI

/// Le ViewModel qui gère la logique et l'état d'une session de révision de flashcards.
@MainActor
final class FlashcardsPlayerViewModel: ObservableObject {
    
    // MARK: - Propriétés Publiées
    
    /// Le titre du paquet de flashcards.
    @Published private(set) var deckTitle: String
    
    /// Les cartes du paquet, potentiellement mélangées.
    @Published private(set) var cards: [Flashcard]
    
    /// L'index de la carte actuellement affichée.
    @Published private(set) var currentCardIndex: Int = 0
    
    /// Indique si la carte actuelle est retournée.
    @Published var isCurrentCardFlipped: Bool = false
    
    /// Indique si la session de révision est terminée.
    @Published private(set) var isFinished: Bool = false
    
    // MARK: - Session Tracking
    private let startTime: Date
    private let documentID: UUID
    private let saveSessionAction: (StudySession) async -> Void
    
    /// La progression dans le paquet, de 0.0 à 1.0.
    var progress: Double {
        guard !cards.isEmpty else { return 0.0 }
        return Double(currentCardIndex + 1) / Double(cards.count)
    }
    
    /// La carte actuellement affichée.
    var currentCard: Flashcard? {
        guard cards.indices.contains(currentCardIndex) else { return nil }
        return cards[currentCardIndex]
    }
    
    // MARK: - Initialisation
    
    init(flashcardsContent: FlashcardsContent, title: String, documentID: UUID, onSave: @escaping (StudySession) async -> Void) {
        self.deckTitle = title
        self.documentID = documentID
        self.saveSessionAction = onSave
        self.startTime = Date() // Capture du temps de début réel
        // On mélange les cartes au début de chaque session pour une meilleure expérience.
        self.cards = flashcardsContent.cards.shuffled()
    }
    
    // MARK: - Actions de l'Utilisateur
    
    /// Retourne la carte actuelle.
    func flipCurrentCard() {
        isCurrentCardFlipped.toggle()
    }
    
    /// L'utilisateur indique qu'il connaissait la réponse.
    func markAsKnown() {
        // TODO: Implémenter la logique du système Leitner (augmenter le 'leitnerBox')
        print("Carte '\(currentCard?.front ?? "")' marquée comme connue.")
        nextCard()
    }
    
    /// L'utilisateur indique qu'il ne connaissait pas la réponse.
    func markAsUnknown() {
        // TODO: Implémenter la logique du système Leitner (réinitialiser le 'leitnerBox' à 1)
        print("Carte '\(currentCard?.front ?? "")' marquée comme inconnue.")
        nextCard()
    }
    
    /// Passe à la carte suivante ou termine la session.
    private func nextCard() {
        if currentCardIndex < cards.count - 1 {
            isCurrentCardFlipped = false // S'assurer que la nouvelle carte est face visible
            currentCardIndex += 1
        } else {
            finishSession()
        }
    }
    
    /// Termine la session de révision.
    func finishSession() {
        isFinished = true
        print("Session de flashcards terminée !")
        
        // Créer et sauvegarder la session d'étude avec durée réelle
        Task {
            var session = StudySession(documentID: documentID, sessionType: .flashcards, startTime: startTime)
            session.endSession() // Définit endTime à maintenant
            
            let realDuration = session.duration
            print("✅ Session flashcards sauvegardée - Durée: \(Int(realDuration/60)) minutes \(Int(realDuration.truncatingRemainder(dividingBy: 60))) secondes")
            
            await saveSessionAction(session)
        }
    }
    
    /// Redémarre la session de révision.
    func restartSession() {
        currentCardIndex = 0
        isFinished = false
        isCurrentCardFlipped = false
        // On mélange à nouveau pour une nouvelle expérience.
        cards.shuffle()
    }
} 