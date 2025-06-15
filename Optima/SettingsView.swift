import SwiftUI
import Security
import Sparkle

struct SettingsView: View {
    @StateObject private var apiKeyManager = APIKeyManager.shared
    @State private var apiKeyInput: String = ""
    @State private var showContent = false

    // Le contrôleur pour l'updater Sparkle
    private let updaterController = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // En-tête
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paramètres")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Gérez les paramètres de l'application.")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // Section Clé API Gemini
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.title2)
                            .foregroundColor(.blue) // Changed color for consistency
                            .symbolRenderingMode(.hierarchical)
                        Text("Clé API Gemini")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }

                    Text("Votre clé API Gemini est nécessaire pour toutes les fonctionnalités d'IA. Elle est stockée de manière sécurisée dans le trousseau de votre Mac.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(nil)
                    
                    TextField("Entrez votre clé API Gemini", text: $apiKeyInput)
                        .textFieldStyle(GlassTextFieldStyle())
                    
                    HStack {
                        Button(action: {
                            apiKeyManager.saveGeminiApiKey(apiKey: apiKeyInput)
                            apiKeyInput = "" // Clear input on save
                        }) {
                            Label("Sauvegarder la Clé", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(GlassButtonStyle(color: .blue))
                        
                        // Add a delete button only if a key is present
                        if !apiKeyManager.apiKey.isEmpty {
                            Button(action: {
                                apiKeyManager.deleteGeminiApiKey()
                            }) {
                                Label("Supprimer la Clé", systemImage: "trash.fill")
                                    .font(.headline)
                            }
                            .buttonStyle(GlassButtonStyle(color: .red))
                        }
                    }
                    
                    if !apiKeyManager.feedbackMessage.isEmpty {
                        Text(apiKeyManager.feedbackMessage)
                            .font(.caption)
                            .foregroundColor(apiKeyManager.feedbackMessage.contains("Erreur") ? .red : .green)
                            .padding(.top, 8)
                            .transition(.opacity)
                    }
                    
                    // Display current API Key status
                    if !apiKeyManager.apiKey.isEmpty {
                        Text("Clé API actuelle : ...\(apiKeyManager.apiKey.suffix(4))")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.top, 4)
                    } else {
                        Text("Aucune clé API Gemini enregistrée.")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                
                // Section Mise à jour
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                            .symbolRenderingMode(.hierarchical)
                        Text("Mises à jour")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Version actuelle")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                        Button(action: {
                            updaterController.checkForUpdates(nil)
                        }) {
                            Label("Vérifier", systemImage: "arrow.down.circle")
                                .font(.headline)
                        }
                        .buttonStyle(GlassButtonStyle(color: .green))
                    }
                }
                .padding()
                .background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding()
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .onAppear {
            apiKeyInput = apiKeyManager.apiKey // Load current key into input for editing
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
        .navigationTitle("Clés API")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .background(UnifiedBackground())
    }
}