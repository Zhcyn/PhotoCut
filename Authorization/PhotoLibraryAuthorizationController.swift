import UIKit
import Photos
import SafariServices
class PhotoLibraryAuthorizationController: UIViewController {
    static var needsAuthorization: Bool {
        PHPhotoLibrary.authorizationStatus() != .authorized
    }
    var didAuthorizeHandler: (() -> ())?
    @IBOutlet private var statusView: StatusView!
    @IBOutlet private var privacyButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
    }
    @IBAction private func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization(openingSettingsIfNeeded: true) { status, _ in
            self.updateViews()
            if status == .authorized {
                self.didAuthorizeHandler?()
            }
        }
    }
    @IBAction private func showPrivacyPolicy() {
        guard let url = AboutViewController.privacyPolicyURL else { return }
        present(SFSafariViewController(url: url), animated: true)
    }
    private func updateViews() {
        privacyButton.titleLabel?.adjustsFontForContentSizeCategory = true
        privacyButton.titleLabel?.minimumScaleFactor = 0.8
        statusView.button.titleLabel?.adjustsFontForContentSizeCategory = true
        statusView.button.titleLabel?.minimumScaleFactor = 0.8
        statusView.message = message(for: PHPhotoLibrary.authorizationStatus())
    }
    private func message(for status: PHAuthorizationStatus) -> StatusView.Message? {
        let title = NSLocalizedString("authorization.title", value: "小剪辑👋", comment: "图片库授权名称")
        switch status {
        case .denied, .restricted:
            return .init(title: title,
                         message: NSLocalizedString("authorization.deniedMessage", value: "小剪辑将视频帧导出为图像。你可以在设置中访问你的视频。", comment: "照片库授权被拒绝消息"),
                         action: NSLocalizedString("authorization.deniedAction", value: "打开设置", comment: "照片库授权被拒绝"))
        default:
            return .init(title: title,
                         message: NSLocalizedString("authorization.notDeterminedMessage", value: "小剪辑将视频帧导出为图像。首先允许访问您的视频。", comment: "照片库授权默认消息"),
                         action: NSLocalizedString("authorization.notDeterminedAction", value: "允许访问", comment: "照片库授权默认操作"))
        }
    }
}
