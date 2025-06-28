//
//  MainNavigationView.swift
//  AdaptiveUI
//
//  Interface de navigation principale d'Optima
//  Architecture adaptative avec barre latérale et zone de contenu contextuelle
//

import SwiftUI

/// Vue de navigation principale utilisant NavigationSplitView
/// Responsabilité : Structure de navigation, routing, interface adaptative
struct MainNavigationView: View {
    
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var selectedViewID: MainView.ID?
    
    var body: some View {
        NavigationSplitView {
            // MARK: - Barre Latérale
            SidebarView(selectedViewID: $selectedViewID)
                .navigationSplitViewColumnWidth(
                    min: 250,
                    ideal: 300,
                    max: 400
                )
        } detail: {
            // MARK: - Zone de Contenu Principal
            DetailContentView()
        }
        .navigationSplitViewStyle(.prominentDetail)
        .overlay(alignment: .trailing) {
            if coordinator.showingAIAssistant {
                AIAssistantPanel()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.showingAIAssistant)
        .sheet(isPresented: $coordinator.showingAIConfiguration) {
            AIConfigurationView()
        }
        .sheet(isPresented: $coordinator.showingSettings) {
            SettingsView()
                .environmentObject(coordinator)
        }
        .onAppear {
            // Sélection initiale
            selectedViewID = coordinator.selectedView.id
        }
        .onChange(of: selectedViewID) { _, newValue in
            if let newValue,
               let mainView = MainView.allCases.first(where: { $0.id == newValue }) {
                coordinator.navigateTo(mainView)
            }
        }
        .onChange(of: coordinator.selectedView) { _, newView in
            selectedViewID = newView.id
        }
    }
}

// MARK: - Barre Latérale
struct SidebarView: View {
    
    @Binding var selectedViewID: MainView.ID?
    @EnvironmentObject private var coordinator: AppCoordinator
    
    var body: some View {
        List(MainView.allCases, selection: $selectedViewID) { view in
            NavigationItemView(
                view: view,
                isSelected: selectedViewID == view.id
            )
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
        }
        .listStyle(.sidebar)
        .navigationTitle("Optima")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ImportButton()
            }
        }
    }
}

// MARK: - Élément de Navigation avec Animations
struct NavigationItemView: View {
    let view: MainView
    let isSelected: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        NavigationLink(value: view.id) {
            HStack {
                // Icône avec animation
                Image(systemName: view.systemImage)
                    .foregroundStyle(isSelected ? .blue : .primary)
                    .frame(width: 20)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
                
                // Texte avec effet
                Text(view.rawValue)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundStyle(isSelected ? .blue : .primary)
                
                Spacer()
                
                // Indicateur de sélection animé
                if isSelected {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                        .scaleEffect(isSelected ? 1.0 : 0.1)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected ? 
                        Color.blue.opacity(0.1) : 
                        (isHovered ? Color.primary.opacity(0.05) : Color.clear)
                    )
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
            )
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bouton d'Import avec Animation
struct ImportButton: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            
            // Feedback sonore
            NSSound(named: "Pop")?.play()
            
            coordinator.showImportSheet()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: .blue.opacity(isHovered ? 0.4 : 0.2),
                            radius: isHovered ? 4 : 2,
                            x: 0,
                            y: isHovered ? 2 : 1
                        )
                )
                .scaleEffect(isPressed ? 0.9 : (isHovered ? 1.05 : 1.0))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(.plain)
        .help("Importer des cours")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Zone de Contenu Détail
struct DetailContentView: View {
    
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var currentView: MainView = .library
    
