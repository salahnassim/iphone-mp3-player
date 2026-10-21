import Foundation

struct Track: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    var title: String { url.deletingPathExtension().lastPathComponent }
}

/// Garde un signet vers TON dossier de musique (dans Fichiers).
/// Les fichiers ne sont jamais copiés dans l'app : si l'app est supprimée, la musique reste.
@MainActor
final class LibraryStore: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var folderName: String?

    private var folderURL: URL?
    private let key = "musicFolderBookmark"
    private let exts: Set<String> = ["mp3", "m4a", "aac", "wav", "flac", "alac", "aiff"]

    init() { restore() }

    func setFolder(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        folderURL?.stopAccessingSecurityScopedResource()
        folderURL = url
        if let data = try? url.bookmarkData() {
            UserDefaults.standard.set(data, forKey: key)
        }
        scan()
    }

    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale),
              url.startAccessingSecurityScopedResource() else { return }
        if stale, let fresh = try? url.bookmarkData() {
            UserDefaults.standard.set(fresh, forKey: key)
        }
        folderURL = url
        scan()
    }

    func scan() {
        guard let folder = folderURL else { return }
        folderName = folder.lastPathComponent
        var found: [Track] = []
        if let en = FileManager.default.enumerator(at: folder,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]) {
            for case let url as URL in en where exts.contains(url.pathExtension.lowercased()) {
                found.append(Track(url: url))
            }
        }
        tracks = found.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}
