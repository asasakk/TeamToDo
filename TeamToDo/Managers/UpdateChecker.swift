import Foundation
import Combine

class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()
    
    @Published var isUpdateAvailable: Bool = false
    @Published var latestVersion: String = ""
    @Published var appStoreURL: URL?
    
    private init() {}
    
    func checkForUpdate() {
        // App Store search API using bundle identifier or App ID
        // Assuming bundle identifier "com.teamtodo.app" or similar, but code shows ID 6755773828
        // Let's use the ID for lookup as it's more reliable if provided.
        let appID = "6755773828"
        let urlString = "https://itunes.apple.com/lookup?id=\(appID)"
        
        guard let url = URL(string: urlString) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let firstResult = results.first,
                   let version = firstResult["version"] as? String,
                   let trackViewUrl = firstResult["trackViewUrl"] as? String {
                    
                    DispatchQueue.main.async {
                        self.latestVersion = version
                        self.appStoreURL = URL(string: trackViewUrl)
                        self.isUpdateAvailable = self.isNewerVersion(version)
                    }
                }
            } catch {
                print("Update check failed: \(error)")
            }
        }
    }
    
    private func isNewerVersion(_ latest: String) -> Bool {
        guard let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return false
        }
        return latest.compare(current, options: .numeric) == .orderedDescending
    }
}
