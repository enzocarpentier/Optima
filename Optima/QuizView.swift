import SwiftUI

struct QuizView: View {
    let qcmTest: QCMTest
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswers: [Int?] = []
    @State private var showResults = false
    @State private var score = 0
    @Environment(\.presentationMode) var presentationMode
    
    init(qcmTest: QCMTest) {
        self.qcmTest = qcmTest
        self._selectedAnswers = State(initialValue: Array(repeating: nil, count: qcmTest.questions.count))
    }
    
    private var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < qcmTest.questions.count else { return nil }
        return qcmTest.questions[currentQuestionIndex]
    }
    
    private var progressPercentage: Double {
        guard !qcmTest.questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex + 1) / Double(qcmTest.questions.count)
    }
    
    var body: some View {
        ZStack {
            UnifiedBackground()
                .edgesIgnoringSafeArea(.all)
            
            if showResults {
                ResultsView(
                    qcmTest: qcmTest,
                    selectedAnswers: selectedAnswers,
                    score: score,
                    onRetry: {
                        resetQuiz()
                    },
                    onClose: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            } else {
                VStack(spacing: 0) {
                    // En-tête avec progression
                    StudyHeaderView(
                        sessionTitle: "QCM",
                        documentName: qcmTest.documentName,
                        progress: progressPercentage,
                        progressText: "Question \(currentQuestionIndex + 1) sur \(qcmTest.questions.count)",
                        onClose: {
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                    
                    // Question actuelle
                    if let question = currentQuestion {
                        QuestionView(
                            question: question,
                            selectedAnswer: selectedAnswers[currentQuestionIndex],
                            onAnswerSelected: { answerIndex in
                                selectedAnswers[currentQuestionIndex] = answerIndex
                            }
                        )
                        .padding()
                    }
                    
                    // Boutons de navigation
                    NavigationButtonsView(
                        canGoBack: currentQuestionIndex > 0,
                        canGoNext: currentQuestionIndex < qcmTest.questions.count - 1,
                        isAnswered: selectedAnswers[currentQuestionIndex] != nil,
                        isLastQuestion: currentQuestionIndex == qcmTest.questions.count - 1,
                        onPrevious: {
                            if currentQuestionIndex > 0 {
                                currentQuestionIndex -= 1
                            }
                        },
                        onNext: {
                            if currentQuestionIndex < qcmTest.questions.count - 1 {
                                currentQuestionIndex += 1
                            }
                        },
                        onFinish: {
                            calculateScore()
                            showResults = true
                        }
                    )
                    .padding()
                }
            }
        }
    }
    
    private func resetQuiz() {
        currentQuestionIndex = 0
        selectedAnswers = Array(repeating: nil, count: qcmTest.questions.count)
        showResults = false
        score = 0
    }
    
    private func calculateScore() {
        var correctAnswers = 0
        for (index, question) in qcmTest.questions.enumerated() {
            if let selectedAnswerIndex = selectedAnswers[index],
               question.options[selectedAnswerIndex] == question.correctAnswer {
                correctAnswers += 1
            }
        }
        score = (correctAnswers * 100) / qcmTest.questions.count
    }
}

// MARK: - Composants

private struct QuestionView: View {
    let question: QuizQuestion
    let selectedAnswer: Int?
    let onAnswerSelected: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Question
            Text(question.question)
                .font(.title2.bold())
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            // Options de réponse
            VStack(spacing: 12) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    AnswerOptionView(
                        option: option,
                        index: index,
                        isSelected: selectedAnswer == index,
                        onTap: {
                            onAnswerSelected(index)
                        }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AnswerOptionView: View {
    let option: String
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    private let optionLabels = ["A", "B", "C", "D"]
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Label de l'option (A, B, C, D)
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Text(optionLabels[index])
                        .font(.headline.bold())
                        .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                }
                
                // Texte de l'option
                Text(option)
                    .font(.body)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isSelected ? Color.blue : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

private struct NavigationButtonsView: View {
    let canGoBack: Bool
    let canGoNext: Bool
    let isAnswered: Bool
    let isLastQuestion: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onFinish: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Bouton Précédent
            Button(action: onPrevious) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Précédent")
                }
                .font(.headline)
                .foregroundColor(canGoBack ? .white : .white.opacity(0.3))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(canGoBack ? Color.white.opacity(0.1) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(canGoBack ? 0.3 : 0.1), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canGoBack)
            
            Spacer()
            
            // Bouton Suivant ou Terminer
            Button(action: isLastQuestion ? onFinish : onNext) {
                HStack(spacing: 8) {
                    Text(isLastQuestion ? "Terminer" : "Suivant")
                    if !isLastQuestion {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.headline.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isAnswered ? Color.blue : Color.white.opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!isAnswered)
            .scaleEffect(isAnswered ? 1.0 : 0.95)
            .animation(.spring(response: 0.3), value: isAnswered)
        }
    }
}

// MARK: - Vue des résultats

private struct ResultsView: View {
    let qcmTest: QCMTest
    let selectedAnswers: [Int?]
    let score: Int
    let onRetry: () -> Void
    let onClose: () -> Void
    
    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
    
    private var scoreMessage: String {
        switch score {
        case 90...100: return "Excellent ! 🎉"
        case 80..<90: return "Très bien ! 👏"
        case 70..<80: return "Bien ! 👍"
        case 60..<70: return "Assez bien 🙂"
        default: return "Peut mieux faire 📚"
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Score principal
            VStack(spacing: 16) {
                Text(scoreMessage)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: Double(score) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(score)%")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                }
            }
            
            // Détails des réponses
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(qcmTest.questions.enumerated()), id: \.offset) { index, question in
                        QuestionResultView(
                            question: question,
                            questionNumber: index + 1,
                            selectedAnswer: selectedAnswers[index],
                            isCorrect: selectedAnswers[index] != nil ? question.options[selectedAnswers[index]!] == question.correctAnswer : false
                        )
                    }
                }
                .padding()
            }
            
            // Boutons d'action
            HStack(spacing: 16) {
                GlassButton(
                    title: "Recommencer",
                    icon: "arrow.clockwise",
                    color: .blue,
                    action: onRetry
                )
                
                GlassButton(
                    title: "Fermer",
                    icon: "xmark",
                    color: .gray,
                    action: onClose
                )
            }
            .padding()
        }
        .padding()
    }
}

