//
//  AIService.swift
//  Foundation/Services
//
//  Service d'intelligence artificielle pédagogique
//  Interface et configuration pour l'IA conversationnelle d'Optima
//

import Foundation

/// Service central d'intelligence artificielle pédagogique
/// Responsabilité : API IA, adaptation pédagogique, génération de contenu
@MainActor
final class AIService: ObservableObject {
    
    // MARK: - État du Service
    @Published var isConnected = false
    @Published var isProcessing = false
    @Published var lastError: AIError?
    @Published var needsAPIKey = true
    
    // MARK: - Configuration
    private var apiConfiguration: AIConfiguration
    private var conversationHistory: [ConversationMessage] = []
    
    // MARK: - Personnalisation
    private var currentPersonality: AIPersonality = .encouraging
    private var adaptationLevel: AdaptationLevel = .medium
    
    // MARK: - Session URL
    private let urlSession = URLSession.shared
    
    init() {
        self.apiConfiguration = AIConfiguration()
        Task {
            await checkAPIKey()
        }
    }
    
    // MARK: - Configuration API
    
    /// Met à jour la clé API et teste la connexion
    func setAPIKey(_ key: String) async {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 🔑 CORRECTION : Mise à jour sur MainActor pour garantir la réactivité UI
        await MainActor.run {
            apiConfiguration.apiKey = trimmedKey
            needsAPIKey = trimmedKey.isEmpty
        }
        
        // Sauvegarder dans UserDefaults (sécurisé pour les apps sandbox)
        UserDefaults.standard.set(apiConfiguration.apiKey, forKey: "gemini_api_key")
        
        if !needsAPIKey {
            _ = await testConnection()
        }
    }
    
    /// Met à jour le modèle IA utilisé
    func setModel(_ model: AIModel) async {
        await MainActor.run {
            apiConfiguration.model = model
        }
        
        // Sauvegarder le modèle dans UserDefaults
        UserDefaults.standard.set(model.rawValue, forKey: "selected_ai_model")
    }
    
    /// Charge la clé API sauvegardée depuis UserDefaults
    private func loadSavedAPIKey() {
        if let savedKey = UserDefaults.standard.string(forKey: "gemini_api_key"), !savedKey.isEmpty {
            // 🔑 CORRECTION : Mise à jour synchrone sur MainActor pour UI réactive
            Task { @MainActor in
                apiConfiguration.apiKey = savedKey
                needsAPIKey = false
            }
        }
    }
    
    /// Charge le modèle sauvegardé depuis UserDefaults
    private func loadSavedModel() {
        if let savedModelString = UserDefaults.standard.string(forKey: "selected_ai_model"),
           let savedModel = AIModel(rawValue: savedModelString) {
            Task { @MainActor in
                apiConfiguration.model = savedModel
            }
        }
    }
    
    /// Vérifie si une clé API est configurée
    private func checkAPIKey() async {
        loadSavedAPIKey()
        loadSavedModel()
        
        if !needsAPIKey {
            _ = await testConnection()
        }
    }
    
    // MARK: - Interface Principale Gemini API
    
