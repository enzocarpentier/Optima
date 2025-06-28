//
//  GeneralSettingsView.swift
//  Foundation/Settings
//
//  Onglet de préférences générales pour Optima
//  Paramètres globaux et comportements par défaut de l'application
//

import SwiftUI

/// **Onglet Préférences Générales**
/// 
/// Configure les paramètres fondamentaux de l'application :
/// - Comportement au démarrage
/// - Préférences de langue et région
/// - Sauvegarde automatique
/// - Gestion des notifications
struct GeneralSettingsView: View {
    
    // MARK: - Préférences Stockées
    
    @AppStorage("defaultStartupView") private var defaultStartupView: String = MainView.library.rawValue
    @AppStorage("enableAutoSave") private var enableAutoSave: Bool = true
    @AppStorage("autoSaveInterval") private var autoSaveInterval: Double = 300 // 5 minutes
    @AppStorage("showDocumentPreview") private var showDocumentPreview: Bool = true
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("preferredLanguage") private var preferredLanguage: String = "fr"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                // MARK: - Section Démarrage
                settingsSection(
                    title: "Démarrage",
                    icon: "power"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Vue par défaut au lancement :")
                                .frame(width: 180, alignment: .leading)
                            
                            Picker("Vue par défaut", selection: $defaultStartupView) {
                                ForEach(MainView.allCases, id: \.rawValue) { view in
                                    HStack {
                                        Image(systemName: view.systemImage)
                                        Text(view.rawValue)
                                    }
                                    .tag(view.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 180)
                        }
                        
                        Toggle("Ouvrir le dernier document consulté", isOn: .constant(false))
                            .disabled(true) // TODO: Implémenter dans une version future
                    }
                }
                
                // MARK: - Section Sauvegarde
                settingsSection(
                    title: "Sauvegarde",
                    icon: "externaldrive"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Sauvegarde automatique", isOn: $enableAutoSave)
                        
                        if enableAutoSave {
                            HStack {
                                Text("Intervalle de sauvegarde :")
                                    .frame(width: 180, alignment: .leading)
                                
                                Picker("Intervalle", selection: $autoSaveInterval) {
                                    Text("1 minute").tag(60.0)
                                    Text("5 minutes").tag(300.0)
                                    Text("10 minutes").tag(600.0)
                                    Text("30 minutes").tag(1800.0)
                                }
                                .pickerStyle(.menu)
                                .frame(width: 120)
                            }
                            .padding(.leading, 20)
                        }
                        
                        HStack {
                            Button("Sauvegarder maintenant") {
                                Task {
                                    // TODO: Déclencher sauvegarde manuelle
                                    print("🔄 Sauvegarde manuelle déclenchée")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Spacer()
                        }
                    }
                }
                
                // MARK: - Section Interface
                settingsSection(
                    title: "Interface",
                    icon: "macwindow"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Aperçu des documents dans la bibliothèque", isOn: $showDocumentPreview)
                        
                        HStack {
                            Text("Langue de l'interface :")
                                .frame(width: 180, alignment: .leading)
                            
                            Picker("Langue", selection: $preferredLanguage) {
                                HStack {
                                    Text("🇫🇷")
                                    Text("Français")
                                }
                                .tag("fr")
                                
                                HStack {
                                    Text("🇺🇸")
                                    Text("English")
                                }
                                .tag("en")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 150)
                            .disabled(true) // TODO: Localisation complète
                        }
                        
                        Text("⚠️ Le changement de langue nécessite un redémarrage de l'application")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
                
                // MARK: - Section Notifications
                settingsSection(
                    title: "Notifications",
                    icon: "bell"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Activer les notifications", isOn: $enableNotifications)
                        
                        if enableNotifications {
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Fin de session d'étude", isOn: .constant(true))
                                    .padding(.leading, 20)
                                    .disabled(true)
                                
                                Toggle("Rappels de révision", isOn: .constant(false))
                                    .padding(.leading, 20)
                                    .disabled(true)
                                
                                Toggle("Erreurs de synchronisation", isOn: .constant(true))
                                    .padding(.leading, 20)
                                    .disabled(true)
                            }
                        }
                        
                        Text("💡 Les notifications vous aident à suivre vos progrès")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
                
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
    }
    
    // MARK: - Composant de Section
    
    /// Crée une section de paramètres avec titre et icône
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête de section
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
            
            // Contenu de la section avec fond subtil
            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    GeneralSettingsView()
        .frame(width: 580, height: 450)
} 