private struct QuestionResultView: View {
    let question: QuizQuestion
    let questionNumber: Int
    let selectedAnswer: Int?
    let isCorrect: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Question \(questionNumber)")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)
                    .font(.title2)
            }
            
            Text(question.question)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
            
            if let selectedIndex = selectedAnswer {
                Text("Votre réponse: \(question.options[selectedIndex])")
                    .font(.subheadline)
                    .foregroundColor(isCorrect ? .green : .red)
            }
            
            if !isCorrect {
                Text("Bonne réponse: \(question.correctAnswer)")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            if let explanation = question.explanation {
                Text("Explication: \(explanation)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isCorrect ? Color.green.opacity(0.5) : Color.red.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleResponse = QuizResponse(
            questions: [
                QuizQuestion(
                    question: "Quelle est la capitale de la France ?",
                    options: ["Londres", "Paris", "Berlin", "Madrid"],
                    correctAnswer: "Paris",
                    explanation: "Paris est la capitale de la France depuis des siècles."
                )
            ],
            metadata: QuizMetadata(
                version: "1.0",
                difficulty: "Facile",
                category: "Géographie"
            )
        )
        
        let sampleQCM = QCMTest(
            documentId: UUID(),
            documentName: "Test de géographie",
            quizResponse: sampleResponse
        )
        
        QuizView(qcmTest: sampleQCM)
    }
}
