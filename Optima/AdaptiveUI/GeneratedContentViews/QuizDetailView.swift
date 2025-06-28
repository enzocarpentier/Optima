import SwiftUI

/// Une vue qui affiche les détails d'un quiz généré.
struct QuizDetailView: View {
    let quizContent: QuizContent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Quiz : \(quizContent.questions.count) Questions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)

                ForEach(quizContent.questions.enumerated().map({ $0 }), id: \.element.id) { index, question in
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Question \(index + 1): \(question.question)")
                            .font(.headline)
                        
                        ForEach(question.options.indices, id: \.self) { optionIndex in
                            HStack {
                                Image(systemName: question.correctAnswers.contains(optionIndex) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(question.correctAnswers.contains(optionIndex) ? .green : .secondary)
                                Text(question.options[optionIndex])
                            }
                        }
                        
                        if let explanation = question.explanation {
                            Text("Explication : \(explanation)")
                                .font(.footnote)
                                .italic()
                                .foregroundStyle(.secondary)
                                .padding(.top, 5)
                        }
                    }
                    .padding()
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Détails du Quiz")
    }
} 