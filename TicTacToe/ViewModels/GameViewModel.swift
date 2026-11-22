import Foundation

/// Owns the rules and local match summaries; views observe changes through callbacks.
// MVVM = Model (dữ liệu), View (hiển thị), ViewModel (trạng thái và xử lý).
// ViewModel không trực tiếp sửa UILabel hay vẽ bàn cờ; nó phát callback cho View.
// `final` cấm tạo lớp con. `class` giúp View và màn hình History cùng giữ
// tham chiếu tới một ViewModel, thay vì mỗi nơi có một bản sao trạng thái.
// Các thao tác game hiện được gọi trên main thread; class này không tự khóa board.
final class GameViewModel {
    // `static` thuộc về kiểu, gọi GameViewModel.winLength; không cần tạo đối tượng.
    // `private` giới hạn truy cập trong phạm vi khai báo và các extension cùng file.
    // historyKey là tên mục lưu trữ, không phải đường dẫn tới một file JSON.
    static let winLength = 5
    private static let historyKey = "match_history_v1"
    private let defaults: UserDefaults

    // private(set): bên ngoài đọc được nhưng chỉ bên trong mới được thay đổi.
    // `[Coordinate: Player]` là Dictionary: tọa độ → người đang chiếm ô.
    // `[:]` tạo dictionary rỗng. Chỉ lưu ô đã đánh, không tạo trước mọi ô trống.
    // board[tọa_độ] trả Player?; nil có nghĩa ô chưa chứa quân.
    private(set) var board: [Coordinate: Player] = [:]
    // Compiler suy ra kiểu của 0 là Int. Điểm X/O chỉ sống trong phiên chạy app.
    // MatchResult? là Optional: nil nghĩa ván chưa kết thúc; có kết quả nghĩa đã xong.
    private(set) var currentPlayer: Player = .cross
    private(set) var totalMoves = 0
    private(set) var crossScore = 0
    private(set) var noughtScore = 0
    private(set) var gameResult: MatchResult?

    // Callback là một closure (khối lệnh có thể lưu trong biến và gọi sau).
    // ((_ coordinate: Coordinate, _ winLine: [Coordinate]?) -> Void)? nghĩa là:
    // - nhận một tọa độ và một mảng tọa độ tùy chọn;
    // - trả Void, tức không trả dữ liệu;
    // - cả callback cũng là Optional: View chưa gán thì callback là nil.
    // `[Coordinate]?` khác `[Coordinate?]`: mảng có thể không có, thay vì từng ô nil.
    var onMovePlaced: ((_ coordinate: Coordinate, _ winLine: [Coordinate]?) -> Void)?
    var onGameEnded: ((_ result: MatchResult) -> Void)?
    var onScoreUpdated: (() -> Void)?

    // `init` khởi tạo đối tượng. Giá trị mặc định .standard dùng kho của app.
    // Test truyền kho riêng để không đọc/ghi lịch sử thật: dependency injection.
    // `let defaults` giữ cố định tham chiếu kho; dữ liệu bên trong kho vẫn đổi được.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // Cho phép bên gọi bỏ qua Bool trả về mà không bị cảnh báo.
    // `at` là nhãn ở nơi gọi: game.place(at: position).
    // `coordinate` là tên biến sử dụng bên trong thân hàm.
    @discardableResult
    func place(at coordinate: Coordinate) -> Bool {
        // Dấu phẩy trong guard yêu cầu đồng thời cả hai điều kiện đúng:
        // ván còn chạy VÀ ô chưa có quân. return false không thay đổi trạng thái.
        guard gameResult == nil, board[coordinate] == nil else { return false }
        // Giữ lại người đang đánh trước khi có thể đổi lượt.
        // Gán vào dictionary tạo/cập nhật mục tương ứng. `+= 1` là tăng thêm một.
        let player = currentPlayer
        board[coordinate] = player
        totalMoves += 1

        // `if let` mở giá trị Optional chỉ bên trong nhánh if.
        // checkWin trả nil khi chưa thắng; trả mảng tọa độ khi tìm thấy hàng thắng.
        if let line = checkWin(at: coordinate, for: player) {
            let result: MatchResult = player == .cross ? .crossWin : .noughtWin
            // Finish before invoking observers so callbacks cannot place another move.
            // Khóa trạng thái ván trước khi thông báo View. Nếu một callback gọi
            // place lần nữa, guard phía trên sẽ từ chối, tránh lưu kết quả hai lần.
            gameResult = result
            if player == .cross { crossScore += 1 } else { noughtScore += 1 }
            saveMatch(result: result)
            // `callback?(...)` chỉ gọi nếu callback khác nil (optional chaining).
            // Thứ tự: cập nhật bàn → cập nhật điểm → thông báo kết thúc.
            onMovePlaced?(coordinate, line)
            onScoreUpdated?()
            onGameEnded?(result)
        } else {
            // Đổi lượt trước callback, để View đọc được người chơi của lượt mới.
            currentPlayer = player.opponent
            onMovePlaced?(coordinate, nil)
        }
        return true
    }