    /// Génère un quiz basé sur le contenu fourni
    func generateQuiz(
        from content: String,
        questionCount: Int = 5,
        difficulty: DifficultyLevel = .intermediate
    ) async throws -> QuizContent {
        
        guard !needsAPIKey else {
            throw AIError.invalidConfiguration
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let prompt = buildQuizPrompt(content: content, questionCount: questionCount, difficulty: difficulty)
        
        do {
            let response = try await makeGeminiRequest(prompt: prompt)
            let quizContent = try parseQuizResponse(response)
            return quizContent
        } catch {
            lastError = error as? AIError ?? AIError.apiError(error.localizedDescription)
            throw lastError!
        }
    }
    
    /// Génère des flashcards sur un sujet
    func generateFlashcards(
        from content: String,
        cardCount: Int = 10,
        categories: [String] = []
    ) async throws -> FlashcardsContent {
        
        guard !needsAPIKey else {
            throw AIError.invalidConfiguration
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let prompt = buildFlashcardsPrompt(content: content, cardCount: cardCount, categories: categories)
        
        do {
            let response = try await makeGeminiRequest(prompt: prompt)
            let flashcardsContent = try parseFlashcardsResponse(response)
            return flashcardsContent
        } catch {
            lastError = error as? AIError ?? AIError.apiError(error.localizedDescription)
            throw lastError!
        }
    }
    
    /// Explique un concept de manière personnalisée
    func explainConcept(
        _ concept: String,
        context: String,
        userProfile: UserProfile
    ) async throws -> ExplanationContent {
        
        guard !needsAPIKey else {
            throw AIError.invalidConfiguration
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let prompt = buildExplanationPrompt(concept: concept, context: context, userProfile: userProfile)
        
        do {
            let response = try await makeGeminiRequest(prompt: prompt)
            let explanationContent = try parseExplanationResponse(response)
            return explanationContent
        } catch {
            lastError = error as? AIError ?? AIError.apiError(error.localizedDescription)
            throw lastError!
        }
    }
    
    /// Résume un contenu académique
    func summarizeContent(
        _ content: String,
        length: SummaryLength = .medium,
        focus: [String] = []
    ) async throws -> SummaryContent {
        
        guard !needsAPIKey else {
            throw AIError.invalidConfiguration
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let prompt = buildSummaryPrompt(content: content, length: length, focus: focus)
        
        do {
            let response = try await makeGeminiRequest(prompt: prompt)
            let summaryContent = try parseSummaryResponse(response)
            return summaryContent
        } catch {
            lastError = error as? AIError ?? AIError.apiError(error.localizedDescription)
            throw lastError!
        }
    }
    
    /// Dialogue conversationnel socratique
    func startConversation(
        about topic: String,
        with context: String
    ) async throws -> ConversationResponse {
        
        guard !needsAPIKey else {
            throw AIError.invalidConfiguration
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let prompt = buildConversationPrompt(topic: topic, context: context)
        
        do {
            let response = try await makeGeminiRequest(prompt: prompt)
            let conversationResponse = try parseConversationResponse(response)
            
            // Ajouter à l'historique
            conversationHistory.append(ConversationMessage(
                role: .user,
                content: "À propos de: \(topic)",
                timestamp: Date()
            ))
            conversationHistory.append(ConversationMessage(
                role: .assistant,
                content: conversationResponse.message,
                timestamp: Date()
            ))
            
            return conversationResponse
        } catch {
            lastError = error as? AIError ?? AIError.apiError(error.localizedDescription)
            throw lastError!
        }
    }
    
    /// Continue une conversation existante
    func continueConversation(
        with message: String
    ) async throws -> ConversationResponse {
        
        guard !needsAPIKey else {
            throw AIError.invalidConfiguration
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        let prompt = buildContinueConversationPrompt(message: message, history: conversationHistory)
        
        do {
            let response = try await makeGeminiRequest(prompt: prompt)
            let conversationResponse = try parseConversationResponse(response)
            
            // Ajouter à l'historique
            conversationHistory.append(ConversationMessage(
                role: .user,
                content: message,
                timestamp: Date()
            ))
            conversationHistory.append(ConversationMessage(
                role: .assistant,
                content: conversationResponse.message,
                timestamp: Date()
            ))
            
            return conversationResponse
        } catch {
            lastError = error as? AIError ?? AIError.apiError(error.localizedDescription)
            throw lastError!
        }
    }
    
    // MARK: - API Gemini Core
    
    /// Effectue une requête à l'API Gemini avec diagnostics avancés
    private func makeGeminiRequest(prompt: String) async throws -> String {
        guard !apiConfiguration.apiKey.isEmpty else {
            throw AIError.invalidConfiguration
        }
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(apiConfiguration.model.rawValue):generateContent?key=\(apiConfiguration.apiKey)"
        
        // 🔍 DIAGNOSTIC : Afficher l'URL générée pour vérification
        print("🔍 URL générée pour l'API Gemini:")
        print("   \(urlString)")
        print("🔍 Modèle utilisé: \(apiConfiguration.model.rawValue)")
        
        guard let url = URL(string: urlString) else {
            print("🔍 ❌ URL malformée!")
            throw AIError.apiError("URL invalide: \(urlString)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = apiConfiguration.timeout
        
        // 🔍 DIAGNOSTIC : Ajouter User-Agent pour éviter le blocage
        request.setValue("OptimaApp/1.0", forHTTPHeaderField: "User-Agent")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": apiConfiguration.maxTokens,
                "temperature": apiConfiguration.temperature
            ]
        ]
        
        // 🔍 DIAGNOSTIC : Afficher le body de la requête  
        if let bodyData = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted),
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("🔍 Body de la requête JSON:")
            print(bodyString)
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("🔍 ❌ Erreur de sérialisation JSON: \(error)")
            throw AIError.invalidResponse
        }
        
        print("🔍 Envoi de la requête...")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("🔍 ❌ Pas de réponse HTTP valide")
                throw AIError.connectionFailed
            }
            
            // 🔍 DIAGNOSTIC : Afficher tous les détails de la réponse
            print("🔍 Code de statut HTTP reçu: \(httpResponse.statusCode)")
            print("🔍 Headers de réponse: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 Contenu de la réponse:")
                print(responseString)
            }
            
            // Vérifier le code de statut avec plus de détails
            switch httpResponse.statusCode {
            case 200:
                print("🔍 ✅ Statut 200 - Succès!")
                break
            case 400:
                let apiMessage = parseErrorMessage(from: data) ?? "La requête est malformée ou contient des paramètres invalides."
                print("🔍 ❌ Erreur 400 - \(apiMessage)")
                throw AIError.apiError(apiMessage)
            case 401:
                print("🔍 ❌ Erreur 401 - Authentification échouée")
                throw AIError.invalidConfiguration
            case 403:
                let apiMessage = parseErrorMessage(from: data) ?? "L'accès est refusé. Vérifiez les permissions de votre clé API."
                print("🔍 ❌ Erreur 403 - \(apiMessage)")
                throw AIError.apiError(apiMessage)
            case 404:
                let apiMessage = parseErrorMessage(from: data) ?? "Le modèle '\(apiConfiguration.model.rawValue)' n'a pas été trouvé."
                print("🔍 ❌ Erreur 404 - \(apiMessage)")
                throw AIError.apiError(apiMessage)
            case 429:
                print("🔍 ❌ Erreur 429 - Limite de taux dépassée")
                throw AIError.rateLimitExceeded
            case 500...599:
                let apiMessage = parseErrorMessage(from: data) ?? "Erreur interne du serveur Gemini."
                print("🔍 ❌ Erreur serveur \(httpResponse.statusCode): \(apiMessage)")
                throw AIError.apiError(apiMessage)
            default:
                let apiMessage = parseErrorMessage(from: data) ?? "Une erreur inattendue est survenue."
                print("🔍 ❌ Code d'erreur inattendu \(httpResponse.statusCode): \(apiMessage)")
                throw AIError.apiError("Erreur \(httpResponse.statusCode): \(apiMessage)")
            }
            
            // Parser la réponse JSON
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("🔍 ❌ Impossible de parser le JSON de réponse")
                throw AIError.invalidResponse
            }
            
            // Vérifier s'il y a des erreurs dans la réponse
            if let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("🔍 ❌ Erreur dans la réponse JSON: \(message)")
                throw AIError.apiError("Erreur API Gemini: \(message)")
            }
            
            guard let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                print("🔍 ❌ Structure de réponse inattendue:")
                print(json)
                throw AIError.invalidResponse
            }
            
