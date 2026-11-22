// swift-tools-version: 5.9
// Đây là manifest của Swift Package Manager, không phải màn hình iOS.
// Dòng swift-tools-version ở đầu file chọn phiên bản tối thiểu để đọc manifest.
// PackageDescription cung cấp các kiểu Package/Target để mô tả phần cần build/test.
import PackageDescription

// Foundation-only rules can be tested on macOS without an iOS simulator.
// Package riêng chỉ build Model và ViewModel để chạy test trên macOS.
// .macOS(.v12) là yêu cầu nền tảng của package, không thay iOS deployment target
// trong Xcode project. App UIKit vẫn được build bằng TicTacToe.xcodeproj.
let package = Package(
    name: "TicTacToeRules",
    platforms: [.macOS(.v12)],
    targets: [
        // Một target là một đơn vị mã được biên dịch thành module.
        // path là thư mục gốc; exclude bỏ UI/tài nguyên; sources chọn phần logic.
        .target(
            name: "TicTacToeRules",
            path: "TicTacToe",
            exclude: ["Views", "Assets.xcassets", "Base.lproj", "Info.plist",
                      "AppDelegate.swift", "SceneDelegate.swift", "ViewController.swift"],
            sources: ["Models", "ViewModels"]
        ),
        // Test target phụ thuộc module logic và đọc mã kiểm thử trong Tests/.
        .testTarget(name: "TicTacToeRulesTests", dependencies: ["TicTacToeRules"], path: "Tests")
    ]
)
