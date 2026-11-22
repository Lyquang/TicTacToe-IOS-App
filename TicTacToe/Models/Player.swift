import Foundation

/// UI-independent player identity used by the game rules and sparse board.
enum Player: String, CaseIterable {
    case cross
    case nought

    var symbol: String { self == .cross ? "X" : "O" }
    var opponent: Player { self == .cross ? .nought : .cross }
}
