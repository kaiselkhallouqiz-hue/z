import SwiftUI

@main
struct PrivacyCenterApp: App {
    @StateObject private var vault = VaultStore()
    @StateObject private var privacy = PrivacyManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vault)
                .environmentObject(privacy)
                .preferredColorScheme(.dark)
        }
    }
}
