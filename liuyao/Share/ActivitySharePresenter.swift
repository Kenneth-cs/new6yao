import UIKit

@MainActor
enum ActivitySharePresenter {
    /// 从当前最上层控制器弹出系统分享。fullScreenCover 下 rootViewController 往往不是可见页。
    static func present(fileURL: URL) {
        guard let presenter = topViewController(), presenter.view.window != nil else {
            try? FileManager.default.removeItem(at: fileURL)
            return
        }
        let controller = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: fileURL)
        }
        if let popover = controller.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 1,
                height: 1
            )
            popover.permittedArrowDirections = []
        }
        presenter.present(controller, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        let window = scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}
