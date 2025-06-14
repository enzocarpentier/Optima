import SwiftUI
import PDFKit
import Combine
import AppKit
import Foundation

// Un conteneur pour la sauvegarde et le chargement
struct LibraryData: Codable {
    var documents: [StoredPDFDocument]
    var folders: [FolderItem]
    var qcmTests: [QCMTest] = []
    var flashcardSets: [FlashcardSet] = []
    var summaries: [DocumentSummary] = []
    var keyTermLists: [KeyTermList] = []
}

// Gestionnaire pour la bibliothèque de PDF
class PDFLibraryManager: ObservableObject {
    @Published var documents: [StoredPDFDocument] = []
    @Published var folders: [FolderItem] = []
    @Published var isLoading: Bool = false
    
    // Matériel d'étude
    @Published var qcmTests: [QCMTest] = []
    @Published var flashcardSets: [FlashcardSet] = []
    @Published var summaries: [DocumentSummary] = []
    @Published var keyTermLists: [KeyTermList] = []

    static let shared = PDFLibraryManager()
    
    private let dataURL: URL
    private let pdfStorageURL: URL // Added for storing PDF files

    private init() {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls[0]
        let libraryPath = appSupportURL.appendingPathComponent("Optima")

        // Créer le dossier s'il n'existe pas
        if !FileManager.default.fileExists(atPath: libraryPath.path) {
            try? FileManager.default.createDirectory(at: libraryPath, withIntermediateDirectories: true)
        }

        self.pdfStorageURL = libraryPath.appendingPathComponent("PDFs") // Define path for PDFs
        if !FileManager.default.fileExists(atPath: self.pdfStorageURL.path) {
            try? FileManager.default.createDirectory(at: self.pdfStorageURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        self.dataURL = libraryPath.appendingPathComponent("library.json")
        
        loadLibrary()
    }
    
    // MARK: - Encodage et Décodage
    
    func loadLibrary() {
        self.isLoading = true
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }

        guard let data = try? Data(contentsOf: dataURL) else { return }
        
        let decoder = JSONDecoder()
        if let decodedData = try? decoder.decode(LibraryData.self, from: data) {
            // Re-créer les miniatures qui n'ont pas été sauvegardées
            self.documents = decodedData.documents.map { doc in
                var mutableDoc = doc
                if let pdfDocument = PDFKit.PDFDocument(url: doc.url) {
                    mutableDoc.thumbnailImage = pdfDocument.page(at: 0)?.thumbnail(of: CGSize(width: 200, height: 280), for: .cropBox)
                }
                return mutableDoc
            }
            self.folders = decodedData.folders
            self.qcmTests = decodedData.qcmTests
            self.flashcardSets = decodedData.flashcardSets
            self.summaries = decodedData.summaries
            self.keyTermLists = decodedData.keyTermLists
        }
    }
    
    func saveLibrary() {
        let dataToSave = LibraryData(documents: documents, folders: folders, qcmTests: qcmTests, flashcardSets: flashcardSets, summaries: summaries, keyTermLists: keyTermLists)
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(dataToSave) {
            try? encodedData.write(to: dataURL, options: [.atomic, .completeFileProtection])
        }
    }
    
    // MARK: - Gestion des documents
    
    func addDocument(url: URL, parentFolderId: UUID? = nil) -> Bool {
        // Generate a unique filename for the internal copy
        let uniqueFilename = UUID().uuidString + ".pdf"
        let destinationURL = self.pdfStorageURL.appendingPathComponent(uniqueFilename)

        do {
            // Copy the file from the source URL to the internal destination URL
            try FileManager.default.copyItem(at: url, to: destinationURL)
        } catch {
            print("Failed to copy PDF from \\(url) to \\(destinationURL): \\(error)")
            return false // Failed to copy the document
        }
        
        // Now, use the destinationURL (internal URL) for the PDFDocument
        guard let pdfDocument = PDFKit.PDFDocument(url: destinationURL) else {
            // If copying succeeded but PDFDocument can't be created from internal URL, clean up
            try? FileManager.default.removeItem(at: destinationURL)
            print("Failed to load PDFDocument from internal URL: \\(destinationURL)")
            return false
        }
        
        // Check if a document with the same original name (for display) already exists in the target folder
        // This check is based on display name, not internal URL.
        let displayName = url.deletingPathExtension().lastPathComponent // Use original name without extension for display
        if documents.contains(where: { $0.name == displayName && $0.parentFolderId == parentFolderId }) {
            // Optionally, handle duplicate name (e.g., by alerting user or renaming)
            // For now, we'll prevent adding if a doc with the same display name exists in the same folder.
            // Or, we could allow it, as their internal URLs would be different.
            // Let's allow it for now, as internal IDs will differ.
            // Consider if this check is still needed or how it should behave.
            // For simplicity, this check is removed to allow files with same name but different content/source.
        }

        let pageCount = pdfDocument.pageCount
        let thumbnailImage = pdfDocument.page(at: 0)?.thumbnail(of: CGSize(width: 200, height: 200), for: .cropBox)
        
        let document = StoredPDFDocument(
            name: displayName, // Store original name for display
            url: destinationURL, // Store the internal URL
            pageCount: pageCount,
            thumbnailImage: thumbnailImage,
            parentFolderId: parentFolderId
        )
        
        documents.append(document)
        saveLibrary() // Sauvegarder après ajout
        return true
    }
    
    func removeDocument(id: UUID) {
        if let index = documents.firstIndex(where: { $0.id == id }) {
            let documentToRemove = documents[index]
            // Attempt to delete the actual PDF file from internal storage
            do {
                try FileManager.default.removeItem(at: documentToRemove.url)
            } catch {
                print("Failed to delete PDF file at \\(documentToRemove.url): \\(error)")
                // Continue to remove from library even if file deletion fails, or handle error more strictly
            }
        }
        documents.removeAll(where: { $0.id == id })
        saveLibrary() // Sauvegarder après suppression
    }
    
    func renameDocument(id: UUID, newName: String) {
        if let index = documents.firstIndex(where: { $0.id == id }) {
            documents[index].name = newName
            saveLibrary() // Sauvegarder après renommage
        }
    }
    
    func moveDocument(id: UUID, toFolderId: UUID?) {
        if let index = documents.firstIndex(where: { $0.id == id }) {
            documents[index].parentFolderId = toFolderId
            saveLibrary() // Sauvegarder après déplacement
        }
    }
    
    // MARK: - Gestion des dossiers
    
    func createFolder(name: String, parentId: UUID? = nil) -> FolderItem {
        let folder = FolderItem(name: name, parentFolderId: parentId)
        folders.append(folder)
        saveLibrary() // Sauvegarder après création
        return folder
    }
    
    func removeFolder(id: UUID) {
        // Supprimer le dossier et son contenu récursivement (simplifié pour l'instant)
        folders.removeAll(where: { $0.id == id })
        documents.removeAll(where: { $0.parentFolderId == id })
        saveLibrary() // Sauvegarder après suppression
    }
    
    func renameFolder(id: UUID, newName: String) {
        if let index = folders.firstIndex(where: { $0.id == id }) {
            folders[index].name = newName
            saveLibrary() // Sauvegarder après renommage
        }
    }
    
    func moveFolder(id: UUID, toParentId: UUID?) {
        if let index = folders.firstIndex(where: { $0.id == id }) {
            folders[index].parentFolderId = toParentId
            saveLibrary() // Sauvegarder après déplacement
        }
    }
    
    func deleteFolder(id: UUID) {
        folders.removeAll { $0.id == id }
        saveLibrary() // Sauvegarder après suppression
    }
    
    // MARK: - Sauvegarde du matériel d'étude

    func save(item: QCMTest) {
        qcmTests.append(item)
        saveLibrary()
    }

    func save(item: FlashcardSet) {
        flashcardSets.append(item)
        saveLibrary()
    }
    
    func save(item: DocumentSummary) {
        summaries.append(item)
        saveLibrary()
    }

    func save(item: KeyTermList) {
        keyTermLists.append(item)
        saveLibrary()
    }
    
    // MARK: - Navigation et filtrage
    
    func getRootItems() -> [any LibraryItem] {
        let rootFolders = folders.filter { $0.parentFolderId == nil }
        let rootDocs = documents.filter { $0.parentFolderId == nil }
        var items: [any LibraryItem] = []
        items.append(contentsOf: rootFolders)
        items.append(contentsOf: rootDocs)
        return items
    }
    
    func getItemsInFolder(folderId: UUID?) -> [any LibraryItem] {
        guard let folderId = folderId else { return getRootItems() }
        let subFolders = folders.filter { $0.parentFolderId == folderId }
        let subDocs = documents.filter { $0.parentFolderId == folderId }
        var items: [any LibraryItem] = []
        items.append(contentsOf: subFolders)
        items.append(contentsOf: subDocs)
        return items
    }
    
    func getBreadcrumbs(forFolderId folderId: UUID?) -> [FolderItem] {
        var crumbs: [FolderItem] = []
        var currentId = folderId
        while let id = currentId, let folder = folders.first(where: { $0.id == id }) {
            crumbs.insert(folder, at: 0)
            currentId = folder.parentFolderId
        }
        return crumbs
    }
    
    // MARK: - Gestion des miniatures
    
    func updateThumbnail(for documentId: UUID) {
        guard let index = documents.firstIndex(where: { $0.id == documentId }),
              let pdfDocument = PDFKit.PDFDocument(url: documents[index].url),
              let thumbnail = pdfDocument.page(at: 0)?.thumbnail(of: CGSize(width: 200, height: 200), for: .cropBox) else {
            return
        }
        
        var document = documents[index]
        document.thumbnailImage = thumbnail
        documents[index] = document
    }
    
    func getDocument(id: UUID) -> StoredPDFDocument? {
        return documents.first { $0.id == id }
    }
}