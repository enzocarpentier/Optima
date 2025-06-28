//
//  SettingsView.swift
//  Foundation/Settings
//
//  Fenêtre de préférences native macOS pour Optima
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    
    @State private var selectedTab: SettingsTab = .general
    
    var body: some View {
        VStack(spacing: 0) {
            // En-tête avec bouton de fermeture
            settingsHeader
            
            Divider()
            
            // Barre d'onglets personnalisée style macOS
            settingsTabBar
            
            Divider()
            
            // Contenu de l'onglet sélectionné
            settingsContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 650, height: 580)
        .background(.regularMaterial)
    }
    
    // MARK: - Composants Personnalisés
    
    /// En-tête avec titre et bouton de fermeture
    private var settingsHeader: some View {
        HStack {
            Text("Préférences")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button {
                coordinator.showingSettings = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Fermer les préférences")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial)
    }
    
    /// Barre d'onglets personnalisée style macOS Preferences
    private var settingsTabBar: some View {
        HStack(spacing: 0) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                SettingsTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
    
    /// Contenu de l'onglet sélectionné
    @ViewBuilder
    private var settingsContent: some View {
        switch selectedTab {
        case .general:
            GeneralSettingsView()
        case .ai:
            AISettingsView()
        case .study:
            StudySettingsView()
        case .advanced:
            AdvancedSettingsView()
        }
    }
}

enum SettingsTab: String, CaseIterable {
    case general = "general"
    case ai = "ai"
    case study = "study"
    case advanced = "advanced"
    
    var title: String {
        switch self {
        case .general: return "Général"
        case .ai: return "IA"
        case .study: return "Étude"
        case .advanced: return "Avancé"
        }
    }
    
    var iconName: String {
        switch self {
        case .general: return "gear"
        case .ai: return "brain.head.profile"
        case .study: return "book.closed"
        case .advanced: return "slider.horizontal.3"
        }
    }
}

// MARK: - Composant Onglet Personnalisé

/// Bouton d'onglet personnalisé avec zone cliquable complète et effet de survol
struct SettingsTabButton: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: tab.iconName)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                
                Text(tab.title)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .help(tab.title)
        .frame(width: 80, height: 60)
        .background(
            backgroundForState,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .contentShape(Rectangle()) // Assure que toute la zone est cliquable
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
    
    private var backgroundForState: Color {
        if isSelected {
            return .blue.opacity(0.15)
        } else if isHovered {
            return .primary.opacity(0.05)
        } else {
            return .clear
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppCoordinator())
}
