import SwiftUI

/// Une vue qui affiche les résultats à la fin d'un quiz.
struct QuizResultView: View {
    
    /// Le ViewModel contenant les données du quiz terminé.
    @ObservedObject var viewModel: QuizPlayerViewModel
    
    var body: some View {
        VStack(spacing: 25) {
            
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
            
            Text("Quiz Terminé !")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Le score sera affiché ici plus tard
            Text("Bravo, vous avez terminé le quiz '\(viewModel.quizTitle)'.")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            Button("Recommencer le Quiz") {
                viewModel.restartQuiz()
            }
            .buttonStyle(.bordered)
            
            Button("Fermer") {
                // Logique pour fermer la vue du quiz
            }
        }
        .padding(40)
        .frame(maxWidth: 500)
    }
} 