import SwiftUI
import PDFKit
import AppKit

// MARK: - Protocols
public protocol LibraryItem: Identifiable {
    var id: UUID { get }
    var name: String { get }
    var dateAdded: Date { get }
    var itemType: LibraryItemType { get }
    var parentFolderId: UUID? { get }
}

// MARK: - Enums
public enum LibraryItemType {
    case folder
    case document
}

// MARK: - Models
public struct FolderItem: LibraryItem, Codable {
    public let id: UUID
    public var name: String
    public let dateAdded: Date
    public var parentFolderId: UUID?
    public var itemType: LibraryItemType { .folder }
    
    public init(id: UUID = UUID(), name: String, dateAdded: Date = Date(), parentFolderId: UUID? = nil) {
        self.id = id
        self.name = name
        self.dateAdded = dateAdded
        self.parentFolderId = parentFolderId
    }
}

public struct StoredPDFDocument: LibraryItem, Codable {
    public let id: UUID
    public var name: String
    public let url: URL
    public let dateAdded: Date
    public let pageCount: Int
    public var thumbnailImage: NSImage?
    public var parentFolderId: UUID?
    public var itemType: LibraryItemType { .document }
    
    // Clés pour l'encodage/décodage, en excluant la miniature
    enum CodingKeys: String, CodingKey {
        case id, name, url, dateAdded, pageCount, parentFolderId
    }
    
    // Initialiseur pour la création
    public init(id: UUID = UUID(), name: String, url: URL, dateAdded: Date = Date(), pageCount: Int, thumbnailImage: NSImage? = nil, parentFolderId: UUID? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.dateAdded = dateAdded
        self.pageCount = pageCount
        self.thumbnailImage = thumbnailImage
        self.parentFolderId = parentFolderId
    }
    
    // Initialiseur pour le décodage (depuis un fichier)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.url = try container.decode(URL.self, forKey: .url)
        self.dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        self.pageCount = try container.decode(Int.self, forKey: .pageCount)
        self.parentFolderId = try container.decodeIfPresent(UUID.self, forKey: .parentFolderId)
        self.thumbnailImage = nil // La miniature sera régénérée
    }
    
    // Fonction pour l'encodage (vers un fichier)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encode(pageCount, forKey: .pageCount)
        try container.encodeIfPresent(parentFolderId, forKey: .parentFolderId)
    }
} 