//
//  GenerationView.swift
//  AdaptiveUI
//
//  Vue de génération de contenu par l'IA
//  Interface pour créer quiz, flashcards, résumés
//

import SwiftUI

struct GenerationView: View {
    
    // MARK: - États
    
    // Type de contenu à générer, sélectionné par l'utilisateur
    @State private var generationType: GenerationType = .quiz
    
    // MARK: - Services
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        VStack(spacing: 0) {
            // Sélecteur de type de contenu
            Picker("Type de Génération", selection: $generationType) {
                ForEach(GenerationType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(.ultraThinMaterial)
            
            Divider()

            // Affiche le formulaire correspondant au type sélectionné
            switch generationType {
            case .quiz:
                QuizGenerationForm()
            case .flashcards:
                FlashcardsGenerationForm()
            case .summary:
                SummaryGenerationForm()
            case .explanation:
                ExplanationGenerationForm()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Génération de Contenu IA")
        .environmentObject(coordinator) // Passer le coordinateur aux vues enfants
    }
}

// MARK: - Types de Génération
enum GenerationType: String, CaseIterable, Identifiable {
    case quiz = "Quiz"
    case flashcards = "Flashcards"
    case summary = "Résumé"
    case explanation = "Explication"
    
    var id: Self { self }
}

// MARK: - Formulaires de Génération (Vues de substitution)

struct QuizGenerationForm: View {
    
    // MARK: - Environnement
    @EnvironmentObject private var coordinator: AppCoordinator

    // MARK: - États du Formulaire
    @State private var questionCount: Int = 10
    @State private var difficulty: QuizDifficulty = .medium
    @State private var includeMultipleChoice = true
    @State private var includeTrueFalse = true
    @State private var isGenerating = false
    @State private var generatedContent: GeneratedContentItem?
    @State private var generationError: String?
    @State private var showErrorAlert = false
    @State private var showResultView = false
    
    var body: some View {
        // Affiche un message si aucun document n'est sélectionné
        if coordinator.selectedDocument == nil {
            NoDocumentSelectedView()
        } else {
            Form {
                Section(header: Text("Options du Quiz pour \"\(coordinator.selectedDocument?.title ?? "")\"")) {
                    // Stepper pour le nombre de questions
                    Stepper("Nombre de questions : \(questionCount)", value: $questionCount, in: 5...20)
                    
                    // Sélecteur de difficulté
                    Picker("Difficulté", selection: $difficulty) {
                        ForEach(QuizDifficulty.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    
                    // Toggles pour les types de questions
                    Toggle("Inclure des QCM", isOn: $includeMultipleChoice)
                    Toggle("Inclure des Vrai/Faux", isOn: $includeTrueFalse)
                }
                
                // Action
                Section {
                    Button(action: {
                        Task { await generateQuiz() }
                    }) {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView()
                                    .scaleEffect(0.5)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            Text(isGenerating ? "Génération en cours..." : "Générer le Quiz")
                            Spacer()
                        }
                    }
                    .disabled(isGenerating || (!includeMultipleChoice && !includeTrueFalse))
                }
                
                // Section pour afficher le résultat
                if let content = generatedContent {
                    Section(header: Text("Résultat")) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            
                            if case let .quiz(quizContent) = content.content {
                                Text("\(quizContent.questions.count) questions ont été générées.")
                            }
                            
                            Spacer()
                            
                            Button("Afficher") {
                                showResultView = true
                            }
                        }
                    }
                }
            }
            .padding()
            .sheet(isPresented: $showResultView) {
                if let content = generatedContent,
                   case let .quiz(quizContent) = content.content,
                   let document = coordinator.selectedDocument {
                    QuizPlayerView(
                        quizContent: quizContent,
                        title: content.title,
                        documentID: document.id,
                        onSave: { session in
                            await coordinator.saveStudySession(session)
                        }
                    )
                }
            }
            .alert("Erreur de Génération", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(generationError ?? "Une erreur inconnue est survenue.")
            }
        }
    }
    
    /// Lance la génération du quiz
    private func generateQuiz() async {
        guard var document = coordinator.selectedDocument,
              let context = document.textContent else {
            generationError = "Le document sélectionné n'a pas de contenu textuel."
            showErrorAlert = true
            return
        }
        
        isGenerating = true
        generatedContent = nil
        
        do {
            let result = try await coordinator.aiService.generateQuiz(
                from: context,
                questionCount: questionCount,
                difficulty: difficulty.aiDifficulty
            )
            
            // Créer et sauvegarder le contenu généré
            let newContent = GeneratedContentItem(
                type: .quiz,
                title: "Quiz sur \(document.title)",
                sourceDocument: document.id,
                content: .quiz(result)
            )
            
            document.generatedContent.append(newContent)
            await coordinator.updateAndSaveDocument(document)
            
            self.generatedContent = newContent
            
        } catch {
            self.generationError = error.localizedDescription
            self.showErrorAlert = true
        }
        
        isGenerating = false
    }
}

/// Niveaux de difficulté pour le quiz
enum QuizDifficulty: String, CaseIterable, Identifiable {
    case easy = "Facile"
    case medium = "Moyen"
    case hard = "Difficile"
    
    var id: Self { self }
    
    // Mapper vers le type de l'AIService
    var aiDifficulty: DifficultyLevel {
        switch self {
        case .easy: return .beginner
        case .medium: return .intermediate
        case .hard: return .advanced
        }
    }
}

struct FlashcardsGenerationForm: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var cardCount: Int = 15
    @State private var isGenerating = false
    @State private var generatedContent: GeneratedContentItem?
    @State private var generationError: String?
    @State private var showErrorAlert = false
    @State private var showResultView = false

    var body: some View {
        if coordinator.selectedDocument == nil {
            NoDocumentSelectedView()
        } else {
            Form {
                Section(header: Text("Options des Flashcards pour \"\(coordinator.selectedDocument?.title ?? "")\"")) {
                    Stepper("Nombre de cartes : \(cardCount)", value: $cardCount, in: 5...50)
                }
                
                Section {
                    Button(action: {
                        Task { await generateFlashcards() }
                    }) {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView().scaleEffect(0.5)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            Text(isGenerating ? "Génération en cours..." : "Générer les Flashcards")
                            Spacer()
                        }
                    }
                    .disabled(isGenerating)
                }
                
                if let content = generatedContent {
                    Section(header: Text("Résultat")) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            
                            if case let .flashcards(flashcardsContent) = content.content {
                                Text("\(flashcardsContent.cards.count) flashcards ont été générées.")
                            }
                            
                            Spacer()
                            
                            Button("Afficher") {
                                showResultView = true
                            }
                        }
                    }
                }
            }
            .padding()
            .sheet(isPresented: $showResultView) {
                if let content = generatedContent, 
                   case let .flashcards(flashcardsContent) = content.content,
                   let document = coordinator.selectedDocument {
                    FlashcardsPlayerView(
                        flashcardsContent: flashcardsContent, 
                        title: content.title,
                        documentID: document.id,
                        onSave: { session in
                            await coordinator.saveStudySession(session)
                        }
                    )
                }
            }
            .alert("Erreur de Génération", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(generationError ?? "Une erreur inconnue est survenue.")
            }
        }
    }

    private func generateFlashcards() async {
        guard var document = coordinator.selectedDocument, let context = document.textContent else {
            generationError = "Le document sélectionné n'a pas de contenu textuel."
            showErrorAlert = true
            return
        }
        
        isGenerating = true
        generatedContent = nil
        
        do {
            let result = try await coordinator.aiService.generateFlashcards(from: context, cardCount: cardCount)
            
            let newContent = GeneratedContentItem(
                type: .flashcards,
                title: "Flashcards sur \(document.title)",
                sourceDocument: document.id,
                content: .flashcards(result)
            )
            
            document.generatedContent.append(newContent)
            await coordinator.updateAndSaveDocument(document)
            
            self.generatedContent = newContent
            
        } catch {
            self.generationError = error.localizedDescription
            self.showErrorAlert = true
        }
        
        isGenerating = false
    }
}

