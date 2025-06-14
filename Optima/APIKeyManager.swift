import Foundation
import Security
import SwiftUI

class APIKeyManager: ObservableObject {
    static let shared = APIKeyManager()
    @Published var apiKey: String = ""
    @Published var feedbackMessage: String = "" // Added for UI feedback

    private let geminiService = "com.optima.geminiApiService"
    private let geminiAccount = "geminiApiKey"

    private init() { // Made init private for singleton and to load key
        self.apiKey = loadGeminiApiKey() ?? ""
    }

    // Function to save Gemini API key
    func saveGeminiApiKey(apiKey: String) {
        guard !apiKey.isEmpty else {
            self.feedbackMessage = "La clé API ne peut pas être vide."
            return
        }
        guard let data = apiKey.data(using: .utf8) else {
            self.feedbackMessage = "Erreur: La clé API ne peut pas être encodée."
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: geminiService,
            kSecAttrAccount as String: geminiAccount,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary) // Delete any existing key first
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            self.apiKey = apiKey // Update published property
            self.feedbackMessage = "Clé API Gemini sauvegardée avec succès."
            print("Gemini API key saved successfully.")
        } else {
            self.feedbackMessage = "Erreur lors de la sauvegarde de la clé API Gemini (code: \(status))."
            print("Error saving Gemini API key: \(status)")
        }
    }

    // Renamed original loadGroqApiKey to loadGeminiApiKey
    private func loadGeminiApiKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: geminiService,
            kSecAttrAccount as String: geminiAccount,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data,
               let key = String(data: retrievedData, encoding: .utf8) {
                return key
            }
        } else if status == errSecItemNotFound {
            print("Gemini API key not found in Keychain.")
        } else {
            print("Error retrieving Gemini API key: \(status)")
        }
        return nil
    }
    
    // Public getter if needed, though direct access to @Published apiKey is common
    func getGeminiApiKey() -> String? {
        return loadGeminiApiKey()
    }


    // Function to delete Gemini API key
    func deleteGeminiApiKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: geminiService,
            kSecAttrAccount as String: geminiAccount
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            self.apiKey = "" // Clear published property
            if status == errSecItemNotFound {
                self.feedbackMessage = "Aucune clé API Gemini à supprimer."
                print("No Gemini API key found to delete.")
            } else {
                self.feedbackMessage = "Clé API Gemini supprimée avec succès."
                print("Gemini API key deleted successfully.")
            }
        } else {
            self.feedbackMessage = "Erreur lors de la suppression de la clé API Gemini (code: \(status))."
            print("Error deleting Gemini API key: \(status)")
        }
    }
}
