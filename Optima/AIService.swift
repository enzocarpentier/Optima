import Foundation
import PDFKit
import Combine

class AIService: ObservableObject {
    static let shared = AIService()
    private var apiKeyManager = APIKeyManager.shared
    private let logger = AppLogger.shared

    @Published var isProcessing: Bool = false
    @Published var progress: Double = 0.0
    @Published var currentTask: String = ""

    private let geminiAPIURLString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key="
    private let geminiModelName = "gemini-1.5-flash-latest"

    private init() {}

    // MARK: - Public Generation Methods
    func generateQCM(text: String, numQuestions: Int, language: String) async throws -> [QuizQuestion] {
        await MainActor.run {
            self.isProcessing = true
            self.progress = 0.0
            self.currentTask = "Generating QCM..."
        }
        let prompt = "From the text below, generate a Multiple Choice Quiz with exactly \(numQuestions) questions in \(language). The entire output must be a single JSON object. The JSON object must have a key 'questions' which is an array of objects. Each object must contain these keys: 'id' (a new UUID string), 'question' (string), 'options' (an array of 4 strings), 'correctAnswer' (a string matching one of the options), and 'explanation' (a brief string explaining the correct answer). Do not include any text or formatting outside of this single JSON object. \n\nText: \n\n\(text)"
        logger.log("Generating QCM with Gemini. Number of questions: \(numQuestions), Language: \(language). Prompt length: \(prompt.count)", level: .info)

        var responseText: String?
        do {
            responseText = try await sendGeminiRequest(prompt: prompt)
            guard let responseText = responseText else {
                throw AIError.parsingError("Received nil response from Gemini request.")
            }
            
            let cleanedJsonText = cleanJsonString(responseText)
            guard let jsonData = cleanedJsonText.data(using: .utf8) else {
                throw AIError.parsingError("Failed to convert Gemini QCM response to Data. Raw response: \(responseText)")
            }
            
            let decoder = JSONDecoder()
            let qcmResponse = try decoder.decode(QuizResponse.self, from: jsonData)
            logger.log("Successfully decoded QCM data from Gemini. Count: \(qcmResponse.questions.count)", level: .info)
            
            await MainActor.run {
                self.isProcessing = false
                self.currentTask = "QCM generated."
            }
            return qcmResponse.questions
        } catch {
            logger.log("Failed to generate or decode QCM JSON from Gemini: \(error.localizedDescription). Raw response: <\(responseText ?? "nil")>", level: .error)
            await MainActor.run {
                self.isProcessing = false
                self.currentTask = "QCM generation failed."
            }
            if let aiError = error as? AIError {
                throw aiError
            } else {
                throw AIError.parsingError("Failed to decode QCM JSON from Gemini: \(error.localizedDescription)")
            }
        }
    }

    func generateFlashcards(text: String, numFlashcards: Int, language: String) async throws -> [FlashCard] {
        await MainActor.run {
            self.isProcessing = true
            self.progress = 0.0
            self.currentTask = "Generating flashcards..."
        }
        let prompt = "From the text below, generate exactly \(numFlashcards) flashcards in \(language). The entire output must be a single JSON object. The JSON object must have a key 'flashcards' which is an array of objects. Each object must contain these keys: 'id' (a new UUID string), 'term' (string), and 'definition' (string). Do not include any text or formatting outside of this single JSON object. \n\nText: \n\n\(text)"
        logger.log("Generating Flashcards with Gemini. Number: \(numFlashcards), Language: \(language). Prompt length: \(prompt.count)", level: .info)

        var responseText: String?
        do {
            responseText = try await sendGeminiRequest(prompt: prompt)
            guard let responseText = responseText else {
                throw AIError.parsingError("Received nil response from Gemini request.")
            }

            let cleanedJsonText = cleanJsonString(responseText)
            guard let jsonData = cleanedJsonText.data(using: .utf8) else {
                throw AIError.parsingError("Failed to convert Gemini Flashcards response to Data. Raw response: \(responseText)")
            }
            let decoder = JSONDecoder()
            let flashcardResponse = try decoder.decode(FlashCardResponse.self, from: jsonData)
            logger.log("Successfully decoded Flashcards data from Gemini. Count: \(flashcardResponse.flashcards.count)", level: .info)
            await MainActor.run {
                self.isProcessing = false
                self.currentTask = "Flashcards generated."
            }
            return flashcardResponse.flashcards
        } catch {
            logger.log("Failed to generate or decode Flashcards JSON from Gemini: \(error.localizedDescription). Raw response: <\(responseText ?? "nil")>", level: .error)
            await MainActor.run {
                self.isProcessing = false
                self.currentTask = "Flashcard generation failed."
            }
            if let aiError = error as? AIError {
                throw aiError
            } else {
                throw AIError.parsingError("Failed to decode Flashcards JSON from Gemini: \(error.localizedDescription)")
            }
        }
    }

