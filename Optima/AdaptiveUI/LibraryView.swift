//
//  LibraryView.swift
//  AdaptiveUI
//
//  Vue de bibliothèque des documents (Phase 1)
//  Interface de base pour la gestion des cours PDF
//

import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    // 🔑 CORRECTION : Utilisation de la variable du coordinateur au lieu d'une variable locale
    
    var body: some View {
        VStack(spacing: 24) {
            // En-tête avec statistiques dynamiques
            HStack {
                VStack(alignment: .leading) {
                    Text("Mes Cours")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(statisticsText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("Importer des cours") {
                    coordinator.showImportSheet()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Contenu principal : documents réels ou état vide
            if coordinator.documents.isEmpty {
                emptyStateView
            } else {
                documentsListView
            }
        }
        .navigationTitle("Bibliothèque")
        .sheet(isPresented: $coordinator.showingImportSheet) {
            ImportSheetView()
        }
    }
    
    // MARK: - Vue de la liste des documents réels
    private var documentsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(coordinator.documents.enumerated()), id: \.element.id) { index, document in
                    RealDocumentRow(document: document) {
                        coordinator.selectDocument(document)
                    }
                    .opacity(1.0)
                    .offset(y: 0)
                    .onAppear {
                        // Animation d'apparition séquentielle
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1)) {
                            // L'animation est déjà dans l'état final
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.8)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                }
            }
            .padding()
        }
    }
    
    // MARK: - État vide avec des documents d'exemple
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Message d'état vide
            VStack(spacing: 16) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 8) {
                    Text("Aucun cours importé")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Importez vos premiers cours PDF pour commencer votre parcours d'apprentissage")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            // Bouton d'action principal
            Button("Importer des cours") {
                coordinator.showImportSheet()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // Séparateur
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.secondary.opacity(0.3))
                Text("ou découvrez avec ces exemples")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.secondary.opacity(0.3))
            }
            .padding(.horizontal, 48)
            
            // Documents d'exemple (pour démonstration)
            VStack(spacing: 8) {
                Text("Exemples de cours")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(mockDocuments, id: \.title) { document in
                            ExampleDocumentRow(document: document)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 200)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Statistiques dynamiques
    private var statisticsText: String {
        let documentCount = coordinator.documents.count
        let totalPages = coordinator.documents.reduce(0) { $0 + $1.pageCount }
        
        if documentCount == 0 {
            return "Aucun document"
        } else if documentCount == 1 {
            return "1 document • \(totalPages) pages"
        } else {
            return "\(documentCount) documents • \(totalPages) pages"
        }
    }
    
    // Documents d'exemple pour l'état vide
    private let mockDocuments = [
        MockDoc(title: "Biologie Cellulaire", subject: "Biologie", pages: 45),
        MockDoc(title: "Mathématiques Avancées", subject: "Mathématiques", pages: 78),
        MockDoc(title: "Histoire Contemporaine", subject: "Histoire", pages: 124)
    ]
}

struct DocumentRow: View {
    let document: MockDoc
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(document.subject)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(document.pages) pages")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct MockDoc {
    let title: String
    let subject: String
    let pages: Int
}

// MARK: - Composant pour les documents réels
struct RealDocumentRow: View {
    let document: DocumentModel
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icône avec animation
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isHovered)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    HStack {
                        if let subject = document.subject {
                            Text(subject)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // Badge de difficulté avec animation
                        Text(document.difficulty.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(document.difficulty.color.opacity(isHovered ? 0.3 : 0.2))
                            .foregroundColor(document.difficulty.color)
                            .cornerRadius(4)
                            .animation(.easeInOut(duration: 0.2), value: isHovered)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(document.pageCount) pages")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Indicateur de progression avec animation
                    if document.studyProgress.completionPercentage > 0 {
                        HStack(spacing: 4) {
                            ProgressView(value: document.studyProgress.completionPercentage)
                                .frame(width: 40)
                                .animation(.easeInOut(duration: 0.3), value: document.studyProgress.completionPercentage)
                            Text("\(Int(document.studyProgress.completionPercentage * 100))%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Chevron avec animation
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .scaleEffect(isHovered ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: isHovered)
            }
            .padding()
            .background(
                Color(NSColor.controlBackgroundColor)
                    .overlay(
                        // Effet de brillance au survol
                        isHovered ? 
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.05), .clear]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : nil
                    )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isHovered ? Color.blue.opacity(0.3) : Color.blue.opacity(0.1), 
                        lineWidth: isHovered ? 2 : 1
                    )
            )
            .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.02 : 1.0))
            .shadow(
                color: .black.opacity(isHovered ? 0.15 : 0.05),
                radius: isHovered ? 8 : 4,
                x: 0,
                y: isHovered ? 4 : 2
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            // Feedback sonore discret
            NSSound(named: "Pop")?.play()
            
            action()
        }
    }
}

