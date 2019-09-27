import AVKit
import Photos
class VideoManager {
    let asset: PHAsset
    let settings: UserDefaults = .standard
    private let imageManager: PHImageManager
    private(set) var imageRequest: ImageRequest?
    private(set) var videoRequest: ImageRequest?
    init(asset: PHAsset, imageManager: PHImageManager = .default()) {
        self.asset = asset
        self.imageManager = imageManager
    }
    deinit {
        cancelAllRequests()
    }
    func cancelAllRequests() {
        imageRequest = nil
        videoRequest = nil
    }
    func posterImage(with config: ImageConfig, resultHandler: @escaping (UIImage?, PHImageManager.Info) -> ()) {
        imageRequest = imageManager.requestImage(for: asset, config: config, resultHandler: resultHandler)
    }
    func downloadingPlayerItem(withOptions options: PHVideoRequestOptions? = .default(), progressHandler: @escaping (Double) -> (), resultHandler: @escaping (AVPlayerItem?, PHImageManager.Info) -> ()) {
        videoRequest = imageManager.requestAVAsset(for: asset, options: options, progressHandler: progressHandler) { asset, _, info in
            resultHandler(asset.flatMap(AVPlayerItem.init), info)
        }
    }
    func currentFrame(for item: AVPlayerItem) -> UIImage? {
        let generator = AVAssetImageGenerator(asset: item.asset)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.appliesPreferredTrackTransform = true
        let cgImage = try? generator.copyCGImage(at: item.currentTime(), actualTime: nil)
        return cgImage.flatMap(UIImage.init)
    }
    func imageData(byAddingAssetMetadataTo image: UIImage) -> Data? {
        let format = settings.imageFormat
        let quality = settings.compressionQuality
        let properties = settings.includeMetadata
            ? CGImage.properties(for: asset.creationDate, location: asset.location)
            : nil
        return image.cgImage?.data(with: format, properties: properties, compressionQuality: quality)
    }
}
