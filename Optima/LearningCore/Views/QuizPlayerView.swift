import SwiftUI

/// La vue principale pour l'expérience de quiz interactive.
struct QuizPlayerView: View {
    
    /// Le ViewModel qui gère l'état et la logique du quiz.
    @StateObject private var viewModel: QuizPlayerViewModel
    
    // MARK: - Initialisation
    
    init(quizContent: QuizContent, title: String, documentID: UUID, onSave: @escaping (StudySession) async -> Void) {
        // Initialise le ViewModel en utilisant @StateObject pour qu'il soit géré par la vue.
        _viewModel = StateObject(wrappedValue: QuizPlayerViewModel(quizContent: quizContent, title: title, documentID: documentID, onSave: onSave))
    }
    
    // MARK: - Corps de la Vue
    
    var body: some View {
        VStack(spacing: 20) {
            
            if viewModel.isFinished {
                QuizResultView(viewModel: viewModel)
            } else {
                // Entête avec titre et barre de progression
                headerView
                
                // Contenu principal du quiz
                if let question = viewModel.currentQuestion {
                    // Affiche la question actuelle
                    QuestionView(question: question, viewModel: viewModel)
                } else {
                    // Vue de chargement ou d'erreur si aucune question n'est disponible
                    Text("Chargement des questions...")
                        .font(.largeTitle)
                }
                
                // Pied de page avec le bouton de navigation
                footerView
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Vues Enfants
    
    private var headerView: some View {
        VStack {
            Text(viewModel.quizTitle)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .padding(.vertical)
        }
    }
    
    private var footerView: some View {
        HStack {
            Spacer()
            Button(action: viewModel.nextQuestion) {
                Text(viewModel.currentQuestionIndex == viewModel.questions.count - 1 ? "Terminer" : "Suivant")
                    .font(.headline)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isNextButtonDisabled)
            .keyboardShortcut(.return, modifiers: [])
        }
    }
    
    private var isNextButtonDisabled: Bool {
        !viewModel.hasAnsweredCurrentQuestion
    }
}

/// Une vue pour afficher une seule question et ses options.
struct QuestionView: View {
    let question: QuizQuestion
    @ObservedObject var viewModel: QuizPlayerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(question.question)
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 20)
            
            ForEach(question.options.indices, id: \.self) { index in
                OptionView(
                    text: question.options[index],
                    isSelected: viewModel.userSelections[question.id] == index
                ) {
                    viewModel.selectOption(optionIndex: index)
                }
            }
            
            Spacer()
        }
    }
}

/// Une vue réutilisable pour afficher un seul bouton d'option de réponse.
private struct OptionView: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    // L'icône passe au vert pour une visibilité maximale et un sens universel
                    .foregroundStyle(isSelected ? .green : .secondary)
                
                // Le texte reste dans la couleur primaire pour une lisibilité maximale
                Text(text)
                
                Spacer()
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            // La bordure utilise la couleur d'accentuation de la marque
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color("AccentColor") : .clear, lineWidth: 2)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
    }
} 