import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import AppKit

// MARK: - Formatage des dates
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    formatter.locale = Locale(identifier: "fr_FR")
    return formatter
}()

// MARK: - Composants réutilisables

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))
            
            TextField("Rechercher...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct BreadcrumbView: View {
    let items: [FolderItem]
    let currentFolderId: UUID?
    let onSelect: (UUID?) -> Void
    let onDrop: (UUID?, String) -> Void
    @State private var isHomeDropTargeted = false
    @State private var libraryGridId = UUID()
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Bouton Accueil
                Button(action: { onSelect(nil) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 12))
                        Text("Accueil")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        ZStack {
                            Color.white.opacity(currentFolderId == nil ? 0.15 : 0.05)
                            if isHomeDropTargeted {
                                Color.blue.opacity(0.4).blur(radius: 5)
                            }
                        }
                    )
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHomeDropTargeted ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .dropDestination(for: String.self) { items, location in
                    if let payload = items.first {
                        onDrop(nil, payload)
                        return true
                    }
                    return false
                } isTargeted: { targeted in
                    withAnimation(.spring()) {
                        isHomeDropTargeted = targeted
                    }
                }
                
                // Chemin des dossiers
                ForEach(items) { folder in
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                    
                    BreadcrumbFolderView(
                        folder: folder,
                        isCurrent: currentFolderId == folder.id,
                        onSelect: { onSelect(folder.id) },
                        onDrop: { payload in
                            onDrop(folder.id, payload)
                        }
                    )
                }
            }
            .padding(.vertical, 4)
        }
        .id(libraryGridId)
    }
}

private struct BreadcrumbFolderView: View {
    let folder: FolderItem
    let isCurrent: Bool
    let onSelect: () -> Void
    let onDrop: (String) -> Void
    @State private var isDropTargeted = false
    
    var body: some View {
        Button(action: onSelect) {
            Text(folder.name)
                .font(.system(size: 12, weight: .medium))
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    ZStack {
                        Color.white.opacity(isCurrent ? 0.15 : 0.05)
                        if isDropTargeted {
                            Color.blue.opacity(0.4).blur(radius: 5)
                        }
                    }
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isDropTargeted ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .dropDestination(for: String.self) { items, location in
            if let payload = items.first {
                onDrop(payload)
                return true
            }
            return false
        } isTargeted: { targeted in
            withAnimation(.spring()) {
                isDropTargeted = targeted
            }
        }
    }
}

// MARK: - Vue principale

struct LibraryView: View {
    @ObservedObject var libraryManager = PDFLibraryManager.shared
    @ObservedObject var aiService = AIService.shared
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var searchText = ""
    @State private var currentFolderId: UUID? = nil
    @State private var selectedItemId: UUID? = nil
    @State private var showPDFPreview = false
    @State private var showNewFolderDialog = false
    @State private var showRenameDialog = false
    @State private var showMoveDialog = false
    @State private var newFolderName = ""
    @State private var renameText = ""
    @State private var showFileImporter = false 
    @State private var targetFolderId: UUID? = nil
    @State private var contextMenuPosition: CGPoint? = nil
    @State private var menuTargetId: UUID? = nil
    @State private var isGridView = true // true = grille, false = liste
    
    // Remplacer @State private var actionDocument: StoredPDFDocument? = nil
    @State private var documentForAction: StoredPDFDocument? = nil
    @State private var showDocumentActionMenu = false
    
    // États pour l'IA
    @State private var showAIError = false
    @State private var aiErrorMessage = ""
    
    // Navigation vers les vues d'IA générée
    @State private var showQCMView = false
    @State private var showFlashcardView = false
    @State private var showSummaryView = false
    @State private var showTermDefinitionView = false
    @State private var generatedQCM: QCMTest? = nil
    @State private var generatedFlashcardSet: FlashcardSet? = nil
    @State private var generatedSummary: DocumentSummary? = nil
    @State private var generatedTermList: KeyTermList? = nil
    @State private var showQCMGenerationSuccess = false
    @State private var completedQCM: QCMTest?
    
