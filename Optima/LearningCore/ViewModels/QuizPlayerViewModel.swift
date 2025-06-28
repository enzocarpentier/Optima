import Foundation
import Combine

/// Le ViewModel qui gère la logique et l'état d'une session de quiz interactive.
@MainActor
final class QuizPlayerViewModel: ObservableObject {
    
    // MARK: - Propriétés Publiées
    
    @Published private(set) var quizTitle: String
    @Published private(set) var questions: [QuizQuestion] = []
    
    /// L'index de la question actuellement affichée.
    @Published private(set) var currentQuestionIndex: Int = 0
    
    /// Les réponses sélectionnées par l'utilisateur, [QuestionID: OptionIndex].
    @Published private(set) var userSelections: [UUID: Int] = [:]
    
    /// Indique si le quiz est terminé.
    @Published private(set) var isFinished: Bool = false
    
    /// La progression du quiz, de 0.0 à 1.0.
    var progress: Double {
        guard !questions.isEmpty else { return 0.0 }
        return Double(currentQuestionIndex + 1) / Double(questions.count)
    }
    
    /// La question actuellement affichée.
    var currentQuestion: QuizQuestion? {
        guard questions.indices.contains(currentQuestionIndex) else { return nil }
        return questions[currentQuestionIndex]
    }
    
    /// Calcule le score final du quiz.
    var finalScore: Double {
        guard !questions.isEmpty else { return 0.0 }
        
        let correctAnswers = questions.reduce(0) { total, question in
            if let selectedOption = userSelections[question.id], question.correctAnswers.contains(selectedOption) {
                return total + 1
            }
            return total
        }
        
        return Double(correctAnswers) / Double(questions.count)
    }
    
    /// Vérifie si l'utilisateur a répondu à la question actuelle.
    var hasAnsweredCurrentQuestion: Bool {
        guard let currentQuestion else { return false }
        return userSelections[currentQuestion.id] != nil
    }
    
    // MARK: - Session Tracking
    private let startTime: Date
    private let documentID: UUID
    private let saveSessionAction: (StudySession) async -> Void
    
    // MARK: - Initialisation
    
    init(quizContent: QuizContent, title: String, documentID: UUID, onSave: @escaping (StudySession) async -> Void) {
        self.questions = quizContent.questions
        self.quizTitle = title
        self.documentID = documentID
        self.saveSessionAction = onSave
        self.startTime = Date() // Capture du temps de début réel
    }
    
    // MARK: - Actions de l'Utilisateur
    
    /// Enregistre la sélection de l'utilisateur pour une question donnée.
    func selectOption(optionIndex: Int) {
        guard let currentQuestion else { return }
        userSelections[currentQuestion.id] = optionIndex
    }
    
    /// Passe à la question suivante, ou termine le quiz si c'est la dernière.
    func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            finishQuiz()
        }
    }
    
    /// Termine le quiz et calcule le score final.
    func finishQuiz() {
        // La logique de calcul du score sera ajoutée ici.
        isFinished = true
        print("Quiz terminé ! Score: \(finalScore)")
        
        // Créer et sauvegarder la session d'étude avec durée réelle
        Task {
            var session = StudySession(documentID: documentID, sessionType: .quiz, startTime: startTime)
            session.overallScore = finalScore
            session.endSession() // Définit endTime à maintenant
            
            let realDuration = session.duration
            print("✅ Session quiz sauvegardée - Durée: \(Int(realDuration/60)) minutes \(Int(realDuration.truncatingRemainder(dividingBy: 60))) secondes")
            
            await saveSessionAction(session)
        }
    }
    
    /// Redémarre le quiz depuis le début.
    func restartQuiz() {
        currentQuestionIndex = 0
        isFinished = false
        userSelections.removeAll()
    }
} 