    var body: some View {
        ZStack {
            // Affichage de la vue avec transition
            Group {
                switch coordinator.selectedView {
                case .library:
                    LibraryView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                case .reader:
                    ReaderView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .generation:
                    GenerationView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                case .study:
                    StudyView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                case .analytics:
                    AnalyticsView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .id(coordinator.selectedView) // Force la recréation pour les transitions
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: coordinator.selectedView)
        .onAppear {
            currentView = coordinator.selectedView
        }
        .onChange(of: coordinator.selectedView) { oldValue, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                currentView = newValue
            }
        }
    }
}

// MARK: - Assistant IA Panel
struct AIAssistantPanel: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    
    var body: some View {
        VStack(spacing: 0) {
            // En-tête contextuel
            aiHeader
            
            // Contenu contextuel selon la vue et le document
            ScrollView {
                contextualContent
            }
            
            // Pied de page avec raccourci
            aiFooter
        }
        .frame(width: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 20, x: -5, y: 0)
        .padding(.trailing, 20)
        .padding(.vertical, 20)
    }
    
    // MARK: - En-tête Contextuel
    
    private var aiHeader: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Assistant IA")
                        .font(.headline)
                    
                    // 🔑 NOUVEAU : Indicateur visuel de statut
                    statusIndicator
                }
                
                Text(contextualSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // 🔑 NOUVEAU : Bouton paramètres dans l'en-tête
            Button {
                coordinator.showAIConfiguration()
            } label: {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .help("Configuration IA")
            
            Button {
                // 🔑 CORRECTION : Fermeture directe et explicite
                coordinator.showingAIAssistant = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .help("Fermer l'assistant")
        }
        .padding()
        .background(.regularMaterial, in: Rectangle())
    }
    
    // MARK: - Contenu Contextuel
    
    @ViewBuilder
    private var contextualContent: some View {
        VStack(spacing: 16) {
            if coordinator.selectedView == .reader && coordinator.selectedDocument != nil {
                // 🔑 CAS 1 : Dans Reader avec document - Actions contextuelles
                readerContextualActions
            } else {
                // 🔑 CAS 2 : Autres vues - Sélection de document
                documentSelectionInterface
            }
        }
        .padding()
    }
    
    // MARK: - Actions Contextuelles pour Reader
    
    private var readerContextualActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Document actuel
            if let document = coordinator.selectedDocument {
                documentInfo(document)
                Divider()
            }
            
            // 🔑 CORRECTION : Logique conditionnelle selon l'état de l'API
            if coordinator.aiService.needsAPIKey {
                // État : Configuration requise
                readerConfigurationNeeded
            } else {
                // État : Actions disponibles
                readerActionsAvailable
            }
        }
    }
    
    // 🔑 Interface de configuration pour ReaderView
    private var readerConfigurationNeeded: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: 32))
                .foregroundStyle(.blue)
            
            Text("Configuration requise")
                .font(.headline)
                .fontWeight(.medium)
            
            Text("Configurez votre clé API Gemini pour activer l'assistance IA sur ce document.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Configurer l'IA") {
                coordinator.showAIConfiguration()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // 🔑 Actions disponibles pour ReaderView
    private var readerActionsAvailable: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("💡 Actions disponibles :")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(spacing: 8) {
                actionButton(
                    title: "Expliquer cette page",
                    icon: "lightbulb.fill",
                    color: .orange
                ) {
                    // TODO: Phase 4 - Action IA réelle
                }
                
                actionButton(
                    title: "Générer un quiz",
                    icon: "questionmark.circle.fill",
                    color: .purple
                ) {
                    coordinator.navigateTo(.generation)
                }
                
                actionButton(
                    title: "Créer des flashcards",
                    icon: "rectangle.stack.fill",
                    color: .green
                ) {
                    coordinator.navigateTo(.generation)
                }
                
                actionButton(
                    title: "Résumer cette section",
                    icon: "doc.text.fill",
                    color: .blue
                ) {
                    // TODO: Phase 4 - Action IA réelle
                }
            }
            
            Divider()
            
            // 🔑 NOUVEAU : Bouton permanent pour accéder à la configuration
            configurationAccessButton
            
            Divider()
            
            // Chat interface (seulement si configuré)
            chatInterface
        }
    }
    
    // 🔑 NOUVEAU : Bouton permanent d'accès à la configuration
    private var configurationAccessButton: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("⚙️ Configuration IA")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Modèle: \(currentModelName) • \(connectionStatus)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Modifier") {
                coordinator.showAIConfiguration()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
    }
    
    // 🔑 Propriétés calculées pour la configuration
    private var currentModelName: String {
        // Récupérer le modèle sauvegardé ou utiliser celui par défaut
        if let savedModelString = UserDefaults.standard.string(forKey: "selected_ai_model"),
           let savedModel = AIModel(rawValue: savedModelString) {
            return savedModel.displayName
        }
        return AIModel.gemini20FlashLite.displayName
    }
    
    private var connectionStatus: String {
        if coordinator.aiService.isConnected {
            return "Connecté"
        } else if coordinator.aiService.needsAPIKey {
            return "Non configuré"
        } else {
            return "Déconnecté"
        }
    }
    
    // 🔑 NOUVEAU : Indicateur visuel de statut
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
    }
    
    private var statusColor: Color {
        if coordinator.aiService.isConnected {
            return .green
        } else if coordinator.aiService.needsAPIKey {
            return .orange
        } else {
            return .red
        }
    }
    
    // MARK: - Interface de Sélection de Document
    
    private var documentSelectionInterface: some View {
        VStack(spacing: 16) {
            // Introduction
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue.gradient)
                
                Text("Choisissez un document")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Sélectionnez un cours de votre bibliothèque pour commencer l'assistance IA")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Divider()
            
            // Liste des documents disponibles
            if coordinator.documents.isEmpty {
                emptyLibraryState
            } else {
                documentsList
            }
            
            // 🔑 NOUVEAU : Bouton permanent de configuration (même dans la sélection de document)
            if !coordinator.aiService.needsAPIKey {
                Divider()
                configurationAccessButton
            }
        }
    }
    
    // MARK: - États Spéciaux
    
    private var emptyLibraryState: some View {
        VStack(spacing: 12) {
            if coordinator.aiService.needsAPIKey {
                // État : API non configurée
                Image(systemName: "key")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
                
                Text("Configuration requise")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Configurez votre clé API Gemini pour activer l'IA")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Configurer l'IA") {
                    coordinator.showAIConfiguration()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                // État : pas de documents
                Image(systemName: "tray")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                
                Text("Aucun document disponible")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Importez des cours PDF pour commencer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Importer des cours") {
                    coordinator.showImportSheet()
                    coordinator.toggleAIAssistant() // Fermer l'assistant pour voir l'import
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
    }
    
    private var documentsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📚 Mes Cours (\(coordinator.documents.count))")
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVStack(spacing: 6) {
                ForEach(coordinator.documents.prefix(6)) { document in
                    documentRow(document)
                }
                
                if coordinator.documents.count > 6 {
                    Button("Voir tous les cours (\(coordinator.documents.count))") {
                        coordinator.navigateTo(.library)
                        coordinator.toggleAIAssistant()
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .padding(.top, 4)
                }
            }
        }
    }
    
    // MARK: - Composants UI
    
    private func documentRow(_ document: DocumentModel) -> some View {
        Button {
            coordinator.selectDocument(document)
            // L'assistant reste ouvert pour les actions contextuelles
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "doc.fill")
                    .foregroundStyle(.blue)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(document.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("\(document.pageCount) pages")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    
    private func documentInfo(_ document: DocumentModel) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.fill")
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(document.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(document.pageCount) pages • \(document.difficulty.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
    }
    
    private func actionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
    
    private var chatInterface: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💬 Posez une question :")
                .font(.caption)
                .fontWeight(.medium)
            
            HStack(spacing: 8) {
                TextField("Que voulez-vous savoir ?", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                
                Button {
                    // TODO: Phase 4 - Chat IA
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
    
    private var aiFooter: some View {
        VStack(spacing: 6) {
            Text("Raccourci : ⌘⇧A")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.regularMaterial, in: Rectangle())
    }
    
    // MARK: - Propriétés Calculées
    
    private var contextualSubtitle: String {
        if coordinator.selectedView == .reader && coordinator.selectedDocument != nil {
            return "Actions sur le document"
        } else {
            return "Sélectionnez un document"
        }
    }
}

// MARK: - Preview
#Preview {
    MainNavigationView()
        .environmentObject(AppCoordinator())
        .frame(width: 1200, height: 800)
} 