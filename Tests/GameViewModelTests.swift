// XCTest cung cấp bộ công cụ kiểm thử. Chạy `swift test` ở thư mục dự án.
// @testable cho phép test truy cập các khai báo internal của module được build để test;
// nó không làm các thuộc tính private trở thành public và không nằm trong bản app.
import XCTest
@testable import TicTacToeRules

// XCTestCase là lớp cha cho nhóm test. Các hàm test... sẽ được runner tìm và gọi.
// Assertions kiểm tra kỳ vọng; sai thì ghi nhận thất bại thay vì báo thành công giả.
final class GameViewModelTests: XCTestCase {
    // Hai Optional mở ngầm này được setUp gán trước từng test.
    // Chỉ an toàn khi runner thực hiện đúng vòng đời setUp → test → tearDown.
    private var defaults: UserDefaults!
    private var suite: String!

    // Mỗi test có suite UserDefaults tên UUID riêng, tránh đụng dữ liệu thật
    // và tránh trạng thái của một test làm ảnh hưởng test tiếp theo.
    override func setUp() {
        super.setUp()
        suite = "TicTacToeTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
    }

    // Dọn kho riêng khi test xong. setUp gọi super trước, tearDown gọi super sau.
    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    // Hàm trợ giúp rút gọn cách tạo tọa độ. `_` cho phép coordinate(0, 1).
    private func coordinate(_ row: Int, _ col: Int) -> Coordinate {
        Coordinate(row: row, col: col)
    }

    // Dựng ván hợp lệ bằng chính API place, không sửa trực tiếp board private(set).
    // dr/dc mặc định là ngang; nought mặc định false. Nước đệm cách xa nhau
    // để người còn lại không vô tình thắng trước. 0..<5 tạo các số 0,1,2,3,4.
    private func win(_ game: GameViewModel, dr: Int = 0, dc: Int = 1, nought: Bool = false) {
        if nought { XCTAssertTrue(game.place(at: coordinate(100, 100))) }
        for i in 0..<5 {
            XCTAssertTrue(game.place(at: coordinate(i * dr, i * dc)))
            if i < 4 { XCTAssertTrue(game.place(at: coordinate(50 + i * 2, 30))) }
        }
    }

    // Tám tổ hợp: bốn trục × hai người thắng. XCTAssertEqual so sánh kết quả,
    // số record, số nước và điểm. X thắng sớm nhất nước 9; O là nước 10.
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

    // XCTAssertTrue/False kiểm tra nước hợp lệ/không hợp lệ. Nước bị từ chối
    // không được tăng số nước, đổi lượt hoặc thêm một record sau khi ván đã xong.
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

    // Đặt X ở cột 0,1,3,4,5 rồi lấp cột 2: nối hai phía thành sáu quân.
    // Chứng minh luật >=5 và thứ tự đường thắng. enumerated trả (index, phần tử).
    // map biến mỗi số trong 0...5 thành một Coordinate để tạo mảng kỳ vọng.
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

    // XCTAssertNil yêu cầu Optional không có giá trị. Ô trống ở giữa hoặc
    // quân đối thủ phải làm đứt chuỗi; ván chưa kết thúc thì lịch sử vẫn rỗng.
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

    // Callback đọc được lượt đã cập nhật. Nếu callback thử đặt tiếp sau khi thắng,
    // ViewModel phải từ chối ngay, chứng minh trạng thái được đóng trước callback.
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

    // Tạo ViewModel thứ hai dùng cùng kho để chứng minh có encode/decode thật.
    // Reset chỉ xóa ván hiện tại; id/date/result của bản ghi cũ không được đổi.
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

    // Tạo 101 ván, đọc lại chỉ 100 ván mới nhất. `for _` không cần biến đếm.
    // map(\.id) là key-path shorthand tương đương map { $0.id }.
    // Set kiểm tra không có id trùng; sorted(by: >) sắp ngày mới → cũ.
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

    // Cố tình lưu bytes không phải JSON. Đọc phải trả [], ván thắng sau đó vẫn lưu được.
    // Data("...".utf8) chuyển chuỗi thành bytes theo bảng mã UTF-8.
    func testCorruptHistoryDoesNotCrashOrBlockNextSave() {
        defaults.set(Data("invalid json".utf8), forKey: "match_history_v1")
        let game = GameViewModel(defaults: defaults)
        XCTAssertTrue(game.loadHistory().isEmpty)
        win(game)
        XCTAssertEqual(game.loadHistory().count, 1)
    }
}
