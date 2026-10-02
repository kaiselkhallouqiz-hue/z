import SwiftUI
import PhotosUI

struct ContentView: View {
    @EnvironmentObject var vault: VaultStore
    @EnvironmentObject var privacy: PrivacyManager

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Accueil", systemImage: "shield.fill") }
                .tag(0)

            VaultView()
                .tabItem { Label("Coffre", systemImage: "lock.fill") }
                .tag(1)

            PrivacyView()
                .tabItem { Label("Privacy", systemImage: "hand.raised.fill") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Réglages", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(.cyan)
        .onChange(of: privacy.isPanicMode) { _, value in
            if value { selectedTab = 0 }
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject var vault: VaultStore
    @EnvironmentObject var privacy: PrivacyManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header

                    Button {
                        privacy.activatePanic(vault: vault)
                    } label: {
                        Label("MODE PANIC", systemImage: "exclamationmark.shield.fill")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    HStack(spacing: 12) {
                        StatCard(title: "Coffre", value: "\(vault.items.count)", icon: "lock.fill")
                        StatCard(title: "Protection", value: privacy.isPanicMode ? "PANIC" : "Active", icon: "shield.fill")
                    }

                    NavigationLink {
                        PhotoPrivacyView()
                    } label: {
                        ActionCard(title: "Photos & vidéos", subtitle: "Analyser les éléments récents", icon: "photo.on.rectangle")
                    }

                    NavigationLink {
                        PermissionView()
                    } label: {
                        ActionCard(title: "Privacy Scan", subtitle: "Vérifier les autorisations", icon: "checkmark.shield")
                    }
                }
                .padding()
            }
            .navigationTitle("Privacy Center")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CENTRE DE CONFIDENTIALITÉ")
                .font(.caption.bold())
                .foregroundStyle(.cyan)
            Text("Protection maximale")
                .font(.largeTitle.bold())
            Text("Contrôle local de tes données et réglages.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct VaultView: View {
    @EnvironmentObject var vault: VaultStore
    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            Group {
                if vault.isUnlocked {
                    List {
                        Section {
                            Button("Ajouter depuis Photos") {
                                pickerItems = []
                            }
                            .photosPicker(isPresented: Binding(
                                get: { false },
                                set: { _ in }
                            ), selection: .constant(nil), matching: .any(of: [.images, .videos]))
                        }

                        ForEach(vault.items) { item in
                            HStack {
                                Image(systemName: item.type == "video" ? "video.fill" : "photo.fill")
                                VStack(alignment: .leading) {
                                    Text(item.filename)
                                    Text(item.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    vault.delete(item)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 18) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.cyan)
                        Text("Coffre verrouillé")
                            .font(.title2.bold())
                        Button("Déverrouiller avec Face ID") {
                            Task { await vault.unlock() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Coffre-fort")
            .toolbar {
                if vault.isUnlocked {
                    Button("Verrouiller") { vault.lock() }
                }
            }
        }
    }
}

struct PhotoPrivacyView: View {
    @StateObject private var photos = PhotoManager()

    var body: some View {
        List {
            Section("Accès") {
                Text(statusText)
                Button("Autoriser / modifier l'accès") {
                    Task { await photos.requestAccess() }
                }
            }

            Section("Analyse rapide") {
                Button("Analyser les dernières 24 h") {
                    Task { await photos.hideRecent(hours: 24) }
                }
                Button("Analyser les dernières 48 h") {
                    Task { await photos.hideRecent(hours: 48) }
                }
                Button("Analyser les 7 derniers jours") {
                    Task { await photos.hideRecent(hours: 168) }
                }
            }

            if !photos.message.isEmpty {
                Section("Résultat") {
                    Text(photos.message)
                }
            }

            Section("Important") {
                Text("iOS limite ce qu'une app tierce peut modifier dans la photothèque. L'app ne peut pas contrôler arbitrairement les données d'autres apps.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Photos & vidéos")
    }

    private var statusText: String {
        switch photos.authorization {
        case .authorized: return "Accès complet"
        case .limited: return "Accès limité"
        case .denied, .restricted: return "Accès refusé"
        default: return "Non déterminé"
        }
    }
}

struct PrivacyView: View {
    @EnvironmentObject var privacy: PrivacyManager

    var body: some View {
        NavigationStack {
            List {
                Section("Protection") {
                    Toggle("Masquer les aperçus", isOn: $privacy.hidePreviews)
                    Stepper("Verrouillage : \(privacy.autoLockMinutes) min",
                            value: $privacy.autoLockMinutes, in: 1...30)
                }

                Section("Réglages système") {
                    Button("Ouvrir les réglages de confidentialité") {
                        privacy.openPrivacySettings()
                    }
                    Button("Ouvrir les réglages du code iPhone") {
                        privacy.openPasscodeSettings()
                    }
                    Button("Ouvrir les réglages de l'app") {
                        privacy.openAppSettings()
                    }
                }

                Section("Applications") {
                    Text("La protection/blocage d'autres apps dépend des API Screen Time d'Apple et des autorisations accordées. Une app classique ne peut pas simplement cacher Snapchat, TikTok ou Instagram.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Privacy")
        }
    }
}

struct PermissionView: View {
    var body: some View {
        List {
            PermissionRow(name: "Photos", icon: "photo.fill")
            PermissionRow(name: "Caméra", icon: "camera.fill")
            PermissionRow(name: "Micro", icon: "mic.fill")
            PermissionRow(name: "Localisation", icon: "location.fill")
            PermissionRow(name: "Contacts", icon: "person.crop.circle")
        }
        .navigationTitle("Privacy Scan")
    }
}

struct PermissionRow: View {
    let name: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon).frame(width: 28)
            Text(name)
            Spacer()
            Text("Voir dans Réglages")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var vault: VaultStore
    @EnvironmentObject var privacy: PrivacyManager

    var body: some View {
        NavigationStack {
            List {
                Section("Sécurité") {
                    Button("Tester Face ID") {
                        Task { await vault.unlock(); vault.lock() }
                    }
                    Button("Verrouiller maintenant") {
                        vault.lock()
                    }
                }

                Section("Panic") {
                    Toggle("Mode Panic actif", isOn: $privacy.isPanicMode)
                    Button("Réinitialiser le mode Panic") {
                        privacy.deactivatePanic()
                    }
                }

                Section("Données") {
                    Button("Vider le coffre", role: .destructive) {
                        vault.clearVault()
                    }
                }

                Section("À propos") {
                    Text("Privacy Center V1")
                    Text("Les protections sont locales et utilisent les mécanismes de sécurité fournis par iOS.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Réglages")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(.cyan)
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.cyan)
                .frame(width: 42)
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
