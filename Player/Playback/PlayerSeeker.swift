import AVKit
struct SeekInfo {
    let time: CMTime
    let toleranceBefore: CMTime
    let toleranceAfter: CMTime
}
class PlayerSeeker {
    private let player: AVPlayer
    var isSeeking: Bool {
        currentSeek != nil
    }
    var finalSeekTime: CMTime? {
        (nextSeek ?? currentSeek)?.time
    }
    private(set) var currentSeek: SeekInfo?
    private(set) var nextSeek: SeekInfo?
    init(player: AVPlayer) {
        self.player = player
    }
    func cancelPendingSeeks() {
        player.currentItem?.cancelPendingSeeks()
    }
    func smoothlySeek(to time: CMTime, toleranceBefore: CMTime = .zero, toleranceAfter: CMTime = .zero) {
        let info = SeekInfo(time: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
        smoothlySeek(with: info)
    }
    func smoothlySeek(with info: SeekInfo) {
        guard info.time != player.currentTime() else { return }
        nextSeek = info
        if !isSeeking {
            if player.rate > 0 {
                player.pause()
            }
            startNextSeek()
        }
    }
    private func startNextSeek() {
        guard let next = nextSeek else { fatalError("No next seek to start") }
        currentSeek = next
        nextSeek = nil
        player.seek(with: currentSeek!) { [weak self] finished in
            self?.didFinishCurrentSeek(wasCancelled: !finished)
        }
    }
    private func didFinishCurrentSeek(wasCancelled: Bool) {
        currentSeek = nil
        let continueSeeking = !wasCancelled && (nextSeek != nil)
        if continueSeeking {
            startNextSeek()
        } else {
            didFinishAllSeeks()
        }
    }
    private func didFinishAllSeeks() {
        currentSeek = nil
        nextSeek = nil
    }
}
extension AVPlayer {
    func seek(with info: SeekInfo, completionHandler: @escaping (Bool) -> ()) {
        seek(to: info.time,
             toleranceBefore: info.toleranceBefore,
             toleranceAfter: info.toleranceAfter,
             completionHandler: completionHandler)
    }
}