/// Vue réutilisable pour indiquer qu'aucun document n'est sélectionné
struct NoDocumentSelectedView: View {
    var body: some View {
        VStack {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Aucun document sélectionné")
                .font(.title2)
                .fontWeight(.medium)
            Text("Veuillez sélectionner un document dans la Bibliothèque pour commencer.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SummaryGenerationForm: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var summaryLength: SummaryLength = .medium
    @State private var isGenerating = false
    @State private var generatedContent: GeneratedContentItem?
    @State private var generationError: String?
    @State private var showErrorAlert = false
    @State private var showResultView = false

    var body: some View {
        if coordinator.selectedDocument == nil {
            NoDocumentSelectedView()
        } else {
            Form {
                Section(header: Text("Options du Résumé pour \"\(coordinator.selectedDocument?.title ?? "")\"")) {
                    Picker("Longueur du résumé", selection: $summaryLength) {
                        ForEach(SummaryLength.allCases) { length in
                            Text(length.rawValue).tag(length)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        Task { await generateSummary() }
                    }) {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView().scaleEffect(0.5)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            Text(isGenerating ? "Génération en cours..." : "Générer le Résumé")
                            Spacer()
                        }
                    }
                    .disabled(isGenerating)
                }
                
                if let content = generatedContent {
                    Section(header: Text("Résultat")) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            
                            if case let .summary(summaryContent) = content.content {
                                Text("Résumé généré (\(summaryContent.text.count) caractères).")
                            }
                            
                            Spacer()
                            
                            Button("Afficher") {
                                showResultView = true
                            }
                        }
                    }
                }
            }
            .padding()
            .sheet(isPresented: $showResultView) {
                if let content = generatedContent, case let .summary(summaryContent) = content.content {
                    SummaryDetailView(summaryContent: summaryContent)
                }
            }
            .alert("Erreur de Génération", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(generationError ?? "Une erreur inconnue est survenue.")
            }
        }
    }

