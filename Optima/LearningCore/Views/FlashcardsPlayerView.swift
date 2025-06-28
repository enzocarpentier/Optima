import SwiftUI

/// La vue principale pour l'expérience de révision de flashcards.
struct FlashcardsPlayerView: View {
    
    /// Le ViewModel qui gère l'état et la logique de la session.
    @StateObject private var viewModel: FlashcardsPlayerViewModel
    
    // MARK: - Initialisation
    
    init(flashcardsContent: FlashcardsContent, title: String, documentID: UUID, onSave: @escaping (StudySession) async -> Void) {
        _viewModel = StateObject(wrappedValue: FlashcardsPlayerViewModel(flashcardsContent: flashcardsContent, title: title, documentID: documentID, onSave: onSave))
    }
    
    // MARK: - Corps de la Vue
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Affiche la vue de résultat si la session est terminée.
            if viewModel.isFinished {
                FlashcardsResultView(viewModel: viewModel)
            } else {
                
                // Entête avec titre et progression
                headerView
                
                Spacer()
                
                // Affiche la carte actuelle
                if let card = viewModel.currentCard {
                    FlashcardView(card: card, isFlipped: viewModel.isCurrentCardFlipped)
                        .onTapGesture {
                            withAnimation(.spring) {
                                viewModel.flipCurrentCard()
                            }
                        }
                }
                
                Spacer()
                
                // Affiche les boutons d'action si la carte est retournée
                if viewModel.isCurrentCardFlipped {
                    actionButtons
                        .transition(.scale.animation(.spring))
                }
                
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Vues Enfants
    
    private var headerView: some View {
        VStack {
            Text(viewModel.deckTitle)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .padding(.vertical)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 30) {
            Button(action: viewModel.markAsUnknown) {
                Label("Je ne savais pas", systemImage: "xmark")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .keyboardShortcut("x", modifiers: .command)
            
            Button(action: viewModel.markAsKnown) {
                Label("Je savais", systemImage: "checkmark")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .keyboardShortcut("s", modifiers: .command)
        }
        .padding(.horizontal)
    }
}

/// Une vue pour afficher l'écran des résultats de la session de flashcards.
struct FlashcardsResultView: View {
    @ObservedObject var viewModel: FlashcardsPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "hand.thumbsup.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Session Terminée !")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Bravo, vous avez révisé toutes les cartes du paquet '\(viewModel.deckTitle)' !")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                Button("Fermer") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Recommencer") {
                    viewModel.restartSession()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
} 