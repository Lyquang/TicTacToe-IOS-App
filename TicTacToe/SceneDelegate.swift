//
//  SceneDelegate.swift
//  TicTacToe
//

import UIKit

// AppDelegate quản lý sự kiện cấp ứng dụng; SceneDelegate quản lý phiên giao diện.
// UIWindowSceneDelegate là protocol để UIKit thông báo các thay đổi của scene.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // `var` cho phép gán lại; `let` thì không. UIWindow? ban đầu là nil.
    // UIWindow là cửa sổ chứa cây giao diện. Thuộc tính này giữ tham chiếu mạnh
    // tới cửa sổ được tạo trong scene(_:willConnectTo:options:).
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        // `as?` thử chuyển UIScene thành UIWindowScene; không đúng kiểu thì trả nil.
        // `guard let` mở Optional: nếu có giá trị, đặt tên windowScene để dùng tiếp;
        // nếu không có thì nhánh else phải thoát (ở đây bằng return).
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Programmatic root — no Storyboard dependency.
        // Tạo cửa sổ thuộc scene vừa nhận. `let window` là biến cục bộ của hàm.
        // Các lời gọi sau tạo màn hình chính, gắn vào cửa sổ và đưa cửa sổ lên hiển thị.
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = GameViewController()
        window.makeKeyAndVisible()
        // `self` là đối tượng SceneDelegate hiện tại. Phân biệt self.window
        // (thuộc tính của đối tượng) với window (biến cục bộ vừa tạo).
        self.window = window
    }

    // Các callback vòng đời hiện chưa có xử lý bổ sung:
    // disconnect: scene mất kết nối; becomeActive: bắt đầu nhận tương tác;
    // resignActive: sắp ngừng tương tác; foreground: sắp quay lại phía trước;
    // background: vào nền. Không phải cứ vào nền là app bị kết thúc ngay.
    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
