import AVKit
protocol PlaybackControllerDelegate: PlayerObserverDelegate {}
class PlaybackController {
    weak var delegate: PlaybackControllerDelegate? {
        didSet { observer.delegate = delegate }
    }
    let player: AVPlayer
    let seeker: PlayerSeeker
    private let observer: PlayerObserver
    init(playerItem: AVPlayerItem, player: AVPlayer = .init()) {
        self.player = player
        self.player.replaceCurrentItem(with: playerItem)
        self.player.actionAtItemEnd = .pause
        self.seeker = PlayerSeeker(player: player)
        self.observer = PlayerObserver(player: player)
    }
    var isReadyToPlay: Bool {
        (player.status == .readyToPlay) && (currentItem?.status == .readyToPlay)
    }
    var isPlaying: Bool {
        player.rate != 0
    }
    var isSeeking: Bool {
        seeker.isSeeking
    }
    var currentTime: CMTime {
        player.currentTime()
    }
    var currentItem: AVPlayerItem? {
        player.currentItem
    }
    var frameRate: Float? {
        currentItem?.asset.tracks(withMediaType: .video).first?.nominalFrameRate
    }
    func playOrPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    func play() {
        guard !isPlaying else { return }
        seekToStartIfNecessary()
        player.play()
    }
    func pause() {
        guard isPlaying else { return }
        player.pause()
    }
    func step(byCount count: Int) {
        pause()
        currentItem?.step(byCount: count)
    }
    private func seekToStartIfNecessary() {
        guard let item = currentItem,
           CMTimeCompare(item.currentTime(), item.duration) >= 0 else { return }
       seeker.cancelPendingSeeks()
       currentItem?.seek(to: .zero, completionHandler: nil)
    }
}
