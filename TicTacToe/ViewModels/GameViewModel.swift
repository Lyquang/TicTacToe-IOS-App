import Foundation

/// Owns the rules and local match summaries; views observe changes through callbacks.
final class GameViewModel {
    static let winLength = 5
    private static let historyKey = "match_history_v1"
    private let defaults: UserDefaults

    private(set) var board: [Coordinate: Player] = [:]
    private(set) var currentPlayer: Player = .cross
    private(set) var totalMoves = 0
    private(set) var crossScore = 0
    private(set) var noughtScore = 0
    private(set) var gameResult: MatchResult?

    var onMovePlaced: ((_ coordinate: Coordinate, _ winLine: [Coordinate]?) -> Void)?
    var onGameEnded: ((_ result: MatchResult) -> Void)?
    var onScoreUpdated: (() -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    @discardableResult
    func place(at coordinate: Coordinate) -> Bool {
        guard gameResult == nil, board[coordinate] == nil else { return false }
        let player = currentPlayer
        board[coordinate] = player
        totalMoves += 1

        if let line = checkWin(at: coordinate, for: player) {
            let result: MatchResult = player == .cross ? .crossWin : .noughtWin
            // Finish before invoking observers so callbacks cannot place another move.
            gameResult = result
            if player == .cross { crossScore += 1 } else { noughtScore += 1 }
            saveMatch(result: result)
            onMovePlaced?(coordinate, line)
            onScoreUpdated?()
            onGameEnded?(result)
        } else {
            currentPlayer = player.opponent
            onMovePlaced?(coordinate, nil)
        }
        return true
    }

    /// Starts a new round while preserving session scores and completed history.
    func resetGame() {
        board.removeAll()
        totalMoves = 0
        currentPlayer = .cross
        gameResult = nil
    }

    /// Checks only lines crossing the latest move, in both directions of each axis.
    /// Five or more consecutive pieces win; blocked ends do not change this rule.
    func checkWin(at coordinate: Coordinate, for player: Player) -> [Coordinate]? {
        guard board[coordinate] == player else { return nil }
        let axes = [(0, 1), (1, 0), (1, 1), (1, -1)]
        for (dr, dc) in axes {
            var forward: [Coordinate] = []
            var backward: [Coordinate] = []
            var next = coordinate.neighbour(dr: dr, dc: dc)
            while board[next] == player {
                forward.append(next)
                next = next.neighbour(dr: dr, dc: dc)
            }
            next = coordinate.neighbour(dr: -dr, dc: -dc)
            while board[next] == player {
                backward.append(next)
                next = next.neighbour(dr: -dr, dc: -dc)
            }
            let line = Array(backward.reversed()) + [coordinate] + forward
            if line.count >= Self.winLength { return line }
        }
        return nil
    }

    private func saveMatch(result: MatchResult) {
        var history = loadHistory()
        history.insert(MatchRecord(result: result, totalMoves: totalMoves), at: 0)
        if let data = try? JSONEncoder().encode(Array(history.prefix(100))) {
            defaults.set(data, forKey: Self.historyKey)
        }
    }

    func loadHistory() -> [MatchRecord] {
        guard let data = defaults.data(forKey: Self.historyKey),
              let records = try? JSONDecoder().decode([MatchRecord].self, from: data)
        else { return [] }
        return records
    }

    func clearHistory() {
        defaults.removeObject(forKey: Self.historyKey)
    }
}
