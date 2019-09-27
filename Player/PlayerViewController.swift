import UIKit
import AVKit
class PlayerViewController: UIViewController {
    var videoManager: VideoManager!
    var settings = UserDefaults.standard
    private var playbackController: PlaybackController?
    private lazy var timeFormatter = VideoTimeFormatter()
    @IBOutlet private var backgroundView: BlurredImageView!
    @IBOutlet private var playerView: ZoomingPlayerView!
    @IBOutlet private var loadingView: PlayerLoadingView!
    @IBOutlet private var titleView: PlayerTitleView!
    @IBOutlet private var controlsView: PlayerControlsView!
    private var isInitiallyReadyForPlayback = false
    private var isScrubbing: Bool {
        controlsView.timeSlider.isInteracting
    }
    private var isSeeking: Bool {
        playbackController?.isSeeking ?? false
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    override var prefersStatusBarHidden: Bool {
        let verticallyCompact = traitCollection.verticalSizeClass == .compact
        return verticallyCompact || shouldHideStatusBar
    }
    private var shouldHideStatusBar = false {
        didSet { setNeedsStatusBarAppearanceUpdate() }
    }
    private func hideStatusBar() {
        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.shouldHideStatusBar = true
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.15) {
                self.shouldHideStatusBar = true
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        loadPreviewImage()
        loadVideo()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideStatusBar()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
private extension PlayerViewController {
    @IBAction func done() {
        videoManager.cancelAllRequests()
        playbackController?.pause()
        navigationController?.popViewController(animated: true)
    }
    @IBAction func playOrPause() {
        guard !isScrubbing else { return }
        playbackController?.playOrPause()
    }
    func stepBackward() {
        guard !isScrubbing else { return }
        playbackController?.step(byCount: -1)
    }
    func stepForward() {
        guard !isScrubbing else { return }
        playbackController?.step(byCount: 1)
    }
    @IBAction func shareCurrentFrame() {
        guard !isScrubbing, let item = playbackController?.currentItem else { return }
        playbackController?.pause()
        generateCurrentFrameAndShare(for: item)
    }
    @IBAction func scrub(_ sender: TimeSlider) {
        playbackController?.seeker.smoothlySeek(to: sender.time)
        updateSlider(withTime: sender.time)
        updateTimeLabel(withTime: sender.time)
    }
}
extension PlayerViewController: PlaybackControllerDelegate {
    func player(_ player: AVPlayer, didUpdateStatus status: AVPlayer.Status) {
        guard status != .failed  else {
            presentAlert(.playbackFailed { _ in self.done() })
            return
        }
        updatePlaybackStatus()
    }
    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateStatus status: AVPlayerItem.Status) {
        guard status != .failed else {
            presentAlert(.playbackFailed { _ in self.done() })
            return
        }
        updatePlaybackStatus()
    }
    func player(_ player: AVPlayer, didPeriodicUpdateAtTime time: CMTime) {
        updateSlider(withTime: time)
        updateTimeLabel(withTime: time)
    }
    func player(_ player: AVPlayer, didUpdateTimeControlStatus status: AVPlayer.TimeControlStatus) {
        updatePlayButton(withStatus: status)
    }
    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateDuration duration: CMTime) {
        updateSlider(withDuration: duration)
    }
    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateTracks tracks: [AVPlayerItemTrack]) {
        updateDetailLabels()
    }
}
extension PlayerViewController: ZoomingPlayerViewDelegate {
    func playerView(_ playerView: ZoomingPlayerView, didUpdateReadyForDisplay ready: Bool) {
        updatePlaybackStatus()
    }
}
private extension PlayerViewController {
    func configureViews() {
        playerView.delegate = self
        controlsView.previousButton.repeatAction = { [weak self] in
            self?.stepBackward()
        }
        controlsView.nextButton.repeatAction = { [weak self] in
            self?.stepForward()
        }
        configureGestures()
        updatePlaybackStatus()
        updatePlayButton(withStatus: .paused)
        updateSlider(withDuration: .zero)
        updateSlider(withTime: .zero)
        updateTimeLabel(withTime: .zero)
        updateDetailLabels()
        updateLoadingProgress(with: nil)
        updatePreviewImage()
    }
    func configureGestures() {
        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeRecognizer.direction = .down
        playerView.addGestureRecognizer(swipeRecognizer)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapRecognizer.require(toFail: playerView.doubleTapToZoomRecognizer)
        tapRecognizer.require(toFail: swipeRecognizer)
        playerView.addGestureRecognizer(tapRecognizer)
    }
    @objc func handleTap(sender: UIGestureRecognizer) {
        guard sender.state == .ended else { return }
        titleView.toggleHidden(animated: true)
        controlsView.toggleHidden(animated: true)
    }
    @objc func handleSwipeDown(sender: UIGestureRecognizer) {
        guard sender.state == .ended else { return }
        done()
    }
    func updatePlaybackStatus() {
        let isReadyToPlay = playbackController?.isReadyToPlay ?? false
        let isReadyToDisplay = playerView.isReadyForDisplay
        if isReadyToPlay && isReadyToDisplay {
            isInitiallyReadyForPlayback = true
            updatePreviewImage()
        }
        controlsView.setControlsEnabled(isReadyToPlay)
    }
    func updatePreviewImage() {
        loadingView.imageView.isHidden = isInitiallyReadyForPlayback
    }
    func updateLoadingProgress(with progress: Float?) {
        loadingView.setProgress(progress, animated: true)
    }
    func updatePlayButton(withStatus status: AVPlayer.TimeControlStatus) {
        controlsView.playButton.setTimeControlStatus(status)
    }
    func updateDetailLabels() {
        let asset = videoManager.asset
        let fps = playbackController?.frameRate
        let dimensions = NumberFormatter().string(fromPixelWidth: asset.pixelWidth, height: asset.pixelHeight)
        let frameRate = fps.flatMap { NumberFormatter.frameRateFormatter().string(fromFrameRate: $0) }
        titleView.setDetailLabels(for: dimensions, frameRate: frameRate)
    }
    func updateTimeLabel(withTime time: CMTime) {
        let showMilliseconds = playbackController?.isPlaying == false
        let formattedTime = timeFormatter.string(fromCurrentTime: time, includeMilliseconds: showMilliseconds)
        controlsView.timeLabel.text = formattedTime
    }
    func updateSlider(withTime time: CMTime) {
        guard !isScrubbing && !isSeeking else { return }
        controlsView.timeSlider.time = time
    }
    func updateSlider(withDuration duration: CMTime) {
        controlsView.timeSlider.duration = duration
    }
    func loadPreviewImage() {
        let size = loadingView.imageView.bounds.size.scaledToScreen
        let config = ImageConfig(size: size, mode: .aspectFit, options: .default())
        videoManager.posterImage(with: config) { [weak self] image, _ in
            guard let image = image else { return }
            self?.loadingView.imageView.image = image
            self?.backgroundView.imageView.image = image
            self?.updatePreviewImage()
        }
    }
    func loadVideo() {
        videoManager.downloadingPlayerItem(progressHandler: { [weak self] progress in
            self?.updateLoadingProgress(with: Float(progress))
        }, resultHandler: { [weak self] playerItem, info in
            self?.updateLoadingProgress(with: nil)
            guard !info.isCancelled else { return }
            if let playerItem = playerItem {
                self?.configurePlayer(with: playerItem)
            } else {
                self?.presentAlert(.videoLoadingFailed { _ in self?.done() })
            }
        })
    }
    func configurePlayer(with playerItem: AVPlayerItem) {
        playbackController = PlaybackController(playerItem: playerItem)
        playbackController?.delegate = self
        playerView.player = playbackController?.player
        playbackController?.play()
    }
    func generateCurrentFrameAndShare(for item: AVPlayerItem) {
        guard let image = videoManager.currentFrame(for: item) else {
            presentAlert(.imageGenerationFailed())
            return
        }
        shareImage(image)
    }
    func shareImage(_ image: UIImage) {
        let item: Any = videoManager.imageData(byAddingAssetMetadataTo: image) ?? image
        let shareController = UIActivityViewController(activityItems: [item], applicationActivities: nil)
        present(shareController, animated: true)
    }
}
extension PlayerViewController: ZoomAnimatable {
    func zoomAnimatorAnimationWillBegin(_ animator: ZoomAnimator) {
        playerView.isHidden = true
        loadingView.isHidden = true
        controlsView.isHidden = true  
        titleView.isHidden = true
    }
    func zoomAnimatorAnimationDidEnd(_ animator: ZoomAnimator) {
        playerView.isHidden = false
        loadingView.isHidden = false
        controlsView.setHidden(false, animated: true, duration: 0.2)
        titleView.setHidden(false, animated: true, duration: 0.2)
        updatePreviewImage()
    }
    func zoomAnimatorImage(_ animator: ZoomAnimator) -> UIImage? {
        loadingView.imageView.image
    }
    func zoomAnimator(_ animator: ZoomAnimator, imageFrameInView view: UIView) -> CGRect? {
        let videoFrame = playerView.zoomedVideoFrame
        if videoFrame != .zero {
            return playerView.superview?.convert(videoFrame, to: view)
        } else {
            return loadingView.convert(loadingImageFrame, to: view)
        }
    }
    private var loadingImageFrame: CGRect {
        let imageSize = loadingView.imageView.image?.size
            ?? CGSize(width: videoManager.asset.pixelWidth, height: videoManager.asset.pixelHeight)
        return AVMakeRect(aspectRatio: imageSize, insideRect: loadingView.imageView.frame)
    }
}
