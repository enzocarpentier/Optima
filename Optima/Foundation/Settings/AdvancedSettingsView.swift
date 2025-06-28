//
//  AdvancedSettingsView.swift
//  Foundation/Settings
//

import SwiftUI

struct AdvancedSettingsView: View {
    @AppStorage("enableDebugMode") private var enableDebugMode: Bool = false
    @AppStorage("maxCacheSize") private var maxCacheSize: Int = 100
    
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                settingsSection(title: "Mises à jour", icon: "arrow.triangle.2.circlepath") {
                    UpdaterSettingsView(updater: coordinator.updater)
                    
                    Divider().padding(.vertical, 4)
                    
                    HStack {
                        Button("Vérifier maintenant") {
                            coordinator.updater.checkForUpdates()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Spacer()
                    }
                }
                
                settingsSection(title: "Débogage", icon: "ladybug") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Mode débogage", isOn: $enableDebugMode)
                        
                        if enableDebugMode {
                            Text("⚠️ Le mode débogage affiche des informations techniques supplémentaires")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(.leading, 20)
                        }
                    }
                }
                
                settingsSection(title: "Performance", icon: "speedometer") {
                    VStack(alignment: .leading, spacing: 12) {
                        
                        HStack {
                            Text("Taille max du cache (MB) :")
                                .frame(width: 180, alignment: .leading)
                            
                            Picker("Cache", selection: $maxCacheSize) {
                                Text("50 MB").tag(50)
                                Text("100 MB").tag(100)
                                Text("200 MB").tag(200)
                                Text("500 MB").tag(500)
                            }
                            .pickerStyle(.menu)
                            .frame(width: 100)
                        }
                        
                        HStack {
                            Button("Vider le cache") {
                                // TODO: Vider le cache
                                print("🗑️ Cache vidé")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Spacer()
                        }
                    }
                }
                
                settingsSection(title: "Données", icon: "externaldrive") {
                    VStack(alignment: .leading, spacing: 12) {
                        
                        HStack {
                            Button("Exporter les données") {
                                // TODO: Export des données
                                print("📤 Export des données")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("Réinitialiser l'application") {
                                // TODO: Reset complet
                                print("🔄 Réinitialisation")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Spacer()
                        }
                        
                        Text("⚠️ La réinitialisation supprime toutes vos données locales")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .italic()
                    }
                }
                
            }
            .padding(24)
        }
    }
    
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            content()
                .padding(.leading, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AdvancedSettingsView()
        .frame(width: 580, height: 450)
}
