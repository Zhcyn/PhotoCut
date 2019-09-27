import Foundation
import AVFoundation
extension UserDefaults {
    private struct Key {
        static let includeMetadata = "IncludeMetadata"
        static let imageFormat = "ImageFormat"
        static let compressionQuality = "CompressionQuality"
    }
    static var isHeifSupported: Bool {
        AVAssetExportSession.allExportPresets().contains(AVAssetExportPresetHEVCHighestQuality)
    }
    var includeMetadata: Bool {
        get { (object(forKey: Key.includeMetadata) as? Bool) ?? true }
        set { set(newValue, forKey: Key.includeMetadata) }
    }
    var imageFormat: ImageFormat {
        get { (codableValue(forKey: Key.imageFormat) ?? ImageFormat.heif).safeFormat }
        set { setCodableValue(value: newValue.safeFormat, forKey: Key.imageFormat) }
    }
    var compressionQuality: Double {
        get { (object(forKey: Key.compressionQuality) as? Double) ?? 0.95 }
        set { set(newValue, forKey: Key.compressionQuality) }
    }
}
private extension ImageFormat {
    var safeFormat: ImageFormat {
        if !UserDefaults.isHeifSupported && (self == .heif) {
            return .jpg
        }
        return self
    }
}
extension UserDefaults {
    func codableValue<T: Codable>(forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    func setCodableValue<T: Codable>(value: T?, forKey key: String) {
        let data = try? value.flatMap(JSONEncoder().encode)
        set(data, forKey: key)
    }
}
