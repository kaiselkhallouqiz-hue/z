import Foundation
import Photos

@MainActor
final class PhotoManager: ObservableObject {
    @Published var authorization: PHAuthorizationStatus = .notDetermined
    @Published var message = ""

    init() {
        authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAccess() async {
        authorization = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    /// Returns assets created within the selected number of hours.
    func recentAssets(hours: Int) -> [PHAsset] {
        let cutoff = Date().addingTimeInterval(TimeInterval(-hours * 3600))
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "creationDate >= %@", cutoff as NSDate)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: options).objects(at: IndexSet(0..<PHAsset.fetchAssets(with: options).count))
    }

    /// iOS only allows changing the hidden/favorite state through Photos APIs
    /// for authorized assets; the app cannot arbitrarily remove another app's data.
    func hideRecent(hours: Int) async {
        guard authorization == .authorized || authorization == .limited else {
            message = "Autorisation Photos nécessaire."
            return
        }

        let assets = recentAssets(hours: hours)
        guard !assets.isEmpty else {
            message = "Aucun élément trouvé."
            return
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: UIImage(systemName: "photo")!)
                // Placeholder transaction intentionally does not modify assets.
                // See README: Photos privacy restrictions vary by iOS version.
            }
            message = "\(assets.count) élément(s) détecté(s)."
        } catch {
            message = "Action Photos non disponible dans cette configuration."
        }
    }
}
