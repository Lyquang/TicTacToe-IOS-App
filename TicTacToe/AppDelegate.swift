//
//  AppDelegate.swift
//  TicTacToe
//
//  Created by CallumHill on 30/7/21.
//

// CÁCH ĐỌC DỰ ÁN CHO NGƯỜI MỚI:
// AppDelegate → SceneDelegate → GameViewController → GameViewModel → InfiniteBoardView.
// Sau đó đọc Models/MatchRecord và HistoryViewController để hiểu lưu lịch sử.
// ViewController.swift là màn hình 3×3 cũ, không phải màn hình được mở hiện tại.
// Swift là ngôn ngữ; UIKit là framework cung cấp cửa sổ, màn hình, nút, chữ...
// Cú pháp thường gặp trong các file:
// - let: không gán lại; var: có thể gán lại; dấu : ghi kiểu, dấu = gán giá trị.
// - Int: số nguyên; Double/CGFloat: số thực; Bool: true/false; String: chuỗi chữ.
// - ==: so sánh bằng; !=: khác; !điều_kiện: phủ định; &&: và; ||: hoặc.
// - if/else: chọn nhánh; for/while: lặp; return: kết thúc hàm (có thể trả giá trị).
// - { } bao thân hàm/nhánh/closure; // là ghi chú; /// là ghi chú tài liệu.
// - MARK là chú thích giúp Xcode chia mục, không chạy như một lệnh.
// Swift tự có String/Int/Array trong thư viện chuẩn. Foundation bổ sung các kiểu
// như Date, UUID, UserDefaults và JSONEncoder mà tầng dữ liệu dùng bên dưới.
// `import` đưa các kiểu dữ liệu của framework vào phạm vi sử dụng của file.
import UIKit

// @main đánh dấu điểm khởi đầu của ứng dụng. UIKit điều phối vòng lặp sự kiện:
// chờ chạm, cập nhật màn hình, nhận thông báo vòng đời... thay vì ta tự viết vòng while.
// `class` tạo kiểu tham chiếu: hai biến có thể cùng trỏ tới một đối tượng.
// Sau dấu `:`: UIResponder là lớp cha; UIApplicationDelegate là protocol.
// Protocol là hợp đồng về các thuộc tính/hàm mà một kiểu cung cấp cho bên gọi.
@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    // `func` khai báo hàm. `-> Bool` nghĩa là trả về true hoặc false.
    // `_ application` bỏ nhãn đối số đầu ở nơi gọi; tên bên trong hàm vẫn là application.
    // `[Key: Any]?` là dictionary tùy chọn: có thể chứa dữ liệu khởi chạy hoặc nil.
    // `Any` có thể chứa giá trị thuộc nhiều kiểu; `?` diễn tả khả năng không có giá trị.
    // UIKit tự gọi hàm này khi ứng dụng khởi động; true báo khởi tạo thành công.
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		return true
	}

	// MARK: UISceneSession Lifecycle

    // Scene là một phiên giao diện của app. AppDelegate chọn cấu hình cho scene mới.
    // Tên "Default Configuration" khớp cấu hình scene trong Info.plist.
    // `UISceneConfiguration(...)` tạo một instance, giống các lời gọi init khác.
	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

    // Set<T> là tập hợp các phần tử không trùng nhau, không có thứ tự cố định.
    // Khi một phiên scene bị loại bỏ, có thể dọn tài nguyên riêng của phiên ở đây.
    // Thân hàm hiện rỗng vì app chưa có tài nguyên riêng cần dọn ở bước này.
	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}


}

