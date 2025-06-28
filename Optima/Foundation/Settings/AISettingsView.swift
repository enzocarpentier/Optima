//
//  AISettingsView.swift
//  Foundation/Settings
//

import SwiftUI

struct AISettingsView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var apiKey = ""
    @State private var selectedModel: AIModel = .gemini20FlashLite
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                settingsSection(title: "Configuration API", icon: "key") {
                    VStack(alignment: .leading, spacing: 12) {
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Clé API Gemini :")
                            
                            SecureField("Saisissez votre clé API...", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.monospaced(.body)())
                        }
                        
                        HStack {
                            Text("Modèle IA :")
                                .frame(width: 130, alignment: .leading)
                            
                            Picker("Modèle", selection: $selectedModel) {
                                ForEach(AIModel.allCases, id: \.self) { model in
                                    Text(model.displayName).tag(model)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 200)
                        }
                        
                        Button("Tester la connexion") {
                            // TODO: Test de connexion
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(apiKey.isEmpty)
                    }
                }
                
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
    }
    
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .font(.title2)
                    .frame(width: 24)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding(.bottom, 4)
            
            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AISettingsView()
        .environmentObject(AppCoordinator())
        .frame(width: 580, height: 450)
}
