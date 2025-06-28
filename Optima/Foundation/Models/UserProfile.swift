//
//  UserProfile.swift
//  Foundation/Models
//
//  Profil utilisateur pour la personnalisation de l'expérience d'apprentissage
//  Préférences, historique et adaptation comportementale
//

import Foundation

/// Profil utilisateur personnalisé
/// Responsabilité : Personnalisation, préférences, adaptation de l'IA
struct UserProfile: Identifiable, Codable {
    
    // MARK: - Identité
    var id = UUID()
    var name: String
    var email: String?
    var dateCreated: Date
    
    // MARK: - Préférences d'Apprentissage
    var learningStyle: LearningStyle
    var preferredDifficulty: DifficultyLevel
    var studySchedule: StudySchedule
    var accessibilityNeeds: AccessibilityPreferences
    
    // MARK: - Préférences d'Interface
    var interfacePreferences: InterfacePreferences
    var notificationSettings: NotificationSettings
    
    // MARK: - Historique et Progression
    var totalStudyTime: TimeInterval = 0
    var documentsStudied: Set<UUID> = []
    var conceptsMastered: Set<String> = []
    var averageSessionRating: Double?
    
    // MARK: - Adaptation IA
    var aiPersonality: AIPersonality
    var preferredExplanationStyle: ExplanationStyle
    var adaptationHistory: [AdaptationEvent] = []
    
    // MARK: - Objectifs et Motivation
    var currentGoals: [LearningGoal] = []
    var achievements: [Achievement] = []
    var streaks: StreakTracker = StreakTracker()
    
    init(name: String) {
        self.name = name
        self.dateCreated = Date()
        self.learningStyle = .visual
        self.preferredDifficulty = .intermediate
        self.studySchedule = StudySchedule()
        self.accessibilityNeeds = AccessibilityPreferences()
        self.interfacePreferences = InterfacePreferences()
        self.notificationSettings = NotificationSettings()
        self.aiPersonality = .encouraging
        self.preferredExplanationStyle = .balanced
    }
}

// MARK: - Types de Préférences

/// Style d'apprentissage préféré
enum LearningStyle: String, CaseIterable, Codable {
    case visual = "Visuel"
    case auditory = "Auditif"
    case kinesthetic = "Kinesthésique"
    case readingWriting = "Lecture/Écriture"
    case multimodal = "Multimodal"
    
    var description: String {
        switch self {
        case .visual: return "Apprend mieux avec des images, diagrammes et cartes mentales"
        case .auditory: return "Apprend mieux en écoutant et en discutant"
        case .kinesthetic: return "Apprend mieux par la pratique et le mouvement"
        case .readingWriting: return "Apprend mieux en lisant et en écrivant"
        case .multimodal: return "Combine plusieurs styles d'apprentissage"
        }
    }
}

/// Horaires d'étude préférés
struct StudySchedule: Codable {
    var preferredTimes: [TimeSlot] = []
    var sessionDuration: TimeInterval = 1800 // 30 minutes
    var breakFrequency: TimeInterval = 300 // 5 minutes
    var weeklyGoal: TimeInterval = 3600 * 10 // 10 heures
    
    struct TimeSlot: Codable {
        let dayOfWeek: Int // 1-7
        let startHour: Int // 0-23
        let duration: TimeInterval
    }
}

/// Préférences d'accessibilité
struct AccessibilityPreferences: Codable {
    var dyslexiaSupport: Bool = false
    var highContrast: Bool = false
    var largerText: Bool = false
    var voiceOverEnabled: Bool = false
    var reducedMotion: Bool = false
    var focusMode: Bool = false
    var customFont: String?
    var readingSpeed: ReadingSpeed = .normal
    
    enum ReadingSpeed: String, CaseIterable, Codable {
        case slow = "Lente"
        case normal = "Normale"
        case fast = "Rapide"
    }
}

/// Préférences d'interface
struct InterfacePreferences: Codable {
    var theme: AppTheme = .system
    var sidebarWidth: Double = 300
    var fontSize: FontSize = .medium
    var animationsEnabled: Bool = true
    var soundEffectsEnabled: Bool = true
    var compactMode: Bool = false
    
    enum AppTheme: String, CaseIterable, Codable {
        case light = "Clair"
        case dark = "Sombre"
        case system = "Système"
    }
    
    enum FontSize: String, CaseIterable, Codable {
        case small = "Petite"
        case medium = "Moyenne"
        case large = "Grande"
        case extraLarge = "Très Grande"
    }
}

/// Paramètres de notifications
struct NotificationSettings: Codable {
    var studyReminders: Bool = true
    var achievementNotifications: Bool = true
    var progressUpdates: Bool = true
    var reminderTimes: [Date] = []
    var quietHours: QuietHours?
    
    struct QuietHours: Codable {
        let startHour: Int
        let endHour: Int
    }
}

/// Personnalité de l'IA
enum AIPersonality: String, CaseIterable, Codable {
    case encouraging = "Encourageante"
    case neutral = "Neutre"
    case challenging = "Exigeante"
    case friendly = "Amicale"
    case professional = "Professionnelle"
    
    var description: String {
        switch self {
        case .encouraging: return "Positive et motivante"
        case .neutral: return "Factuelle et directe"
        case .challenging: return "Pousse vers l'excellence"
        case .friendly: return "Décontractée et accessible"
        case .professional: return "Formelle et académique"
        }
    }
}

/// Style d'explication préféré
enum ExplanationStyle: String, CaseIterable, Codable {
    case simple = "Simple"
    case detailed = "Détaillée"
    case analogical = "Analogique"
    case example_based = "Par Exemples"
    case socratic = "Socratique"
    case balanced = "Équilibrée"
}

/// Événement d'adaptation de l'IA
struct AdaptationEvent: Identifiable, Codable {
    var id = UUID()
    let timestamp: Date
    let trigger: String
    let adaptation: String
    let effectiveness: Double?
}

/// Objectif d'apprentissage
struct LearningGoal: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var targetDate: Date
    var progress: Double = 0.0
    var isCompleted: Bool = false
    var category: GoalCategory
    
    enum GoalCategory: String, CaseIterable, Codable {
        case timeBasedLearning = "Temps d'Étude"
        case conceptMastery = "Maîtrise de Concepts"
        case documentCompletion = "Complétion de Cours"
        case skillDevelopment = "Développement de Compétences"
    }
}

/// Badge de réussite
struct Achievement: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let iconName: String
    let dateEarned: Date
    let category: AchievementCategory
    
    enum AchievementCategory: String, CaseIterable, Codable {
        case consistency = "Régularité"
        case mastery = "Maîtrise"
        case exploration = "Exploration"
        case improvement = "Amélioration"
    }
}

/// Suivi des séries
struct StreakTracker: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastStudyDate: Date?
    var streakType: StreakType = .daily
    
    enum StreakType: String, CaseIterable, Codable {
        case daily = "Quotidienne"
        case weekly = "Hebdomadaire"
        case custom = "Personnalisée"
    }
} 