    /// Starts a new round while preserving session scores and completed history.
    // `removeAll` xóa các mục dictionary. Reset giữ nguyên điểm phiên và lịch sử;
    // không lưu ván bỏ dở, không đặt lại góc nhìn/zoom của UIScrollView.
    func resetGame() {
        board.removeAll()
        totalMoves = 0
        currentPlayer = .cross
        gameResult = nil
    }

    /// Checks only lines crossing the latest move, in both directions of each axis.
    /// Five or more consecutive pieces win; blocked ends do not change this rule.
    // Kiểu trả về [Coordinate]? cho phép phân biệt không thắng (nil)
    // với một danh sách các ô thực sự tạo thành đường thắng.
    func checkWin(at coordinate: Coordinate, for player: Player) -> [Coordinate]? {
        guard board[coordinate] == player else { return nil }
        // Mỗi cặp (dr, dc) là tuple: độ thay đổi hàng và cột.
        // Ngang (0,1), dọc (1,0), chéo xuống (1,1), chéo ngược (1,-1).
        // Chỉ hàng đi qua nước mới có thể tạo chiến thắng mới, không cần quét cả bàn.
        let axes = [(0, 1), (1, 0), (1, 1), (1, -1)]
        // `for ... in` duyệt tập hợp; `(dr, dc)` tách hai phần tử của tuple.
        // [] tạo mảng rỗng. Hai mảng chứa quân cùng loại ở hai phía của nước mới.
        for (dr, dc) in axes {
            var forward: [Coordinate] = []
            var backward: [Coordinate] = []
            var next = coordinate.neighbour(dr: dr, dc: dc)
            // `while` lặp khi ô tiếp theo cùng người chơi. Gặp ô trống hoặc đối thủ
            // thì dừng. append thêm một phần tử vào cuối mảng.
            while board[next] == player {
                forward.append(next)
                next = next.neighbour(dr: dr, dc: dc)
            }
            // Đảo dấu cả hai độ lệch để kiểm tra chiều còn lại trên cùng trục.
            next = coordinate.neighbour(dr: -dr, dc: -dc)
            while board[next] == player {
                backward.append(next)
                next = next.neighbour(dr: -dr, dc: -dc)
            }
            // Ghép theo thứ tự không gian: phía ngược (đảo lại), ô mới, phía thuận.
            // Ví dụ [cột 0,1] + [cột 2] + [cột 3,4]. `+` nối các mảng.
            // reversed trả một collection đảo chiều; Array(...) biến thành mảng.
            // Self là kiểu hiện tại (GameViewModel); self là đối tượng hiện tại.
            let line = Array(backward.reversed()) + [coordinate] + forward
            if line.count >= Self.winLength { return line }
        }
        return nil
    }

    // Chỉ lưu tóm tắt khi thắng; không lưu dictionary các nước hay ván đang chơi.
    // Model vẫn có case draw, nhưng luật hiện tại không tự kết luận hòa.
    private func saveMatch(result: MatchResult) {
        var history = loadHistory()
        // insert(..., at: 0) đặt ván mới ở đầu để lịch sử mới nhất xuất hiện trước.
        history.insert(MatchRecord(result: result, totalMoves: totalMoves), at: 0)
        // Codable cho JSONEncoder biết cách chuyển các record thành Data (bytes).
        // prefix(100) giữ tối đa 100 ván. `try?` biến lỗi encode thành nil;
        // if let chỉ ghi kho khi encode thành công, thay vì làm app dừng vì lỗi.
        if let data = try? JSONEncoder().encode(Array(history.prefix(100))) {
            defaults.set(data, forKey: Self.historyKey)
        }
    }

    // Đọc bytes theo key rồi JSONDecoder chuyển ngược thành mảng MatchRecord.
    // `[MatchRecord].self` là giá trị mô tả kiểu cần giải mã, không phải một record.
    // guard dưới đây cần cả dữ liệu lẫn kết quả giải mã; lỗi/không có thì trả [].
    func loadHistory() -> [MatchRecord] {
        guard let data = defaults.data(forKey: Self.historyKey),
              let records = try? JSONDecoder().decode([MatchRecord].self, from: data)
        else { return [] }
        return records
    }

    // Xóa mục lưu trữ, không xóa điểm X/O của phiên hiện tại.
    func clearHistory() {
        defaults.removeObject(forKey: Self.historyKey)
    }
}
