import Foundation

struct VaultItem: Identifiable, Codable, Hashable {
    let id: UUID
    let filename: String
    let createdAt: Date
    let type: String
    let encryptedFilename: String

    init(id: UUID = UUID(), filename: String, createdAt: Date = .now, type: String, encryptedFilename: String) {
        self.id = id
        self.filename = filename
        self.createdAt = createdAt
        self.type = type
        self.encryptedFilename = encryptedFilename
    }
}

enum PanicAction: String, CaseIterable, Identifiable {
    case lock = "Verrouiller le coffre"
    case hidePreview = "Masquer l’aperçu"
    case clearSession = "Fermer la session"
    var id: String { rawValue }
}
