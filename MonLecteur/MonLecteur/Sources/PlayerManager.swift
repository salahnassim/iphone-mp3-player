import AVFoundation
import MediaPlayer

@MainActor
final class PlayerManager: ObservableObject {
    @Published var queue: [Track] = []
    @Published var index: Int?
    @Published var isPlaying = false
    @Published var position: Double = 0
    @Published var duration: Double = 0

    private let player = AVPlayer()

    var currentTrack: Track? {
        guard let i = index, queue.indices.contains(i) else { return nil }
        return queue[i]
    }

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
                                       queue: .main) { [weak self] t in
            Task { @MainActor in
                guard let self else { return }
                self.position = t.seconds
                if let d = self.player.currentItem?.duration.seconds, d.isFinite { self.duration = d }
                self.updateNowPlaying()
            }
        }
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.next() }
        }
        setupRemote()
    }

    func play(_ tracks: [Track], startAt i: Int) {
        queue = tracks
        load(i)
    }

    private func load(_ i: Int) {
        guard queue.indices.contains(i) else { return }
        index = i
        player.replaceCurrentItem(with: AVPlayerItem(url: queue[i].url))
        position = 0
        resume()
    }

    func resume() { player.play(); isPlaying = true; updateNowPlaying() }
    func pause() { player.pause(); isPlaying = false; updateNowPlaying() }
    func toggle() { isPlaying ? pause() : resume() }

    func next() {
        guard let i = index else { return }
        if i + 1 < queue.count { load(i + 1) } else { pause() }
    }

    func previous() {
        guard let i = index else { return }
        if position > 3 { seek(0) } else if i > 0 { load(i - 1) }
    }

    func seek(_ s: Double) {
        player.seek(to: CMTime(seconds: s, preferredTimescale: 600))
        position = s
    }

    private func setupRemote() {
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget { [weak self] _ in Task { @MainActor in self?.resume() }; return .success }
        c.pauseCommand.addTarget { [weak self] _ in Task { @MainActor in self?.pause() }; return .success }
        c.nextTrackCommand.addTarget { [weak self] _ in Task { @MainActor in self?.next() }; return .success }
        c.previousTrackCommand.addTarget { [weak self] _ in Task { @MainActor in self?.previous() }; return .success }
        c.changePlaybackPositionCommand.addTarget { [weak self] e in
            if let e = e as? MPChangePlaybackPositionCommandEvent {
                Task { @MainActor in self?.seek(e.positionTime) }
            }
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let t = currentTrack else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: t.title,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: position,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
    }
}