    private func generateSummary() async {
        guard var document = coordinator.selectedDocument, let context = document.textContent else {
            generationError = "Le document sélectionné n'a pas de contenu textuel."
            showErrorAlert = true
            return
        }
        
        isGenerating = true
        generatedContent = nil
        
        do {
            let result = try await coordinator.aiService.summarizeContent(context, length: summaryLength)
            
            let newContent = GeneratedContentItem(
                type: .summary,
                title: "Résumé de \(document.title)",
                sourceDocument: document.id,
                content: .summary(result)
            )
            
            document.generatedContent.append(newContent)
            await coordinator.updateAndSaveDocument(document)
            
            self.generatedContent = newContent
            
        } catch {
            self.generationError = error.localizedDescription
            self.showErrorAlert = true
        }
        
        isGenerating = false
    }
}

struct ExplanationGenerationForm: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var conceptToExplain: String = ""
    @State private var isGenerating = false
    @State private var generatedContent: GeneratedContentItem?
    @State private var generationError: String?
    @State private var showErrorAlert = false
    @State private var showResultView = false

    var body: some View {
        if coordinator.selectedDocument == nil {
            NoDocumentSelectedView()
        } else {
            Form {
                Section(header: Text("Options de l'Explication pour \"\(coordinator.selectedDocument?.title ?? "")\"")) {
                    TextField("Concept à expliquer (ex: 'la photosynthèse')", text: $conceptToExplain)
                }
                
                Section {
                    Button(action: {
                        Task { await generateExplanation() }
                    }) {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView().scaleEffect(0.5)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            Text(isGenerating ? "Génération en cours..." : "Générer l'Explication")
                            Spacer()
                        }
                    }
                    .disabled(isGenerating || conceptToExplain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                if let content = generatedContent {
                    Section(header: Text("Résultat")) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            
                            if case let .explanation(explanationContent) = content.content {
                                Text("Explication générée (\(explanationContent.text.count) caractères).")
                            }
                            
                            Spacer()
                            
                            Button("Afficher") {
                                showResultView = true
                            }
                        }
                    }
                }
            }
            .padding()
            .sheet(isPresented: $showResultView) {
                if let content = generatedContent, case let .explanation(explanationContent) = content.content {
                    ExplanationDetailView(explanationContent: explanationContent)
                }
            }
            .alert("Erreur de Génération", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(generationError ?? "Une erreur inconnue est survenue.")
            }
        }
    }

    private func generateExplanation() async {
        guard var document = coordinator.selectedDocument, let context = document.textContent else {
            generationError = "Le document sélectionné n'a pas de contenu textuel."
            showErrorAlert = true
            return
        }
        
        let concept = conceptToExplain.trimmingCharacters(in: .whitespacesAndNewlines)
        isGenerating = true
        generatedContent = nil
        
        do {
            // TODO: Remplacer par le vrai profil utilisateur quand il sera disponible
            var tempProfile = UserProfile(name: "Utilisateur")
            tempProfile.learningStyle = .visual
            tempProfile.preferredDifficulty = .intermediate
            tempProfile.preferredExplanationStyle = .analogical
            
            let result = try await coordinator.aiService.explainConcept(concept, context: context, userProfile: tempProfile)
            
            let newContent = GeneratedContentItem(
                type: .explanation,
                title: "Explication de '\(concept)'",
                sourceDocument: document.id,
                content: .explanation(result)
            )
            
            document.generatedContent.append(newContent)
            await coordinator.updateAndSaveDocument(document)
            
            self.generatedContent = newContent
            
        } catch {
            self.generationError = error.localizedDescription
            self.showErrorAlert = true
        }
        
        isGenerating = false
    }
}

// J'ajoute la conformité à Identifiable ici pour que ça fonctionne dans le ForEach
//enum SummaryLength: String, CaseIterable {
//    case brief = "Bref"
//    case medium = "Moyen"
//    case detailed = "Détaillé"
//}
//
//extension SummaryLength: Identifiable {
//    var id: Self { self }
//}

#Preview {
    GenerationView()
        .environmentObject(AppCoordinator()) // Injecter un coordinateur pour la prévisualisation
        .frame(width: 400, height: 500)
} 