    func generateSummary(text: String, language: String, length: SummaryLength = .medium) async throws -> TextSummary {
        await MainActor.run {
            self.isProcessing = true
            self.progress = 0.0
            self.currentTask = "Generating summary..."
        }
        let lengthDescriptionString: String
        switch length {
        case .short: lengthDescriptionString = "a short (1-2 paragraphs)"
        case .medium: lengthDescriptionString = "a medium-length (3-5 paragraphs)"
        case .long: lengthDescriptionString = "a detailed (more than 5 paragraphs)"
        }
        let originalWordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let prompt = """
        From the text below, generate \(lengthDescriptionString) summary in \(language).
        The entire output must be a single JSON object. The JSON object must have a key 'summary_data' which is an object containing these keys:
        - 'id': A new UUID string.
        - 'summaryText': The generated summary text.
        - 'keyPoints': An array of 3-5 key point strings from the text.
        - 'mainTopics': An array of 3-5 main topic strings.
        - 'wordCount': The integer word count of the generated summary.
        - 'originalWordCount': The integer word count of the original text, which is \(originalWordCount).
        Do not include any text or formatting outside of this single JSON object.

        Text:
        \(text)
        """
        logger.log("Generating Summary with Gemini. Language: \(language), Length: \(length). Prompt length: \(prompt.count)", level: .info)

        var responseText: String?
        do {
            responseText = try await sendGeminiRequest(prompt: prompt)
            guard let responseText = responseText else {
                throw AIError.parsingError("Received nil response from Gemini request.")
            }

            let cleanedJsonText = cleanJsonString(responseText)
            guard let jsonData = cleanedJsonText.data(using: .utf8) else {
                throw AIError.parsingError("Failed to convert Gemini Summary response to Data. Raw response: \(responseText)")
            }

            let decoder = JSONDecoder()
            let summaryResponse = try decoder.decode(SummaryResponse.self, from: jsonData)
            
            logger.log("Successfully decoded Summary data from Gemini.", level: .info)

            await MainActor.run {
                self.isProcessing = false
                self.currentTask = "Summary generated."
            }
            return summaryResponse.summary_data
        } catch {
            logger.log("Failed to generate or decode Summary JSON from Gemini: \(error.localizedDescription). Raw response: <\(responseText ?? "nil")>", level: .error)
            await MainActor.run {
                self.isProcessing = false
                self.currentTask = "Summary generation failed."
            }
            if let aiError = error as? AIError {
                throw aiError
            } else {
                throw AIError.parsingError("Failed to decode Summary JSON from Gemini: \(error.localizedDescription)")
            }
        }
    }

