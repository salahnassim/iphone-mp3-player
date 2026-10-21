import SwiftUI

struct ContentView: View {
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject var player: PlayerManager
    @State private var pickingFolder = false

    var body: some View {
        NavigationStack {
            Group {
                if library.tracks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.plus").font(.system(size: 48))
                        Text("Choisis ton dossier de musique")
                        Button("Choisir un dossier") { pickingFolder = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(Array(library.tracks.enumerated()), id: \.element.id) { i, t in
                        Button { player.play(library.tracks, startAt: i) } label: {
                            HStack {
                                Text(t.title).lineLimit(1)
                                Spacer()
                                if player.currentTrack == t { Image(systemName: "speaker.wave.2.fill") }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(library.folderName ?? "Mon Lecteur")
            .toolbar {
                Button { pickingFolder = true } label: { Image(systemName: "folder") }
                Button { library.scan() } label: { Image(systemName: "arrow.clockwise") }
            }
            .safeAreaInset(edge: .bottom) { if player.currentTrack != nil { MiniPlayer() } }
            .fileImporter(isPresented: $pickingFolder, allowedContentTypes: [.folder]) { r in
                if case .success(let url) = r { library.setFolder(url) }
            }
        }
    }
}

struct MiniPlayer: View {
    @EnvironmentObject var player: PlayerManager

    var body: some View {
        VStack(spacing: 6) {
            Text(player.currentTrack?.title ?? "").font(.subheadline.bold()).lineLimit(1)
            Slider(value: Binding(get: { player.position }, set: { player.seek($0) }),
                   in: 0...max(player.duration, 1))
            HStack(spacing: 36) {
                Button { player.previous() } label: { Image(systemName: "backward.fill") }
                Button { player.toggle() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill").font(.title)
                }
                Button { player.next() } label: { Image(systemName: "forward.fill") }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