    // Filtrer les éléments en fonction de la recherche
    var filteredItems: [any LibraryItem] {
        let items = currentFolderId == nil 
            ? libraryManager.getRootItems()
            : libraryManager.getItemsInFolder(folderId: currentFolderId)
        
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { 
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    // Trier les éléments - dossiers d'abord, puis documents, par ordre alphabétique
    var sortedItems: [any LibraryItem] {
        filteredItems.sorted { item1, item2 in
            if item1.itemType == item2.itemType {
                return item1.name.lowercased() < item1.name.lowercased()
            } else {
                return item1.itemType == .folder
            }
        }
    }
    
    // Fil d'Ariane pour la navigation
    var breadcrumbs: [FolderItem] {
        let crumbs = libraryManager.getBreadcrumbs(forFolderId: currentFolderId)
        return crumbs
    }
    
    private func moveItem(with payload: String, to destinationFolderId: UUID?) {
        guard let sourceId = UUID(uuidString: payload) else { return }

        // Empêcher de déposer un dossier sur lui-même
        if sourceId == destinationFolderId { return }

        // Logique de déplacement via le manager
        if libraryManager.folders.contains(where: { $0.id == sourceId }) {
            libraryManager.moveFolder(id: sourceId, toParentId: destinationFolderId)
        } else if libraryManager.documents.contains(where: { $0.id == sourceId }) {
            libraryManager.moveDocument(id: sourceId, toFolderId: destinationFolderId)
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // En-tête
                LibraryHeaderView(
                    searchText: $searchText,
                    isGridView: $isGridView,
                    breadcrumbs: breadcrumbs,
                    onNewFolder: {
                        newFolderName = "Nouveau dossier"
                        showNewFolderDialog = true
                    },
                    onImportFile: { 
                        showFileImporter = true
                    },
                    onNavigate: { folderId in
                        withAnimation {
                            currentFolderId = folderId
                        }
                    },
                    onDrop: { destinationId, payload in
                        moveItem(with: payload, to: destinationId)
                    }
                )

                // Contenu principal
                mainContentView
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.1)) // Fond subtil
            .sheet(isPresented: $showPDFPreview) {
                if let docId = selectedItemId, let doc = libraryManager.documents.first(where: { $0.id == docId }) {
                    PDFPreview(document: doc, onDismiss: { showPDFPreview = false })
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result: result)
            }
            .sheet(isPresented: $showQCMView) {
                if let qcm = generatedQCM {
                    QuizView(qcmTest: qcm)
                }
            }
            .sheet(isPresented: $showFlashcardView) {
                if let flashcardSet = generatedFlashcardSet {
                    FlashcardView(flashcardSet: flashcardSet)
                }
            }
            .sheet(isPresented: $showSummaryView) {
                if let summary = generatedSummary {
                    SummaryView(documentSummary: summary)
                }
            }
            .sheet(isPresented: $showTermDefinitionView) {
                if let termList = generatedTermList {
                    TermDefinitionView(keyTermList: termList)
                }
            }
            .overlay(overlayContent)
            .alert("Erreur de l'IA", isPresented: $showAIError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(aiErrorMessage)
            }
            
            // Overlay pour le menu d'actions du document
            if showDocumentActionMenu, let document = documentForAction {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showDocumentActionMenu = false
                    }
                
                DocumentActionView(
                    document: document,
                    onDismiss: { showDocumentActionMenu = false },
                    onShowPreview: {
                        showDocumentActionMenu = false
                        // Petit délai pour assurer la transition fluide
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.selectedItemId = document.id
                            showPDFPreview = true
                        }
                    },
                    onGenerateQCM: {
                        Task {
                            showDocumentActionMenu = false
                            await generateQCM(for: document)
                        }
                    },
                    onGenerateFlashcards: {
                        Task {
                            showDocumentActionMenu = false
                            await generateFlashcards(for: document)
                        }
                    },
                    onGenerateSummary: {
                        Task {
                            showDocumentActionMenu = false
                            await generateSummary(for: document)
                        }
                    },
                    onGenerateDefinitions: {
                        Task {
                            showDocumentActionMenu = false
                            await generateTermDefinitions(for: document)
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: showDocumentActionMenu)
    }
    
    // MARK: - Vues composées
    
    @ViewBuilder
    private var mainContentView: some View {
        if libraryManager.isLoading {
            Spacer()
            ProgressView("Chargement de la bibliothèque...")
                .controlSize(.large)
            Spacer()
        } else if filteredItems.isEmpty && !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if filteredItems.isEmpty {
            EmptyLibraryView(onImport: { showFileImporter = true })
        } else {
            if isGridView {
                LibraryGridView(
                    items: sortedItems,
                    selectedItemId: $selectedItemId,
                    libraryManager: libraryManager,
                    onDoubleClick: handleDoubleClick,
                    onMove: moveItem,
                    contextMenuProvider: { item in
                        itemContextMenu(for: item)
                    }
                )
            } else {
                LibraryListView(
                    items: sortedItems,
                    selectedItemId: $selectedItemId,
                    libraryManager: libraryManager,
                    onDoubleClick: handleDoubleClick,
                    contextMenuProvider: { item in
                        itemContextMenu(for: item)
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        Group {
            if aiService.isProcessing {
                VStack {
                    Text(aiService.currentTask)
                        .font(.headline)
                        .foregroundColor(.white)
                    ProgressView(value: aiService.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .frame(width: 200)
                }
                .padding(20)
                .background(Color.black.opacity(0.7))
                .cornerRadius(15)
            } else if showQCMGenerationSuccess {
                GenerationSuccessView(
                    message: "QCM généré avec succès!",
                    onDismiss: { showQCMGenerationSuccess = false },
                    onNavigate: {
                        showQCMGenerationSuccess = false
                        if let qcm = completedQCM {
                            navigationManager.requestNavigation(to: .studyTab(studyItemId: qcm.id))
                        }
                    }
                )
            }
        }
    }

    // MARK: - Actions & Menus

    @ViewBuilder
    private func itemContextMenu(for item: any LibraryItem) -> some View {
        Button("Renommer") {
            menuTargetId = item.id
            renameText = item.name
            showRenameDialog = true
        }

        Button("Déplacer") {
            menuTargetId = item.id
            showMoveDialog = true
        }

        Divider()

        Button("Supprimer", role: .destructive) {
            if let doc = item as? StoredPDFDocument {
                libraryManager.removeDocument(id: doc.id)
            } else if let folder = item as? FolderItem {
                libraryManager.removeFolder(id: folder.id)
            }
        }
    }

    // MARK: - Gestionnaires d'événements
    private func handleDoubleClick(on item: any LibraryItem) {
        if let folder = item as? FolderItem {
            withAnimation {
                currentFolderId = folder.id
                selectedItemId = nil
            }
        } else if let doc = item as? StoredPDFDocument {
            selectedItemId = doc.id
            documentForAction = doc
            showDocumentActionMenu = true
        }
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                let securityScoped = url.startAccessingSecurityScopedResource()
                defer {
                    if securityScoped {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let success = libraryManager.addDocument(url: url, parentFolderId: currentFolderId)
                if !success {
                    aiErrorMessage = "Impossible d'accéder au fichier : \(url.lastPathComponent). Vérifiez les autorisations."
                    showAIError = true
                }
            }
        case .failure(let error):
            aiErrorMessage = "Erreur d'importation : \(error.localizedDescription)"
            showAIError = true
        }
    }

    // MARK: - Actions IA
    
    private func generateQCM(for document: StoredPDFDocument) async {
        let textResult = PDFTextExtractor.shared.extractText(from: document.url)
        let documentText: String
        
        switch textResult {
        case .success(let text):
            documentText = text
        case .failure(let error):
            aiErrorMessage = "Impossible d'extraire le texte du document : \(error.localizedDescription)"
            showAIError = true
            return
        }
        
        do {
            let quizQuestions = try await aiService.generateQCM(text: documentText, numQuestions: 10, language: "fr")
            let quizResponse = QuizResponse(questions: quizQuestions, metadata: nil)
            let qcmTest = QCMTest(documentId: document.id, documentName: document.name, quizResponse: quizResponse)
            
            libraryManager.save(item: qcmTest)
            
            // Mettre à jour l'état pour afficher la vue de succès
            completedQCM = qcmTest
            showQCMGenerationSuccess = true
            
        } catch {
            aiErrorMessage = aiService.handleError(error)
            showAIError = true
        }
    }
    
    private func generateFlashcards(for document: StoredPDFDocument) async {
        let textResult = PDFTextExtractor.shared.extractText(from: document.url)
        let documentText: String
        
        switch textResult {
        case .success(let text):
            documentText = text
        case .failure(let error):
            aiErrorMessage = "Impossible d'extraire le texte du document : \(error.localizedDescription)"
            showAIError = true
            return
        }
        
        do {
            let flashcards = try await aiService.generateFlashcards(text: documentText, numFlashcards: 20, language: "fr")
            
            let flashcardResponse = FlashCardResponse(
                flashcards: flashcards,
                metadata: FlashCardMetadata(version: "1.0", level: "intermediate", subject: "general")
            )
            
            let flashcardSet = FlashcardSet(
                documentId: document.id,
                documentName: document.name,
                flashcardResponse: flashcardResponse
            )
            
            libraryManager.save(item: flashcardSet)

            generatedFlashcardSet = flashcardSet
            showFlashcardView = true // TODO: Remplacer par une vue de succès similaire au QCM
            
        } catch {
            aiErrorMessage = aiService.handleError(error)
            showAIError = true
        }
    }
    
    private func generateSummary(for document: StoredPDFDocument) async {
        let textResult = PDFTextExtractor.shared.extractText(from: document.url)
        let documentText: String
        
        switch textResult {
        case .success(let text):
            documentText = text
        case .failure(let error):
            aiErrorMessage = "Impossible d'extraire le texte du document : \(error.localizedDescription)"
            showAIError = true
            return
        }
        
        do {
            let textSummary = try await aiService.generateSummary(text: documentText, language: "fr", length: .medium)
            
            let documentSummary = DocumentSummary(
                documentId: document.id,
                documentName: document.name,
                textSummary: textSummary
            )
            
            libraryManager.save(item: documentSummary)
            
            generatedSummary = documentSummary
            showSummaryView = true // TODO: Remplacer par une vue de succès
            
        } catch {
            aiErrorMessage = aiService.handleError(error)
            showAIError = true
        }
    }
    
    private func generateTermDefinitions(for document: StoredPDFDocument) async {
        let textResult = PDFTextExtractor.shared.extractText(from: document.url)
        let documentText: String
        
        switch textResult {
        case .success(let text):
            documentText = text
        case .failure(let error):
            aiErrorMessage = "Impossible d'extraire le texte du document : \(error.localizedDescription)"
            showAIError = true
            return
        }
        
        do {
            // Approche simplifiée pour extraire des termes : on prend des mots uniques de plus de 5 lettres.
            let words = documentText.components(separatedBy: .whitespacesAndNewlines)
            let commonTerms = Array(Set(words.filter { $0.count > 5 && !$0.lowercased().starts(with: "http") })).prefix(15)
            
            let termDefinitions = try await aiService.generateDefinitions(text: documentText, terms: Array(commonTerms), language: "fr")
            
            guard !termDefinitions.isEmpty else {
                aiErrorMessage = "L'IA n'a pas pu générer de définitions pour les termes de ce document."
                showAIError = true
                return
            }

            let termResponse = TermDefinitionResponse(definitions: termDefinitions, metadata: nil)
            
            let keyTermList = KeyTermList(
                documentId: document.id,
                documentName: document.name,
                termResponse: termResponse
            )
            
            libraryManager.save(item: keyTermList)

            generatedTermList = keyTermList
            showTermDefinitionView = true // TODO: Remplacer par une vue de succès
            
        } catch {
            aiErrorMessage = aiService.handleError(error)
            showAIError = true
        }
    }
}

// MARK: - Sous-vues pour l'affichage de la bibliothèque

private struct EmptyLibraryView: View {
    let onImport: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Votre bibliothèque est vide")
                .font(.title2)
                .fontWeight(.bold)
            Text("Importez des documents PDF pour commencer à générer du contenu d'étude.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Importer un document", action: onImport)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct LibraryGridView: View {
    let items: [any LibraryItem]
    @Binding var selectedItemId: UUID?
    var libraryManager: PDFLibraryManager
    let onDoubleClick: (any LibraryItem) -> Void
    let onMove: (String, UUID) -> Void
    let contextMenuProvider: (any LibraryItem) -> any View

    private let columns = [GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 20)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(items, id: \.id) { item in
                    LibraryItemCell(item: item, isSelected: selectedItemId == item.id)
                        .highPriorityGesture(TapGesture(count: 2).onEnded { onDoubleClick(item) })
                        .simultaneousGesture(TapGesture().onEnded { selectedItemId = item.id })
                        .contextMenu {
                            AnyView(contextMenuProvider(item))
                        }
                        .onDrag { NSItemProvider(object: item.id.uuidString as NSString) }
                        .dropDestination(for: String.self) { droppedItems, _ in
                            guard let firstId = droppedItems.first, item.itemType == .folder else { return false }
                            onMove(firstId, item.id)
                            return true
                        }
                }
            }
            .padding()
        }
        .background(Color.clear)
        .onTapGesture { selectedItemId = nil }
    }
}

private struct LibraryListView: View {
    let items: [any LibraryItem]
    @Binding var selectedItemId: UUID?
    var libraryManager: PDFLibraryManager
    let onDoubleClick: (any LibraryItem) -> Void
    let contextMenuProvider: (any LibraryItem) -> any View

    var body: some View {
        List(selection: $selectedItemId) {
            ForEach(items, id: \.id) { item in
                LibraryListItemCell(item: item, libraryManager: libraryManager)
                    .onTapGesture(count: 2) { onDoubleClick(item) }
                    .listRowBackground(Color.clear)
                    .contextMenu {
                        AnyView(contextMenuProvider(item))
                    }
            }
        }
        .scrollContentBackground(.hidden)
    }
}

private struct LibraryItemCell: View {
    let item: any LibraryItem
    let isSelected: Bool

    var body: some View {
        if let folder = item as? FolderItem {
            FolderGridItemView(folder: folder, isSelected: isSelected)
        } else if let document = item as? StoredPDFDocument {
            DocumentGridItemView(document: document, isSelected: isSelected)
        }
    }
}

private struct LibraryListItemCell: View {
    let item: any LibraryItem
    @ObservedObject var libraryManager: PDFLibraryManager

    var body: some View {
        if let folder = item as? FolderItem {
            FolderListItemView(folder: folder, libraryManager: libraryManager)
        } else if let document = item as? StoredPDFDocument {
            DocumentListItemView(document: document)
        }
    }
}

// MARK: - Vues des éléments de la bibliothèque

private struct FolderGridItemView: View {
    let folder: FolderItem
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                
                Image(systemName: "folder.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow.opacity(0.8))
                    .shadow(color: .yellow.opacity(0.3), radius: 5)
            }
            
            Text(folder.name)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(height: 180)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? 
                            LinearGradient(
                                colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            GlassStyle.strokeGradient,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        )
        .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.2), radius: 10)
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

private struct DocumentGridItemView: View {
    let document: StoredPDFDocument
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                if let thumbnail = document.thumbnailImage {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.2), radius: 5)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .frame(height: 120)
                        .overlay(
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(document.pageCount) pages")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? 
                            LinearGradient(
                                colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            GlassStyle.strokeGradient,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        )
        .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.2), radius: 10)
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

private struct FolderListItemView: View {
    let folder: FolderItem
    @ObservedObject var libraryManager: PDFLibraryManager
    
    private var documentCount: Int {
        libraryManager.getItemsInFolder(folderId: folder.id).filter { $0.itemType == .document }.count
    }

    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundColor(.yellow)
                .font(.title2)
            Text(folder.name)
                .font(.body)
                .foregroundColor(.white)
            Spacer()
            Text("\(documentCount) éléments")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

private struct DocumentListItemView: View {
    let document: StoredPDFDocument
    
    var body: some View {
        HStack {
            Image(systemName: "doc.text.fill")
                .foregroundColor(.white)
                .font(.title2)
            VStack(alignment: .leading) {
                Text(document.name)
                    .font(.body)
                    .foregroundColor(.white)
                Text(document.url.lastPathComponent)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("\(document.pageCount) pages")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Vue de sélection de dossier

struct FolderSelectionView: View {
    @ObservedObject var libraryManager: PDFLibraryManager
    @State private var currentFolderId: UUID? = nil
    let itemToMoveId: UUID?
    
    let onSelect: (UUID?) -> Void
    let onCancel: () -> Void
    
    private var folders: [FolderItem] {
        libraryManager.getItemsInFolder(folderId: currentFolderId)
            .compactMap { $0 as? FolderItem }
            .filter { $0.id != itemToMoveId }
    }
    
    var body: some View {
        VStack {
            Text("Déplacer vers...")
                .font(.title2)
                .padding()
            
            // TODO: Ajouter un fil d'Ariane ici
            
            List(folders, id: \.id) { folder in
                Button(action: {
                    onSelect(folder.id)
                }) {
                    HStack {
                        Image(systemName: "folder.fill")
                        Text(folder.name)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Bouton pour déplacer à la racine
            Button(action: {
                onSelect(nil)
            }) {
                HStack {
                    Image(systemName: "tray.full.fill")
                    Text("Bibliothèque (racine)")
                }
            }
            .padding()
            
            HStack {
                Button("Annuler", role: .cancel, action: onCancel)
            }
            .padding()
        }
        .frame(width: 400, height: 500)
    }
}

// MARK: - Vue d'aperçu PDF

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
    }
}

private struct DocumentActionView: View {
    let document: StoredPDFDocument
    let onDismiss: () -> Void
    let onShowPreview: () -> Void
    let onGenerateQCM: () -> Void
    let onGenerateFlashcards: () -> Void
    let onGenerateSummary: () -> Void
    let onGenerateDefinitions: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.accentColor)

            Text(document.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                actionButton(
                    title: "Générer un QCM",
                    icon: "questionmark.diamond.fill",
                    color: .cyan,
                    action: onGenerateQCM
                )
                actionButton(
                    title: "Créer des Flashcards",
                    icon: "rectangle.stack.fill",
                    color: .purple,
                    action: onGenerateFlashcards
                )
                actionButton(
                    title: "Résumer le texte",
                    icon: "text.book.closed.fill",
                    color: .orange,
                    action: onGenerateSummary
                )
                actionButton(
                    title: "Définir les termes",
                    icon: "character.book.closed.fill",
                    color: .green,
                    action: onGenerateDefinitions
                )
            }

            HStack(spacing: 16) {
                Button(action: onDismiss) {
                    Text("Fermer")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onShowPreview) {
                    Label("Ouvrir le document", systemImage: "arrow.right.circle.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(32)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 32, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 20)
        .frame(maxWidth: 500)
    }
    
    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding()
            .background(color.opacity(0.15))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Vues supplémentaires

private struct LibraryHeaderView: View {
    @Binding var searchText: String
    @Binding var isGridView: Bool
    let breadcrumbs: [FolderItem]
    let onNewFolder: () -> Void
    let onImportFile: () -> Void
    let onNavigate: (UUID?) -> Void
    let onDrop: (UUID?, String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Bibliothèque")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Bouton pour changer de vue (grille/liste)
                Button(action: {
                    withAnimation { isGridView.toggle() }
                }) {
                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                // Bouton pour créer un nouveau dossier
                Button(action: onNewFolder) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                // Bouton pour importer un fichier
                Button(action: onImportFile) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Fil d'Ariane
            if !breadcrumbs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        // Bouton pour revenir à la racine
                        DropTargetButton(onDrop: { payload in onDrop(nil, payload) }, contentBuilder: {
                            HStack(spacing: 2) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 12))
                                Text("Accueil")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                        })
                        .onTapGesture { onNavigate(nil) }

                        // Chemin des dossiers
                        ForEach(breadcrumbs) { folder in
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 2)
                            
                            DropTargetButton(onDrop: { payload in onDrop(folder.id, payload) }, contentBuilder: {
                                Text(folder.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                            })
                            .onTapGesture { onNavigate(folder.id) }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Barre de recherche
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.7))
                
                TextField("Rechercher...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .colorScheme(.dark)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.9),
                    Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// Wrapper pour rendre n'importe quelle vue une zone de dépôt
private struct DropTargetButton<Content: View>: View {
    let onDrop: (String) -> Void
    let viewContent: () -> Content
    @State private var isTargeted = false

    init(onDrop: @escaping (String) -> Void, @ViewBuilder contentBuilder: @escaping () -> Content) {
        self.onDrop = onDrop
        self.viewContent = contentBuilder
    }

    var body: some View {
        viewContent()
            .background(isTargeted ? Color.blue.opacity(0.4) : Color.clear)
            .dropDestination(for: String.self) { items, _ in
                guard let payload = items.first else { return false }
                onDrop(payload)
                return true
            } isTargeted: { isTargeted in
                withAnimation(.spring()) {
                    self.isTargeted = isTargeted
                }
            }
    }
}
