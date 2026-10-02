import Foundation
import UIKit

@MainActor
final class PrivacyManager: ObservableObject {
    @Published var isPanicMode = false
    @Published var autoLockMinutes = 5
    @Published var hidePreviews = true

    func activatePanic(vault: VaultStore) {
        isPanicMode = true
        vault.lock()
        hidePreviews = true
    }

    func deactivatePanic() {
        isPanicMode = false
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func openPrivacySettings() {
        guard let url = URL(string: "App-prefs:root=Privacy") else { return }
        UIApplication.shared.open(url)
    }

    func openPasscodeSettings() {
        guard let url = URL(string: "App-prefs:root=PASSCODE") else { return }
        UIApplication.shared.open(url)
    }
}
