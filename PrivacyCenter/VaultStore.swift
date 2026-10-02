import Foundation
import PhotosUI
import UIKit

@MainActor
final class VaultStore: ObservableObject {
    @Published private(set) var items: [VaultItem] = []
    @Published var isUnlocked = false

    private let fm = FileManager.default
    private var vaultURL: URL {
        fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Vault", isDirectory: true)
    }

    private var metadataURL: URL { vaultURL.appendingPathComponent("metadata.json") }

    init() {
        try? fm.createDirectory(at: vaultURL, withIntermediateDirectories: true)
        loadMetadata()
    }

    func unlock() async {
        do {
            try await BiometricAuth.shared.authenticate(reason: "Déverrouiller Privacy Center")
            isUnlocked = true
        } catch {
            isUnlocked = false
        }
    }

    func lock() {
        isUnlocked = false
    }

    func importItem(data: Data, originalName: String, type: String) {
        guard isUnlocked else { return }
        do {
            let encrypted = try VaultCrypto.shared.encrypt(data)
            let safeName = UUID().uuidString + ".vault"
            try encrypted.write(to: vaultURL.appendingPathComponent(safeName), options: .completeFileProtection)
            let item = VaultItem(filename: originalName, type: type, encryptedFilename: safeName)
            items.insert(item, at: 0)
            saveMetadata()
        } catch {
            print("Vault import error:", error)
        }
    }

    func delete(_ item: VaultItem) {
        guard isUnlocked else { return }
        try? fm.removeItem(at: vaultURL.appendingPathComponent(item.encryptedFilename))
        items.removeAll { $0.id == item.id }
        saveMetadata()
    }

    func clearVault() {
        guard isUnlocked else { return }
        for item in items {
            try? fm.removeItem(at: vaultURL.appendingPathComponent(item.encryptedFilename))
        }
        items.removeAll()
        saveMetadata()
    }

    private func loadMetadata() {
        guard let data = try? Data(contentsOf: metadataURL),
              let decoded = try? JSONDecoder().decode([VaultItem].self, from: data) else { return }
        items = decoded
    }

    private func saveMetadata() {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: metadataURL, options: .completeFileProtection)
        }
    }
}