            print("🔍 ✅ Réponse reçue avec succès!")
            print("🔍 Texte reçu: \(text.prefix(100))...")
            return text
            
        } catch let error as AIError {
            print("🔍 ❌ AIError: \(error)")
            throw error
        } catch let urlError as URLError {
            // Diagnostic détaillé des erreurs réseau
            print("🔍 ❌ URLError détecté:")
            print("   Code: \(urlError.code)")
            print("   Description: \(urlError.localizedDescription)")
            print("   URL: \(urlError.failingURL?.absoluteString ?? "N/A")")
            
            switch urlError.code {
            case .notConnectedToInternet:
                throw AIError.connectionFailed
            case .cannotFindHost:
                throw AIError.apiError("Impossible de résoudre l'adresse du serveur Gemini")
            case .timedOut:
                throw AIError.connectionFailed
            case .badURL:
                throw AIError.apiError("URL malformée: \(urlString)")
            case .cannotConnectToHost:
                throw AIError.apiError("Impossible de se connecter au serveur Gemini")
            case .networkConnectionLost:
                throw AIError.connectionFailed
            default:
                throw AIError.apiError("Erreur réseau: \(urlError.localizedDescription)")
            }
        } catch {
            print("🔍 ❌ Erreur inconnue: \(error)")
            throw AIError.apiError("Erreur inconnue: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Construction des Prompts
    
    private func buildQuizPrompt(content: String, questionCount: Int, difficulty: DifficultyLevel) -> String {
        return """
        Tu es un expert en création de quiz éducatifs. Créé un quiz à partir du contenu suivant.
        
        INSTRUCTIONS:
        - Créé exactement \(questionCount) questions
        - Niveau de difficulté: \(difficulty.rawValue)
        - Format JSON strict suivant:
        
        {
          "questions": [
            {
              "question": "Question ici?",
              "type": "QCM",
              "options": ["Option A", "Option B", "Option C", "Option D"],
              "correctAnswers": [0],
              "explanation": "Explication de la réponse",
              "points": 1
            }
          ],
          "timeLimit": 300,
          "passingScore": 0.7
        }
        
        CONTENU À ANALYSER:
        \(content)
        
        Réponds UNIQUEMENT avec le JSON, sans texte additionnel.
        """
    }
    
    private func buildFlashcardsPrompt(content: String, cardCount: Int, categories: [String]) -> String {
        let categoriesText = categories.isEmpty ? "automatiques" : categories.joined(separator: ", ")
        
        return """
        Tu es un expert en création de flashcards éducatives. Créé des flashcards à partir du contenu suivant.
        
        INSTRUCTIONS:
        - Créé exactement \(cardCount) flashcards
        - Catégories: \(categoriesText)
        - Format JSON strict suivant:
        
        {
          "cards": [
            {
              "front": "Question ou concept",
              "back": "Réponse ou explication",
              "category": "Catégorie",
              "difficulty": "Intermédiaire"
            }
          ],
          "categories": ["Cat1", "Cat2"]
        }
        
        CONTENU À ANALYSER:
        \(content)
        
        Réponds UNIQUEMENT avec le JSON, sans texte additionnel.
        """
    }
    
    private func buildExplanationPrompt(concept: String, context: String, userProfile: UserProfile) -> String {
        return """
        Tu es un tuteur pédagogique expert. Explique le concept suivant de manière personnalisée.
        
        CONCEPT: \(concept)
        CONTEXTE: \(context)
        STYLE D'APPRENTISSAGE: \(userProfile.learningStyle.rawValue)
        NIVEAU: \(userProfile.preferredDifficulty.rawValue)
        STYLE D'EXPLICATION: \(userProfile.preferredExplanationStyle.rawValue)
        
        FORMAT JSON:
        {
          "text": "Explication principale",
          "examples": ["Exemple 1", "Exemple 2"],
          "analogies": ["Analogie 1"],
          "visualDescriptions": ["Description visuelle"]
        }
        
        Réponds UNIQUEMENT avec le JSON, sans texte additionnel.
        """
    }
    
    private func buildSummaryPrompt(content: String, length: SummaryLength, focus: [String]) -> String {
        let focusText = focus.isEmpty ? "général" : focus.joined(separator: ", ")
        
        return """
        Tu es un expert en résumé académique. Résume le contenu suivant.
        
        LONGUEUR: \(length.rawValue)
        FOCUS: \(focusText)
        
        FORMAT JSON:
        {
          "text": "Résumé principal",
          "keyPoints": ["Point clé 1", "Point clé 2"],
          "concepts": [
            {
              "name": "Concept",
              "definition": "Définition",
              "importance": "Élevée",
              "relatedConcepts": ["Concept lié"]
            }
          ]
        }
        
        CONTENU:
        \(content)
        
        Réponds UNIQUEMENT avec le JSON, sans texte additionnel.
        """
    }
    
    private func buildConversationPrompt(topic: String, context: String) -> String {
        return """
        Tu es un tuteur socratique intelligent. Commence une conversation pédagogique sur le sujet.
        
        SUJET: \(topic)
        CONTEXTE: \(context)
        PERSONNALITÉ: \(currentPersonality.rawValue)
        
        FORMAT JSON:
        {
          "message": "Message de début de conversation",
          "suggestedQuestions": ["Question 1", "Question 2"],
          "relatedConcepts": ["Concept 1", "Concept 2"],
          "confidence": 0.9,
          "reasoning": "Raisonnement optionnel"
        }
        
        Réponds UNIQUEMENT avec le JSON, sans texte additionnel.
        """
    }
    
    private func buildContinueConversationPrompt(message: String, history: [ConversationMessage]) -> String {
        let historyText = history.suffix(6).map { "\($0.role.rawValue): \($0.content)" }.joined(separator: "\n")
        
        return """
        Tu es un tuteur socratique. Continue cette conversation pédagogique.
        
        HISTORIQUE:
        \(historyText)
        
        NOUVEAU MESSAGE: \(message)
        PERSONNALITÉ: \(currentPersonality.rawValue)
        
        FORMAT JSON:
        {
          "message": "Réponse pédagogique",
          "suggestedQuestions": ["Question 1", "Question 2"],
          "relatedConcepts": ["Concept 1"],
          "confidence": 0.9,
          "reasoning": "Raisonnement"
        }
        
        Réponds UNIQUEMENT avec le JSON, sans texte additionnel.
        """
    }
    
    // MARK: - Parsers JSON
    
    /// Nettoie une chaîne JSON en retirant les marqueurs de code Markdown
    private func cleanJSONString(from string: String) -> String {
        var text = string.trimmingCharacters(in: .whitespacesAndNewlines)

        let jsonPrefix = "```json"
        let regularPrefix = "```"
        let suffix = "```"

        if text.hasPrefix(jsonPrefix) {
            text = String(text.dropFirst(jsonPrefix.count))
        } else if text.hasPrefix(regularPrefix) {
            text = String(text.dropFirst(regularPrefix.count))
        }

        if text.hasSuffix(suffix) {
            text = String(text.dropLast(suffix.count))
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Tente de parser un message d'erreur depuis une réponse JSON de l'API
    private func parseErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let errorDict = json["error"] as? [String: Any],
              let message = errorDict["message"] as? String else {
            return nil
        }
        // Nettoyer le message pour enlever les détails techniques si besoin
        return message.components(separatedBy: ". Request ID:").first
    }
    
    private func parseQuizResponse(_ jsonString: String) throws -> QuizContent {
        let cleanedJSON = cleanJSONString(from: jsonString)
        guard let jsonData = cleanedJSON.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let questionsArray = json["questions"] as? [[String: Any]] else {
            throw AIError.invalidResponse
        }
        
        var questions: [QuizQuestion] = []
        
        for questionData in questionsArray {
            guard let questionText = questionData["question"] as? String,
                  let typeString = questionData["type"] as? String,
                  let options = questionData["options"] as? [String],
                  let correctAnswers = questionData["correctAnswers"] as? [Int],
                  let points = questionData["points"] as? Int else {
                continue
            }
            
            let type = QuizQuestion.QuestionType(rawValue: typeString) ?? .multipleChoice
            let explanation = questionData["explanation"] as? String
            
            let question = QuizQuestion(
                question: questionText,
                type: type,
                options: options,
                correctAnswers: correctAnswers,
                explanation: explanation,
                points: points
            )
            
            questions.append(question)
        }
        
        let timeLimit = json["timeLimit"] as? TimeInterval ?? 300
        let passingScore = json["passingScore"] as? Double ?? 0.7
        
        return QuizContent(
            questions: questions,
            timeLimit: timeLimit,
            passingScore: passingScore
        )
    }
    
    private func parseFlashcardsResponse(_ jsonString: String) throws -> FlashcardsContent {
        let cleanedJSON = cleanJSONString(from: jsonString)
        guard let jsonData = cleanedJSON.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let cardsArray = json["cards"] as? [[String: Any]] else {
            throw AIError.invalidResponse
        }
        
        var cards: [Flashcard] = []
        
        for cardData in cardsArray {
            guard let front = cardData["front"] as? String,
                  let back = cardData["back"] as? String else {
                continue
            }
            
            let category = cardData["category"] as? String
            let difficultyString = cardData["difficulty"] as? String ?? "Intermédiaire"
            let difficulty = DifficultyLevel(rawValue: difficultyString) ?? .intermediate
            
            let card = Flashcard(
                front: front,
                back: back,
                category: category,
                difficulty: difficulty
            )
            
            cards.append(card)
        }
        
        let categories = json["categories"] as? [String] ?? []
        
        return FlashcardsContent(cards: cards, categories: categories)
    }
    
    private func parseExplanationResponse(_ jsonString: String) throws -> ExplanationContent {
        let cleanedJSON = cleanJSONString(from: jsonString)
        guard let jsonData = cleanedJSON.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let text = json["text"] as? String else {
            throw AIError.invalidResponse
        }
        
        let examples = json["examples"] as? [String] ?? []
        let analogies = json["analogies"] as? [String] ?? []
        let visualDescriptions = json["visualDescriptions"] as? [String] ?? []
        
        return ExplanationContent(
            text: text,
            examples: examples,
            analogies: analogies,
            visualDescriptions: visualDescriptions
        )
    }
    
    private func parseSummaryResponse(_ jsonString: String) throws -> SummaryContent {
        let cleanedJSON = cleanJSONString(from: jsonString)
        guard let jsonData = cleanedJSON.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let text = json["text"] as? String else {
            throw AIError.invalidResponse
        }
        
        let keyPoints = json["keyPoints"] as? [String] ?? []
        
        var concepts: [ConceptSummary] = []
        if let conceptsArray = json["concepts"] as? [[String: Any]] {
            for conceptData in conceptsArray {
                guard let name = conceptData["name"] as? String,
                      let definition = conceptData["definition"] as? String else {
                    continue
                }
                
                let importanceString = conceptData["importance"] as? String ?? "Moyenne"
                let importance = ConceptSummary.ImportanceLevel(rawValue: importanceString) ?? .medium
                let relatedConcepts = conceptData["relatedConcepts"] as? [String] ?? []
                
                let concept = ConceptSummary(
                    name: name,
                    definition: definition,
                    importance: importance,
                    relatedConcepts: relatedConcepts
                )
                
                concepts.append(concept)
            }
        }
        
        return SummaryContent(text: text, keyPoints: keyPoints, concepts: concepts)
    }
    
    private func parseConversationResponse(_ jsonString: String) throws -> ConversationResponse {
        let cleanedJSON = cleanJSONString(from: jsonString)
        guard let jsonData = cleanedJSON.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let message = json["message"] as? String else {
            throw AIError.invalidResponse
        }
        
        let suggestedQuestions = json["suggestedQuestions"] as? [String] ?? []
        let relatedConcepts = json["relatedConcepts"] as? [String] ?? []
        let confidence = json["confidence"] as? Double ?? 0.8
        let reasoning = json["reasoning"] as? String
        
        return ConversationResponse(
            message: message,
            suggestedQuestions: suggestedQuestions,
            relatedConcepts: relatedConcepts,
            confidence: confidence,
            reasoning: reasoning
        )
    }
    
    // MARK: - Configuration et Personnalisation
    
    func updatePersonality(_ personality: AIPersonality) {
        currentPersonality = personality
    }
    
    func setAdaptationLevel(_ level: AdaptationLevel) {
        adaptationLevel = level
    }
    
    func resetConversation() {
        conversationHistory.removeAll()
    }
    
    // MARK: - Test de Connexion Avancé
    
    /// Teste la connexion avec fallback automatique entre différents modèles
    func testConnectionWithFallback() async -> (success: Bool, workingModel: AIModel?, error: String?) {
        guard !needsAPIKey else {
            await MainActor.run {
                isConnected = false
            }
            return (false, nil, "Clé API manquante")
        }
        
        // 🔍 DIAGNOSTIC : Test de résolution DNS spécifique
        print("🔍 === DIAGNOSTIC GEMINI API ===")
        print("🔍 Test de résolution DNS pour generativelanguage.googleapis.com...")
        
        // Test de résolution DNS spécifique pour le domaine Gemini
        do {
            let testURL = URL(string: "https://generativelanguage.googleapis.com")!
            var request = URLRequest(url: testURL)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 10.0
            
            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 ✅ DNS résolution OK pour Gemini (Status: \(httpResponse.statusCode))")
            }
        } catch let urlError as URLError {
            print("🔍 ❌ Problème de résolution DNS pour Gemini: \(urlError.localizedDescription)")
            
            // Analyser le type d'erreur DNS
            let errorMessage: String
            switch urlError.code {
            case .cannotFindHost:
                errorMessage = "Impossible de résoudre l'adresse du serveur Gemini. Votre réseau bloque peut-être l'accès à Google APIs. Vérifiez votre connexion et les paramètres de proxy/firewall."
            case .notConnectedToInternet:
                errorMessage = "Pas de connexion Internet"
            case .timedOut:
                errorMessage = "Délai d'attente dépassé - vérifiez votre connexion Internet"
            case .cannotConnectToHost:
                errorMessage = "Impossible de se connecter au serveur Gemini - votre réseau bloque peut-être l'accès"
            case .networkConnectionLost:
                errorMessage = "Connexion réseau perdue"
            default:
                errorMessage = "Erreur de réseau: \(urlError.localizedDescription)"
            }
            
            await MainActor.run {
                isConnected = false
                self.lastError = AIError.connectionFailed
            }
            
            return (false, nil, errorMessage)
        } catch {
            print("🔍 ❌ Erreur de test DNS: \(error)")
        }
        
        // Liste des modèles à tester par ordre de préférence
        let modelsToTest: [AIModel] = [
            .gemini20FlashLiteDot,  // Format exact de votre curl
            .gemini20FlashLite,     // Format standard
            .gemini20Flash,         // Modèle de base
            .gemini15Flash          // Fallback stable
        ]
        
        print("🔍 Test de \(modelsToTest.count) modèles disponibles...")
        
        var lastError: Error?
        
        for model in modelsToTest {
            print("🔍 Test du modèle: \(model.rawValue)")
            
            // Sauvegarder temporairement le modèle actuel
            _ = apiConfiguration.model
            apiConfiguration.model = model
            
            do {
                _ = try await makeGeminiRequest(prompt: "Test")
                
                // Si on arrive ici, le modèle fonctionne !
                await MainActor.run {
                    isConnected = true
                    self.lastError = nil
                    needsAPIKey = false
                }
                
                print("🔍 ✅ Modèle fonctionnel trouvé: \(model.rawValue)")
                return (true, model, nil)
                
            } catch {
                print("🔍 ❌ Modèle \(model.rawValue) échoué: \(error)")
                lastError = error
                // Continuer avec le modèle suivant
            }
        }
        
        // Aucun modèle ne fonctionne - analyser la dernière erreur
        await MainActor.run {
            isConnected = false
            self.lastError = AIError.connectionFailed
        }
        
        // Fournir un message d'erreur plus précis avec solutions
        let errorMessage: String
        if let lastError = lastError {
            if lastError.localizedDescription.contains("cannotFindHost") ||
               lastError.localizedDescription.contains("Impossible de résoudre") {
                errorMessage = """
                Impossible de résoudre l'adresse du serveur Gemini.
                
                Solutions possibles :
                • Vérifiez que votre connexion Internet fonctionne
                • Votre réseau d'entreprise bloque peut-être Google APIs
                • Essayez de désactiver temporairement le VPN/Proxy
                • Contactez votre administrateur réseau si nécessaire
                """
            } else if lastError.localizedDescription.contains("Internet connection appears to be offline") ||
                      lastError.localizedDescription.contains("network connection was lost") {
                errorMessage = "Pas de connexion Internet - vérifiez votre connexion réseau"
            } else if lastError.localizedDescription.contains("Invalid authentication credentials") ||
                      lastError.localizedDescription.contains("API key") ||
                      lastError.localizedDescription.contains("401") {
                errorMessage = "Clé API invalide - vérifiez votre clé dans Google AI Studio"
            } else if lastError.localizedDescription.contains("403") {
                errorMessage = "Accès refusé - vérifiez votre clé API et ses permissions"
            } else if lastError.localizedDescription.contains("404") {
                errorMessage = "Modèle non trouvé - le modèle n'est peut-être pas encore disponible"
            } else if lastError.localizedDescription.contains("429") {
                errorMessage = "Limite de taux atteinte - attendez quelques minutes et réessayez"
            } else {
                errorMessage = "Erreur de connexion: \(lastError.localizedDescription)"
            }
        } else {
            errorMessage = "Aucun modèle disponible ne fonctionne"
        }
        
        print("🔍 ❌ Test échoué: \(errorMessage)")
        return (false, nil, errorMessage)
    }
    
    /// Teste la connexion avec le modèle actuel
    func testConnection() async -> Bool {
        let result = await testConnectionWithFallback()
        
        if result.success, let workingModel = result.workingModel {
            // Mettre à jour le modèle vers celui qui fonctionne
            await MainActor.run {
                apiConfiguration.model = workingModel
            }
            
            // Sauvegarder le modèle qui fonctionne
            UserDefaults.standard.set(workingModel.rawValue, forKey: "selected_ai_model")
            print("🔍 ✅ Configuration sauvegardée avec le modèle: \(workingModel.rawValue)")
        }
        
        return result.success
    }
}

// MARK: - Types de Données IA

/// Configuration de l'API IA
struct AIConfiguration {
    var apiEndpoint: String = "https://generativelanguage.googleapis.com/v1beta"
    var apiKey: String = ""
    var model: AIModel = .gemini20FlashLite
    var maxTokens: Int = 2000
    var temperature: Double = 0.7
    var timeout: TimeInterval = 30.0
}

/// Modèles IA disponibles - Toutes les variantes possibles pour assurer la compatibilité maximale
enum AIModel: String, CaseIterable {
    // Tous les formats possibles pour Gemini 2.0
    case gemini20FlashLiteDot = "gemini-2.0.flash-lite"      // Format exemple curl exact
    case gemini20FlashLite = "gemini-2.0-flash-lite"         // Format standard
    case gemini20Flash = "gemini-2.0-flash"                  // Modèle de base 2.0
    case gemini20FlashOfficial = "gemini-2.0-flash-lite-v2"  // Format officiel alternatif
    
    // Modèles Gemini 1.5 (stables et prouvés)
    case gemini15Flash = "gemini-1.5-flash"                  // Très stable
    case gemini15Pro = "gemini-1.5-pro"                      // Très stable
    case gemini15Flash8B = "gemini-1.5-flash-8b"             // Version légère
    
    var displayName: String {
        switch self {
        case .gemini20FlashLiteDot: return "Gemini 2.0.Flash-Lite (Curl)"
        case .gemini20FlashLite: return "Gemini 2.0 Flash Lite"
        case .gemini20Flash: return "Gemini 2.0 Flash"
        case .gemini20FlashOfficial: return "Gemini 2.0 Flash Lite (Officiel)"
        case .gemini15Flash: return "Gemini 1.5 Flash (Stable)"
        case .gemini15Pro: return "Gemini 1.5 Pro (Stable)"
        case .gemini15Flash8B: return "Gemini 1.5 Flash-8B (Léger)"
        }
    }
    
    var description: String {
        switch self {
        case .gemini20FlashLiteDot: return "Format exact de votre exemple curl"
        case .gemini20FlashLite: return "Format standard 2.0 Lite"
        case .gemini20Flash: return "Modèle de base Gemini 2.0"
        case .gemini20FlashOfficial: return "Format officiel API 2.0 Lite (v2)"
        case .gemini15Flash: return "Modèle très stable et éprouvé"
        case .gemini15Pro: return "Le plus puissant et stable"
        case .gemini15Flash8B: return "Version économique et rapide"
        }
    }
    
    var isPreferred: Bool {
        switch self {
        case .gemini20FlashLiteDot: return true   // Votre exemple curl
        case .gemini15Flash: return true          // Fallback très fiable
        default: return false
        }
    }
    
    var isStable: Bool {
        switch self {
        case .gemini15Flash, .gemini15Pro, .gemini15Flash8B: return true
        default: return false
        }
    }
}

/// Niveaux d'adaptation de l'IA
enum AdaptationLevel: String, CaseIterable {
    case low = "Faible"
    case medium = "Moyen"
    case high = "Élevé"
    case adaptive = "Adaptatif"
}

/// Longueur de résumé
enum SummaryLength: String, CaseIterable, Identifiable {
    case brief = "Bref"
    case medium = "Moyen"
    case detailed = "Détaillé"
    case comprehensive = "Complet"

    var id: Self { self }
}

/// Message dans une conversation
struct ConversationMessage: Identifiable, Codable {
    var id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    enum MessageRole: String, Codable {
        case user = "user"
        case assistant = "assistant"
        case system = "system"
    }
}

/// Réponse conversationnelle
struct ConversationResponse: Codable {
    let message: String
    let suggestedQuestions: [String]
    let relatedConcepts: [String]
    let confidence: Double
    let reasoning: String?
}

// MARK: - Erreurs IA
enum AIError: LocalizedError {
    case notImplemented(String)
    case connectionFailed
    case invalidConfiguration
    case apiError(String)
    case rateLimitExceeded
    case contentTooLong
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notImplemented(let feature):
            return "Fonctionnalité non implémentée: \(feature)"
        case .connectionFailed:
            return "Connexion à l'IA impossible. Veuillez vérifier votre connexion Internet."
        case .invalidConfiguration:
            return "Clé API invalide ou manquante. Veuillez vérifier votre configuration dans l'assistant IA."
        case .apiError(let message):
            return "Erreur de l'API Gemini : \(message)"
        case .rateLimitExceeded:
            return "Vous avez atteint la limite de requêtes. Veuillez réessayer dans quelques instants."
        case .contentTooLong:
            return "Le texte fourni est trop long pour être traité par l'IA."
        case .invalidResponse:
            return "L'IA a renvoyé une réponse dans un format inattendu."
        }
    }
} 