    func generateDefinitions(text: String, terms: [String], language: String) async throws -> [TermDefinition] {
        await MainActor.run {
            self.isProcessing = true
            self.progress = 0.0
            self.currentTask = "Generating definitions..."
        }

        let termsString = terms.joined(separator: ", ")
        let prompt = """
        From the text below, provide definitions in \(language) for these specific terms: [\(termsString)].
        The entire output must be a single JSON object. The JSON object must have a key 'definitions' which is an array of objects.
        Each object must have these keys:
        - 'id': A new UUID string.
        - 'term': The term being defined.
        - 'definition': A clear and concise definition based on the text.
        - 'context': A sentence showing how the term is used in the original text.
        - 'relatedTerms': An array of 1-3 related terms found in the text.
        - 'importance': The importance of the term, rated as 'Essentiel', 'Moyen', or 'Secondaire'.

        If a term cannot be defined from the text, omit it from the array. Do not include any text or formatting outside of this single JSON object.

        Text:
        \(text)
        """

        logger.log("Generating Definitions with Gemini. Language: \(language), Terms: \(termsString). Prompt length: \(prompt.count)", level: .info)

        var responseText: String?
        do {
            responseText = try await sendGeminiRequest(prompt: prompt)
            guard let responseText = responseText else {
                throw AIError.parsingError("Received nil response from Gemini request.")
            }

            let cleanedJsonText = cleanJsonString(responseText)
            guard let jsonData = cleanedJsonText.data(using: .utf8) else {
                throw AIError.parsingError("Failed to convert Gemini Definitions response to Data. Raw response: \(responseText)")
            }
            
            let decoder = JSONDecoder()
            let definitionResponse = try decoder.decode(TermDefinitionResponse.self, from: jsonData)
            
            logger.log("Successfully decoded Definitions data from Gemini. Count: \(definitionResponse.definitions.count)", level: .info)
            
            await MainActor.run {
                self.isProcessing = false
                self.currentTask = "Definitions generated."
            }
            
            guard !definitionResponse.definitions.isEmpty else {
                throw AIError.parsingError("No definitions were generated from the text")
            }
            
            return definitionResponse.definitions
            
        } catch {
            logger.log("Failed to generate or decode Definitions JSON from Gemini: \(error.localizedDescription). Raw response: <\(responseText ?? "nil")>", level: .error)
            await MainActor.run {
                self.isProcessing = false
                self.currentTask = "Definitions generation failed."
            }
            if let aiError = error as? AIError {
                throw aiError
            } else {
                throw AIError.parsingError("Failed to decode Definitions JSON from Gemini: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Gemini API Request Logic
    private func sendGeminiRequest(prompt: String, retryCount: Int = 3) async throws -> String {
        guard let apiKey = apiKeyManager.getGeminiApiKey(), !apiKey.isEmpty else {
            logger.log("Gemini API Key is missing.", level: .error)
            await MainActor.run {
                self.isProcessing = false
                self.currentTask = "Gemini API Key is missing."
            }
            throw AIError.apiKeyMissing
        }
        
        guard let url = URL(string: "\(geminiAPIURLString)\(apiKey)") else {
            throw AIError.apiError("Invalid Gemini API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
             "generationConfig": [
               "response_mime_type": "application/json",
             ]
        ]
        
        await MainActor.run {
            self.progress = 0.1
            self.currentTask = "Sending request to Gemini..."
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            throw AIError.apiError("Failed to create Gemini request body: \(error.localizedDescription)")
        }

        logger.log("Sending request to Gemini API.", level: .info)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                self.progress = 0.5
                self.currentTask = "Processing Gemini response..."
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }

            let responseBodyString = String(data: data, encoding: .utf8) ?? "Could not decode response body"
            logger.log("Gemini API Response Status Code: \(httpResponse.statusCode)", level: .info)

            // Handle rate limiting specifically
            if httpResponse.statusCode == 429 {
                let rateLimitInfo = parseRateLimitError(from: data)
                
                if rateLimitInfo.isDailyQuota {
                    logger.log("Gemini API daily quota exceeded.", level: .error)
                    throw AIError.dailyQuotaExceeded
                }

                if retryCount > 0 {
                    let retryAfter = rateLimitInfo.retryDelay
                    logger.log("Gemini API rate limit exceeded. Retrying after \(retryAfter) seconds... (attempts left: \(retryCount - 1))", level: .warning)
                    await MainActor.run {
                        self.currentTask = "Rate limit hit. Retrying in \(retryAfter)s..."
                    }
                    try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
                    return try await sendGeminiRequest(prompt: prompt, retryCount: retryCount - 1)
                } else {
                    logger.log("Gemini API rate limit exceeded. No retries left.", level: .error)
                    throw AIError.rateLimitExceeded
                }
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = "Gemini API request failed. Status: \(httpResponse.statusCode). Body: \(responseBodyString)"
                logger.log(errorMessage, level: .error)
                throw AIError.apiError(errorMessage)
            }
            
            return try await parseGeminiResponse(data: data)

        } catch let error as AIError {
            throw error
        } catch {
            logger.log("Error during Gemini API request: \(error.localizedDescription)", level: .error)
            // Simple retry logic
            if retryCount > 0 {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                return try await sendGeminiRequest(prompt: prompt, retryCount: retryCount - 1)
            } else {
                throw AIError.networkError("Failed after multiple retries: \(error.localizedDescription)")
            }
        }
    }

    private func parseRateLimitError(from errorData: Data) -> (retryDelay: Int, isDailyQuota: Bool) {
        // Default delay is 60 seconds if parsing fails
        let defaultDelay = 60
        var isDaily = false
        var retryDelay = defaultDelay
        
        do {
            if let json = try JSONSerialization.jsonObject(with: errorData, options: []) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let details = error["details"] as? [[String: Any]] {
                
                detailsLoop: for detail in details {
                    if detail["@type"] as? String == "type.googleapis.com/google.rpc.QuotaFailure",
                       let violations = detail["violations"] as? [[String: Any]] {
                        for violation in violations {
                            if let quotaId = violation["quotaId"] as? String, quotaId.contains("PerDay") {
                                isDaily = true
                                break detailsLoop // Daily limit found, exit the main loop
                            }
                        }
                    }

                    if detail["@type"] as? String == "type.googleapis.com/google.rpc.RetryInfo",
                       let retryDelayString = detail["retryDelay"] as? String {
                        let numericString = retryDelayString.replacingOccurrences(of: "s", with: "")
                        if let delaySeconds = Int(numericString) {
                            retryDelay = delaySeconds
                        }
                    }
                }
            }
        } catch {
            logger.log("Could not parse rate limit info from Gemini error response: \(error.localizedDescription)", level: .error)
        }
        
        return (retryDelay, isDaily)
    }

    private func parseGeminiResponse(data: Data) async throws -> String {
        do {
            guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw AIError.parsingError("Could not serialize response into JSON.")
            }
            
            // Check for safety blocks first
            if let promptFeedback = jsonResponse["promptFeedback"] as? [String: Any],
               let safetyRatings = promptFeedback["safetyRatings"] as? [[String: Any]],
               safetyRatings.contains(where: { ($0["probability"] as? String) != "NEGLIGIBLE" }) {
                logger.log("Content blocked due to safety settings. Feedback: \(promptFeedback)", level: .error)
                throw AIError.contentBlockedBySafetySettings
            }

            guard let candidates = jsonResponse["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                
                // If candidates array is empty and there's no safety block, it's a different issue.
                if (jsonResponse["candidates"] as? [[String: Any]])?.isEmpty ?? false {
                     throw AIError.parsingError("The API returned an empty 'candidates' array without a safety warning. The model may have refused to answer.")
                }
                
                // Log detailed error if parsing fails for other reasons
                let responseBodyString = String(data: data, encoding: .utf8) ?? "Invalid response body"
                logger.log("Failed to parse Gemini JSON response. Body: \(responseBodyString)", level: .error)
                throw AIError.parsingError("Failed to parse Gemini JSON response or extract text.")
            }
            
            logger.log("Successfully parsed Gemini response.", level: .info)
            await MainActor.run {
                self.progress = 1.0
                self.currentTask = "Content generated successfully."
                self.isProcessing = false
            }
            return text
        } catch {
            logger.log("Error decoding Gemini JSON: \(error.localizedDescription)", level: .error)
            throw AIError.parsingError("Error decoding Gemini JSON: \(error.localizedDescription)")
        }
    }
    
    /// Cleans the JSON string received from the AI.
    private func cleanJsonString(_ rawString: String) -> String {
        // Find the first and last braces to extract the JSON object, ignoring any extra text.
        if let firstBrace = rawString.firstIndex(of: "{"),
           let lastBrace = rawString.lastIndex(of: "}") {
            let jsonSubstring = rawString[firstBrace...lastBrace]
            return String(jsonSubstring)
        }
        
        // If no JSON object is found, return the original string for error logging.
        return rawString
    }

    // MARK: - Helper to handle errors for UI
    func handleError(_ error: Error) -> String {
        Task {
            await MainActor.run {
                self.isProcessing = false
                if let aiError = error as? AIError {
                    self.currentTask = aiError.errorDescription ?? "An AI error occurred."
                } else {
                    self.currentTask = "An error occurred: \(error.localizedDescription)"
                }
            }
        }

        if let aiError = error as? AIError {
            return aiError.localizedDescription
        } else {
            return error.localizedDescription
        }
    }
}

// Dummy AppLogger for AIService to compile. Replace with your actual logger.
class AppLogger {
    static let shared = AppLogger()
    enum LogLevel { case info, debug, error, warning }
    func log(_ message: String, level: LogLevel) {
        print("[\(level)] \(message)")
    }
}


