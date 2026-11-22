// swift-tools-version: 5.9
import PackageDescription

// Foundation-only rules can be tested on macOS without an iOS simulator.
let package = Package(
    name: "TicTacToeRules",
    platforms: [.macOS(.v12)],
    targets: [
        .target(
            name: "TicTacToeRules",
            path: "TicTacToe",
            exclude: ["Views", "Assets.xcassets", "Base.lproj", "Info.plist",
                      "AppDelegate.swift", "SceneDelegate.swift", "ViewController.swift"],
            sources: ["Models", "ViewModels"]
        ),
        .testTarget(name: "TicTacToeRulesTests", dependencies: ["TicTacToeRules"], path: "Tests")
    ]
)
