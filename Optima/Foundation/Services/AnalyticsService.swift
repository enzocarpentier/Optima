import Foundation

/// Un service chargé de calculer et de fournir des statistiques d'apprentissage
/// à partir des sessions d'étude enregistrées.
@MainActor
final class AnalyticsService: ObservableObject {
    
    // MARK: - Propriétés Publiées
    
    @Published private(set) var totalStudyTime: TimeInterval = 0
    @Published private(set) var totalSessions: Int = 0
    @Published private(set) var averageQuizScore: Double?
    @Published private(set) var studyTimeByDay: [Date: TimeInterval] = [:]
    
    // MARK: - Initialisation
    
    init() {
        // Le service est maintenant initialisé vide.
        // Les données seront fournies de l'extérieur via la méthode 'process'.
    }
    
    // MARK: - Méthodes de Calcul
    
    /// Traite un tableau de sessions d'étude pour calculer les statistiques.
    func process(sessions: [StudySession]) {
        self.totalSessions = sessions.count
        self.totalStudyTime = sessions.reduce(0) { $0 + $1.duration }
        
        let quizScores = sessions.compactMap { $0.overallScore }
        if !quizScores.isEmpty {
            self.averageQuizScore = quizScores.reduce(0, +) / Double(quizScores.count)
        } else {
            self.averageQuizScore = nil
        }
        
        // Calculer le temps d'étude par jour
        var timeByDay: [Date: TimeInterval] = [:]
        for session in sessions {
            let day = Calendar.current.startOfDay(for: session.startTime)
            timeByDay[day, default: 0] += session.duration
        }
        self.studyTimeByDay = timeByDay
    }
    
    // MARK: - Fonctions Utilitaires Factices
    
//    private func createMockSession(on date: Date, duration: TimeInterval, score: Double?) -> StudySession {
//        var session = StudySession(documentID: UUID(), sessionType: .quiz)
//        session.endTime = date.addingTimeInterval(duration)
//        session.overallScore = score
//        // Pour le calcul par jour, on utilise la date de fin (ou de début, peu importe pour le mock)
//        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
//        session.startTime = Calendar.current.date(from: components)!
//        return session
//    }
} 