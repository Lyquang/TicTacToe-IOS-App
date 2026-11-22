import XCTest
@testable import TicTacToeRules

final class GameViewModelTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!

    override func setUp() {
        super.setUp()
        suite = "TicTacToeTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    private func coordinate(_ row: Int, _ col: Int) -> Coordinate {
        Coordinate(row: row, col: col)
    }

    private func win(_ game: GameViewModel, dr: Int = 0, dc: Int = 1, nought: Bool = false) {
        if nought { XCTAssertTrue(game.place(at: coordinate(100, 100))) }
        for i in 0..<5 {
            XCTAssertTrue(game.place(at: coordinate(i * dr, i * dc)))
            if i < 4 { XCTAssertTrue(game.place(at: coordinate(50 + i * 2, 30))) }
        }
    }

    func testWinsOnAllFourAxesForEitherPlayer() {
        for (dr, dc) in [(0, 1), (1, 0), (1, 1), (1, -1)] {
            for nought in [false, true] {
                let game = GameViewModel(defaults: defaults)
                defaults.removePersistentDomain(forName: suite)
                win(game, dr: dr, dc: dc, nought: nought)
                XCTAssertEqual(game.gameResult, nought ? .noughtWin : .crossWin)
                XCTAssertEqual(game.loadHistory().count, 1)
                XCTAssertEqual(game.loadHistory().first?.totalMoves, nought ? 10 : 9)
                XCTAssertEqual(game.crossScore, nought ? 0 : 1)
                XCTAssertEqual(game.noughtScore, nought ? 1 : 0)
            }
        }
    }

    func testRejectsOccupiedCellAndMovesAfterWin() {
        let game = GameViewModel(defaults: defaults)
        XCTAssertTrue(game.place(at: coordinate(0, 0)))
        XCTAssertFalse(game.place(at: coordinate(0, 0)))
        XCTAssertEqual(game.totalMoves, 1)
        XCTAssertEqual(game.currentPlayer, .nought)
        game.resetGame()
        win(game)
        XCTAssertFalse(game.place(at: coordinate(10, 10)))
        XCTAssertEqual(game.totalMoves, 9)
        XCTAssertEqual(game.loadHistory().count, 1)
    }

    func testBridgingMoveFindsBothSidesAndOverlineInOrder() {
        let game = GameViewModel(defaults: defaults)
        var winningLine: [Coordinate] = []
        game.onMovePlaced = { _, line in if let line = line { winningLine = line } }
        for (index, col) in [0, 1, 3, 4, 5, 2].enumerated() {
            XCTAssertTrue(game.place(at: coordinate(-10, col)))
            if index < 5 { XCTAssertTrue(game.place(at: coordinate(40 + index * 2, 40))) }
        }
        XCTAssertEqual(game.gameResult, .crossWin)
        XCTAssertEqual(winningLine, (0...5).map { coordinate(-10, $0) })
    }

    func testGapsAndOpponentPiecesDoNotWin() {
        let game = GameViewModel(defaults: defaults)
        for col in [0, 1, 3, 4] {
            XCTAssertTrue(game.place(at: coordinate(0, col)))
            XCTAssertTrue(game.place(at: coordinate(20 + col * 2, 0)))
        }
        XCTAssertNil(game.gameResult)
        XCTAssertNil(game.checkWin(at: coordinate(0, 2), for: .cross))
        XCTAssertTrue(game.place(at: coordinate(5, 5)))
        XCTAssertTrue(game.place(at: coordinate(0, 2)))
        XCTAssertNil(game.checkWin(at: coordinate(0, 0), for: .cross))
        XCTAssertTrue(game.loadHistory().isEmpty)
    }

    func testCallbacksObserveUpdatedTurnAndCannotAddMoveAfterWinning() {
        let game = GameViewModel(defaults: defaults)
        game.onMovePlaced = { _, line in
            if line != nil {
                XCTAssertEqual(game.gameResult, .crossWin)
                XCTAssertFalse(game.place(at: self.coordinate(99, 99)))
            } else {
                XCTAssertEqual(game.currentPlayer, game.totalMoves % 2 == 0 ? .cross : .nought)
            }
        }
        win(game)
    }

    func testHistorySurvivesNewViewModelAndResetKeepsScore() {
        let game = GameViewModel(defaults: defaults)
        win(game)
        let record = game.loadHistory()[0]
        game.resetGame()
        XCTAssertTrue(game.board.isEmpty)
        XCTAssertNil(game.gameResult)
        XCTAssertEqual(game.totalMoves, 0)
        XCTAssertEqual(game.currentPlayer, .cross)
        XCTAssertEqual(game.crossScore, 1)
        let reloaded = GameViewModel(defaults: defaults)
        XCTAssertEqual(reloaded.loadHistory()[0].id, record.id)
        XCTAssertEqual(reloaded.loadHistory()[0].date, record.date)
        XCTAssertEqual(reloaded.loadHistory()[0].result, .crossWin)
        reloaded.clearHistory()
        XCTAssertTrue(game.loadHistory().isEmpty)
    }

    func testHistoryIsNewestFirstAndLimitedTo100() {
        let game = GameViewModel(defaults: defaults)
        for _ in 0..<101 {
            win(game)
            game.resetGame()
        }
        let records = GameViewModel(defaults: defaults).loadHistory()
        XCTAssertEqual(records.count, 100)
        XCTAssertEqual(Set(records.map(\.id)).count, 100)
        XCTAssertEqual(records.map(\.date), records.map(\.date).sorted(by: >))
    }

    func testCorruptHistoryDoesNotCrashOrBlockNextSave() {
        defaults.set(Data("invalid json".utf8), forKey: "match_history_v1")
        let game = GameViewModel(defaults: defaults)
        XCTAssertTrue(game.loadHistory().isEmpty)
        win(game)
        XCTAssertEqual(game.loadHistory().count, 1)
    }
}
