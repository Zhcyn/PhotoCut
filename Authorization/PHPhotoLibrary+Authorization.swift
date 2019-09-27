import Photos
import UIKit
extension PHPhotoLibrary {
    static func requestAuthorization(openingSettingsIfNeeded openSettings: Bool, completion: @escaping (PHAuthorizationStatus, Bool) -> ()) {
        let status = authorizationStatus()
        let accessDenied = (status == .denied || status == .restricted)
        if accessDenied && openSettings {
            UIApplication.shared.openSettings() { didOpen in
                completion(status, didOpen)
            }
            return
        }
        requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status, false)
            }
        }
    }
}
private extension UIApplication {
    func openSettings(completionHandler: ((Bool) -> ())? = nil) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
            canOpenURL(settingsUrl) else {
                completionHandler?(false)
                return
        }
        open(settingsUrl, options: [:], completionHandler: completionHandler)
    }
}
