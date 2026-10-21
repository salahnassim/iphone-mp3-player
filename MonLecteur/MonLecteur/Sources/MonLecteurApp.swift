import SwiftUI

@main
struct MonLecteurApp: App {
    @StateObject private var library = LibraryStore()
    @StateObject private var player = PlayerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
                .environmentObject(player)
        }
    }
}
