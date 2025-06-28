//
//  AIConfigurationView.swift
//  AdaptiveUI/Views
//
//  Interface de configuration de la clé API Gemini
//  Permet à l'utilisateur de saisir et tester sa clé API
//

import SwiftUI

struct AIConfigurationView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiKey = ""
    @State private var selectedModel: AIModel = .gemini20FlashLite
    @State private var isTestingConnection = false
    @State private var connectionResult: ConnectionResult?
    @State private var showingAPIKeyHelp = false
    
    enum ConnectionResult {
        case success
        case failure(String)
        
        var errorDetails: String {
            switch self {
            case .success:
                return ""
            case .failure(let error):
                return error
            }
        }
    }
    
    var body: some View {
        // 🔑 CORRECTION : Structure simplifiée sans NavigationView imbriquée
        VStack(spacing: 0) {
            // En-tête avec titre
            configurationHeader
            
            // Contenu principal
            ScrollView {
                VStack(spacing: 24) {
                    // En-tête visuel
                    headerSection
                    
                    // Configuration API
                    configurationSection
                    
                    // Test de connexion
                    testSection
                }
                .padding(24)
            }
            
            // Actions en bas (toujours visibles)
            VStack(spacing: 0) {
                Divider()
                actionButtons
                    .padding(24)
                    .background(.regularMaterial)
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .sheet(isPresented: $showingAPIKeyHelp) {
            apiKeyHelpSheet
        }
        .onAppear {
            loadCurrentConfiguration()
        }
    }
    
    // 🔑 NOUVEAU : En-tête de configuration avec bouton fermer
    private var configurationHeader: some View {
        HStack {
            Text("Configuration IA")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Fermer")
        }
        .padding()
        .background(.regularMaterial)
    }
    
    // MARK: - Sections de l'interface
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundStyle(.blue.gradient)
            
            Text("Configuration Gemini API")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Configurez votre clé API Gemini pour activer l'intelligence artificielle d'Optima")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Clé API Gemini")
                        .font(.headline)
                    
                    Button {
                        showingAPIKeyHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Comment obtenir une clé API Gemini")
                }
                
                SecureField("Saisissez votre clé API...", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.monospaced(.body)())
                
                if !apiKey.isEmpty {
                    Text("Clé: \(apiKey.prefix(8))***\(apiKey.suffix(4))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Modèle IA")
                    .font(.headline)
                
                Picker("Modèle IA", selection: $selectedModel) {
                    ForEach(AIModel.allCases, id: \.self) { model in
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(model.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if model.isPreferred {
                                        Text("RECOMMANDÉ")
                                            .font(.caption2)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.green, in: RoundedRectangle(cornerRadius: 4))
                                    }
                                }
                                Text(model.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tag(model)
                    }
                }
                .pickerStyle(.menu)
                
                Text("💡 Le test automatique trouvera le modèle optimal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var testSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await testConnection()
                }
            } label: {
                HStack {
                    if isTestingConnection {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "network")
                    }
                    
                    Text(isTestingConnection ? "Test en cours..." : "Tester la connexion")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(apiKey.isEmpty || isTestingConnection)
            
            // Résultat du test
            if let result = connectionResult {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result.isSuccess ? .green : .red)
                        
                        Text(result.isSuccess ? "Connexion réussie ✓" : "Erreur de connexion")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    
                    if !result.isSuccess {
                        Text(result.errorDetails)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    (result.isSuccess ? Color.green : Color.red).opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 8)
                )
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button("Annuler") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(minWidth: 120)
            
            Button("Sauvegarder") {
                Task {
                    await saveConfiguration()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(minWidth: 120)
            .disabled(apiKey.isEmpty)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Actions
    
    private func loadCurrentConfiguration() {
        // Charger la configuration actuelle depuis le service IA
        Task {
            await MainActor.run {
                // Note : On ne charge pas la clé par sécurité, l'utilisateur doit la saisir
                // Charger le modèle sélectionné depuis UserDefaults
                if let savedModelString = UserDefaults.standard.string(forKey: "selected_ai_model"),
                   let savedModel = AIModel(rawValue: savedModelString) {
                    selectedModel = savedModel
                }
            }
        }
    }
    
    private func testConnection() async {
        guard !apiKey.isEmpty else { return }
        
        await MainActor.run {
            isTestingConnection = true
            connectionResult = nil
        }
        
        // Tester avec le service IA avancé
        await coordinator.aiService.setAPIKey(apiKey)
        await coordinator.aiService.setModel(selectedModel)
        
        print("🔍 Début du test de connexion avancé...")
        let result = await coordinator.aiService.testConnectionWithFallback()
        
        await MainActor.run {
            isTestingConnection = false
            
            if result.success {
                if let workingModel = result.workingModel {
                    // Mettre à jour le modèle sélectionné vers celui qui fonctionne
                    selectedModel = workingModel
                    connectionResult = .success
                    print("🔍 ✅ Test réussi avec le modèle: \(workingModel.rawValue)")
                } else {
                    connectionResult = .success
                }
            } else {
                let errorMessage = result.error ?? coordinator.aiService.lastError?.localizedDescription ?? "Échec du test"
                connectionResult = .failure(errorMessage)
                print("🔍 ❌ Test échoué: \(errorMessage)")
            }
        }
    }
    
    private func saveConfiguration() async {
        // Sauvegarder la configuration dans le service IA
        await coordinator.aiService.setAPIKey(apiKey)
        await coordinator.aiService.setModel(selectedModel)
        
        // Sauvegarder le modèle sélectionné dans UserDefaults
        UserDefaults.standard.set(selectedModel.rawValue, forKey: "selected_ai_model")
        
        await MainActor.run {
            // 🔑 CORRECTION : Fermer la configuration et ouvrir l'assistant si la clé est valide
            dismiss()
            
            // Si la clé API est maintenant configurée, ouvrir l'assistant
            if !coordinator.aiService.needsAPIKey {
                coordinator.showingAIAssistant = true
            }
        }
    }
    
    // MARK: - Sheet d'aide
    
    @ViewBuilder
    private var apiKeyHelpSheet: some View {
        // 🔑 CORRECTION : Sheet d'aide simplifiée sans NavigationView
        VStack(spacing: 0) {
            // En-tête de l'aide
            HStack {
                Text("Aide API Gemini")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showingAPIKeyHelp = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Fermer l'aide")
            }
            .padding()
            .background(.regularMaterial)
            
            // Contenu de l'aide
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Comment obtenir une clé API Gemini")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        instructionStep(
                            number: 1,
                            title: "Aller sur Google AI Studio",
                            description: "Visitez https://aistudio.google.com"
                        )
                        
                        instructionStep(
                            number: 2,
                            title: "Connectez-vous",
                            description: "Utilisez votre compte Google"
                        )
                        
                        instructionStep(
                            number: 3,
                            title: "Générer une clé API",
                            description: "Cliquez sur 'Get API Key' puis 'Create API Key'"
                        )
                        
                        instructionStep(
                            number: 4,
                            title: "Copier la clé",
                            description: "Copiez la clé générée et collez-la dans Optima"
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⚠️ Important")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        
                        Text("• Gardez votre clé API secrète\n• Ne la partagez jamais\n• Elle sera sauvegardée localement sur votre Mac")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .padding()
            }
        }
        .frame(minWidth: 480, minHeight: 500)
    }
    
    private func instructionStep(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue, in: Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Extension pour ConnectionResult

extension AIConfigurationView.ConnectionResult {
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    var message: String {
        switch self {
        case .success:
            return "Connexion réussie ✓"
        case .failure(let error):
            return "Erreur : \(error)"
        }
    }
}

// MARK: - Preview

#Preview {
    AIConfigurationView()
        .environmentObject(AppCoordinator())
} 