// MARK: - Composant pour les documents d'exemple
struct ExampleDocumentRow: View {
    let document: MockDoc
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(document.title)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(document.subject)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(document.pages) p.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(6)
    }
}

struct ImportSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: AppCoordinator
    
    // États de l'interface
    @State private var isDragOver = false
    @State private var isImporting = false
    @State private var importProgress: Double = 0.0
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            // En-tête
            Text("Importer des Cours")
                .font(.title)
                .fontWeight(.semibold)
            
            // Zone de drop principale
            dropZoneView
            
            // Messages d'état
            statusMessagesView
            
            // Barre de progression
            if isImporting {
                progressView
            }
            
            // Boutons d'action
            actionButtonsView
        }
        .padding(24)
        .frame(width: 500, height: isImporting ? 450 : 400)
        .animation(.easeInOut(duration: 0.3), value: isImporting)
    }
    
    // MARK: - Zone de Drop
    
    private var dropZoneView: some View {
        VStack(spacing: 16) {
            // Icône avec animation sophistiquée
            ZStack {
                // Cercle de fond avec pulsation
                Circle()
                    .fill(isDragOver ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .scaleEffect(isDragOver ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isDragOver)
                
                Image(systemName: isDragOver ? "doc.badge.plus.fill" : "doc.badge.plus")
                    .font(.system(size: 32))
                    .foregroundStyle(isDragOver ? .green : .blue)
                    .scaleEffect(isDragOver ? 1.2 : 1.0)
                    .rotationEffect(.degrees(isDragOver ? 5 : 0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isDragOver)
            }
            
            VStack(spacing: 8) {
                Text(isDragOver ? "Relâchez pour importer" : "Glissez-déposez vos fichiers PDF ici")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(isDragOver ? .green : .primary)
                
                Text("ou cliquez pour les sélectionner")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .animation(.easeInOut(duration: 0.2), value: isDragOver)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(
            // Fond avec gradient animé
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isDragOver ? 
                    LinearGradient(colors: [.green.opacity(0.15), .green.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(colors: [.blue.opacity(0.1), .blue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .animation(.easeInOut(duration: 0.3), value: isDragOver)
        )
        .overlay(
            // Bordure animée
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isDragOver ? Color.green : Color.blue,
                    style: StrokeStyle(
                        lineWidth: isDragOver ? 3 : 2, 
                        dash: isDragOver ? [12, 4] : [8, 4],
                        dashPhase: isDragOver ? 8 : 0
                    )
                )
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isDragOver)
        )
        .onDrop(of: ["public.file-url"], isTargeted: $isDragOver) { providers in
            // Feedback sonore pour le drop
            if isDragOver {
                NSSound(named: "Glass")?.play()
            }
            return handleDrop(providers: providers)
        }
        .onTapGesture {
            // Feedback tactile simulé
            withAnimation(.easeInOut(duration: 0.1)) {
                // Petit effet de "pression"
            }
            NSSound(named: "Pop")?.play()
            openFilePicker()
        }
        .disabled(isImporting)
        .opacity(isImporting ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isImporting)
    }
    
    // MARK: - Messages d'État
    
    private var statusMessagesView: some View {
        VStack(spacing: 8) {
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            if let successMessage = successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(successMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Barre de Progression
    
    private var progressView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Import en cours...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(importProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: importProgress)
                .progressViewStyle(LinearProgressViewStyle())
        }
    }
    
    // MARK: - Boutons d'Action
    
    private var actionButtonsView: some View {
        HStack {
            Button("Annuler") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .disabled(isImporting)
            
            Spacer()
            
            Button("Sélectionner des fichiers") {
                openFilePicker()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isImporting)
        }
    }
    
    // MARK: - Gestion des Fichiers
    
    /// Gère le drop de fichiers
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        clearMessages()
        
        // 🔑 CORRECTION : Accepter tous les providers pour validation manuelle après extraction
        Task {
            await processProviders(providers)
        }
        
        return true
    }
    
    /// Ouvre le sélecteur de fichiers natif macOS
    private func openFilePicker() {
        clearMessages()
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf]
        panel.title = "Sélectionner des cours PDF"
        panel.prompt = "Importer"
        
        panel.begin { response in
            if response == .OK {
                Task {
                    await processURLs(panel.urls)
                }
            }
        }
    }
    
    /// Traite les providers de fichiers (drag & drop)
    private func processProviders(_ providers: [NSItemProvider]) async {
        await MainActor.run {
            isImporting = true
            importProgress = 0.0
        }
        
        var urls: [URL] = []
        
        // Extraction des URLs depuis les providers
        for (index, provider) in providers.enumerated() {
            await MainActor.run {
                importProgress = Double(index) / Double(providers.count) * 0.3
            }
            
            if let url = await extractURL(from: provider) {
                urls.append(url)
            }
        }
        
        await processURLs(urls)
    }
    
    /// Traite les URLs de fichiers
    private func processURLs(_ urls: [URL]) async {
        await MainActor.run {
            isImporting = true
            importProgress = 0.3
        }
        
        var successCount = 0
        var rejectedCount = 0
        let totalFiles = urls.count
        
        // 🔑 CORRECTION : Validation préalable des extensions
        let validURLs = urls.filter { url in
            url.pathExtension.lowercased() == "pdf"
        }
        
        let invalidURLs = urls.filter { url in
            url.pathExtension.lowercased() != "pdf"
        }
        
        // 🔑 CORRECTION : Affichage d'erreur pour fichiers non-PDF
        if !invalidURLs.isEmpty {
            let fileNames = invalidURLs.map { $0.lastPathComponent }.joined(separator: ", ")
            await MainActor.run {
                showError("Fichiers non-PDF rejetés: \(fileNames). Seuls les PDFs sont acceptés.")
            }
            rejectedCount = invalidURLs.count
        }
        
        // Traitement des fichiers PDF valides
        for (index, url) in validURLs.enumerated() {
            await MainActor.run {
                importProgress = 0.3 + (Double(index) / Double(totalFiles)) * 0.7
            }
            
            do {
                // Import du document via l'AppCoordinator
                try await coordinator.importDocument(from: url)
                successCount += 1
                
            } catch {
                await MainActor.run {
                    showError("Erreur d'import de \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }
        
        await MainActor.run {
            isImporting = false
            importProgress = 1.0
            
            // 🔑 CORRECTION : Messages de statut améliorés
            if successCount > 0 && rejectedCount > 0 {
                let message = "\(successCount) PDF(s) importé(s), \(rejectedCount) fichier(s) rejeté(s)"
                showSuccess(message)
            } else if successCount > 0 {
                let message = successCount == 1 ? 
                    "1 document importé avec succès" : 
                    "\(successCount) documents importés avec succès"
                showSuccess(message)
            } else if rejectedCount > 0 && successCount == 0 {
                // Message d'erreur déjà affiché plus haut
            }
            
            // Fermeture automatique seulement si succès
            if successCount > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
    
    /// Extrait l'URL depuis un NSItemProvider
    private func extractURL(from provider: NSItemProvider) async -> URL? {
        return await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                } else if let url = item as? URL {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    // MARK: - Gestion des Messages
    
    private func showError(_ message: String) {
        errorMessage = message
        successMessage = nil
        
        // Auto-effacement après 5 secondes
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if errorMessage == message {
                errorMessage = nil
            }
        }
    }
    
    private func showSuccess(_ message: String) {
        successMessage = message
        errorMessage = nil
    }
    
    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

#Preview {
    NavigationStack {
        LibraryView()
            .environmentObject(AppCoordinator())
    }
} 