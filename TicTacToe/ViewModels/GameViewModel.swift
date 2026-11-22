//
//  GameViewModel.swift
//  TicTacToe
//
//  📌 MỤC ĐÍCH: Chứa toàn bộ LOGIC của game (không có UI).
//  Đây là trái tim của kiến trúc MVVM.
//
//  ─────────────────────────────────────────────────────────────────
//  📖 KIẾN TRÚC MVVM (Model - View - ViewModel)
//  ─────────────────────────────────────────────────────────────────
//  Model      = Dữ liệu thuần túy (Coordinate, Player, MatchRecord)
//  View       = Giao diện (GameViewController, InfiniteBoardView)
//  ViewModel  = Cầu nối: xử lý logic, thông báo cho View khi có thay đổi
//
//  Lợi ích:
//  - View chỉ hiển thị, không biết logic
//  - Logic không phụ thuộc vào UI → dễ test, dễ thay đổi UI sau này
//  - Separation of Concerns (phân tách trách nhiệm)
//  ─────────────────────────────────────────────────────────────────
//

import Foundation  // Không cần UIKit vì ViewModel không chứa UI code

// ─────────────────────────────────────────────────────────────────
// 📖 KHÁI NIỆM: `final class`
// ─────────────────────────────────────────────────────────────────
// `class` = Reference type (khác struct)
// → Dùng class cho ViewModel vì View cần GIỮ THAM CHIẾU đến nó
//   (nhiều View có thể tham chiếu cùng một ViewModel)
//
// `final` = không cho class khác kế thừa (subclass) từ class này
// → Tốt cho performance vì Swift có thể dùng static dispatch
// ─────────────────────────────────────────────────────────────────
final class GameViewModel {

    // MARK: - Hằng số game

    /// Số quân liên tiếp cần để thắng (luật Caro/Gomoku = 5).
    static let winLength = 5
    // `static` = thuộc về CLASS, không phải instance
    // Truy cập: GameViewModel.winLength (không cần tạo object)

    // MARK: - Trạng thái game

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: Dictionary trong Swift
    // ─────────────────────────────────────────────────────────────
    // [Coordinate: Player] = Dictionary với key là Coordinate, value là Player
    // Tương tự Object/Map trong JavaScript: { [key: string]: Player }
    //
    // `private(set)` = bên ngoài class CHỈ ĐỌC được, không sửa được
    // Chỉ code trong class này mới được gán giá trị mới.
    // → Bảo vệ dữ liệu (encapsulation)
    // ─────────────────────────────────────────────────────────────
    
    /// Bàn cờ — lưu thưa (sparse): chỉ những ô CÓ QUÂN mới có trong dict.
    private(set) var board: [Coordinate: Player] = [:]

    /// Người chơi đang đến lượt.
    private(set) var currentPlayer: Player = .cross

    /// Tổng số nước đã đánh trong ván hiện tại.
    private(set) var totalMoves: Int = 0

    /// Điểm X (Cross).
    private(set) var crossScore: Int = 0

    /// Điểm O (Nought).
    private(set) var noughtScore: Int = 0

    // MARK: - Callbacks (Closure để thông báo cho View)

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: Closure (hàm vô danh / lambda)
    // ─────────────────────────────────────────────────────────────
    // Closure = đoạn code có thể lưu trữ và gọi sau, giống lambda/arrow function JS.
    //
    // Cú pháp kiểu closure:
    //   ((_ coordinate: Coordinate, _ winLine: [Coordinate]?) -> Void)?
    //   ↑ nhận vào 2 tham số            ↑ trả về Void (không trả gì)  ↑ optional (có thể nil)
    //
    // Cách dùng trong MVVM:
    //   ViewModel xử lý xong → gọi closure → View tự cập nhật
    //   Giống như EventEmitter / callback pattern trong Node.js
    //
    // `var` vì View sẽ gán closure vào sau khi tạo ViewModel.
    // ─────────────────────────────────────────────────────────────

    /// Gọi sau khi đặt quân. Truyền tọa độ vừa đặt và đường thắng (nếu có).
    var onMovePlaced: ((_ coordinate: Coordinate, _ winLine: [Coordinate]?) -> Void)?

    /// Gọi khi game kết thúc (thắng hoặc hòa).
    var onGameEnded: ((_ result: MatchResult) -> Void)?

    /// Gọi khi điểm thay đổi.
    var onScoreUpdated: (() -> Void)?

    // MARK: - Hành động game

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: @discardableResult
    // ─────────────────────────────────────────────────────────────
    // Hàm này trả về `Bool` (thành công hay không).
    // Mặc định Swift WARNING nếu bạn gọi hàm có return value mà không dùng kết quả.
    // `@discardableResult` → bỏ qua warning đó — caller có thể bỏ qua giá trị trả về.
    // ─────────────────────────────────────────────────────────────
    
    /// Đặt quân tại tọa độ cho. Trả về true nếu hợp lệ.
    @discardableResult
    func place(at coordinate: Coordinate) -> Bool {
        // ─────────────────────────────────────────────────────────
        // 📖 KHÁI NIỆM: Guard statement
        // ─────────────────────────────────────────────────────────
        // `guard condition else { return }` = "nếu điều kiện KHÔNG thỏa → thoát sớm"
        // Khác với `if`: guard giúp tránh lồng nhiều tầng if-else,
        // code "happy path" (đường thành công) không bị thụt vào nhiều.
        //
        // `board[coordinate] == nil` → ô đó chưa có quân
        // ─────────────────────────────────────────────────────────
        guard board[coordinate] == nil else { return false }
        //  ↑ Nếu ô ĐÃ CÓ QUÂN (không nil) → thoát, trả false

        // Đặt quân của người chơi hiện tại vào ô đó
        board[coordinate] = currentPlayer
        totalMoves += 1  // tương đương totalMoves = totalMoves + 1

        // Kiểm tra có thắng không sau nước này
        let winLine = checkWin(at: coordinate, for: currentPlayer)

        if let line = winLine {
            // ─────────────────────────────────────────────────────
            // 📖 KHÁI NIỆM: Optional Binding (`if let`)
            // ─────────────────────────────────────────────────────
            // `checkWin` trả về `[Coordinate]?` (Optional array — có thể nil)
            // `if let line = winLine` → "nếu winLine CÓ GIÁ TRỊ, gán vào line"
            // Bên trong if: `line` chắc chắn không phải nil, an toàn để dùng.
            // ─────────────────────────────────────────────────────
            
            // Tính kết quả dựa trên ai đang chơi
            // Toán tử 3 ngôi: điều_kiện ? giá_trị_nếu_đúng : giá_trị_nếu_sai
            let result: MatchResult = (currentPlayer == .cross) ? .crossWin : .noughtWin

            updateScore(for: result)  // cộng điểm
            saveMatch(result: result)  // lưu vào lịch sử

            // Gọi closure để thông báo cho View (? nghĩa là gọi nếu closure không nil)
            onMovePlaced?(coordinate, line)
            onGameEnded?(result)

        } else if isDraw() {
            let result: MatchResult = .draw
            saveMatch(result: result)
            onMovePlaced?(coordinate, nil)
            onGameEnded?(result)

        } else {
            // Chưa ai thắng → thông báo đặt quân thành công, đổi lượt
            onMovePlaced?(coordinate, nil)
            currentPlayer = currentPlayer.opponent  // dùng computed property ở Player.swift
        }

        return true
    }

    /// Đặt lại bàn cờ về trạng thái ban đầu (điểm số được giữ nguyên).
    func resetGame() {
        board.removeAll()         // xóa hết phần tử trong dictionary
        totalMoves = 0
        currentPlayer = .cross   // X luôn đi trước
    }

    // MARK: - Kiểm tra thắng

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: Tuple
    // ─────────────────────────────────────────────────────────────
    // `(dr: Int, dc: Int)` là một Tuple — nhóm 2 giá trị lại.
    // Không cần tạo struct riêng cho dữ liệu đơn giản chỉ dùng 1 lần.
    // Giống object literal {dr: 0, dc: 1} trong JavaScript.
    // ─────────────────────────────────────────────────────────────
    
    /// Kiểm tra xem nước vừa đặt tại `coordinate` có tạo thành 5 liên tiếp không.
    /// - Returns: Mảng 5+ tọa độ thắng, hoặc `nil` nếu chưa thắng.
    func checkWin(at coordinate: Coordinate, for player: Player) -> [Coordinate]? {
        // 4 hướng cần kiểm tra (mỗi hướng kiểm tra cả 2 chiều):
        // (0,1) = ngang,  (1,0) = dọc,  (1,1) = chéo \,  (1,-1) = chéo /
        let directions: [(dr: Int, dc: Int)] = [(0,1), (1,0), (1,1), (1,-1)]

        for dir in directions {
            // Bắt đầu từ ô vừa đặt
            var line = [coordinate]

            // Mở rộng về phía DƯƠNG (forward)
            var next = coordinate.neighbour(dr: dir.dr, dc: dir.dc)
            while board[next] == player {
                // `while` = lặp khi điều kiện còn đúng
                // Ô tiếp theo có cùng quân → thêm vào đường thắng
                line.append(next)
                next = next.neighbour(dr: dir.dr, dc: dir.dc)  // bước tiếp
            }

            // Mở rộng về phía ÂM (backward — ngược hướng)
            var prev = coordinate.neighbour(dr: -dir.dr, dc: -dir.dc)
            while board[prev] == player {
                line.append(prev)
                prev = prev.neighbour(dr: -dir.dr, dc: -dir.dc)
            }

            // Kiểm tra có đủ 5 ô liên tiếp không
            if line.count >= GameViewModel.winLength {
                return line  // trả về đường thắng
            }
        }

        return nil  // không có đường thắng nào
    }

    // MARK: - Kiểm tra hòa

    private func isDraw() -> Bool {
        // Bàn cờ vô hạn → không bao giờ hòa (luôn còn ô trống)
        return false
    }

    // MARK: - Cập nhật điểm

    /// `private` = chỉ gọi được từ bên trong class này.
    private func updateScore(for result: MatchResult) {
        switch result {
        case .crossWin:  crossScore  += 1
        case .noughtWin: noughtScore += 1
        case .draw:      break  // `break` = không làm gì, thoát khỏi switch
        }
        onScoreUpdated?()  // thông báo View cập nhật điểm
    }

    // MARK: - Lưu lịch sử (UserDefaults)

    /// Key để lưu/đọc từ UserDefaults — đặt tên rõ ràng để tránh xung đột.
    private let historyKey = "match_history_v1"

    /// Lưu ván đấu vừa kết thúc vào UserDefaults.
    func saveMatch(result: MatchResult) {
        // Tạo record mới
        let record = MatchRecord(result: result, totalMoves: totalMoves)

        // Đọc lịch sử cũ
        var history = loadHistory()

        // Thêm record mới vào đầu danh sách
        // `insert(_:at:)` = chèn vào vị trí chỉ định
        history.insert(record, at: 0)

        // Giới hạn 100 record — tránh tốn bộ nhớ
        // `prefix(100)` = lấy tối đa 100 phần tử đầu
        // `Array(...)` = chuyển kết quả về Array (vì prefix trả ArraySlice)
        if history.count > 100 { history = Array(history.prefix(100)) }

        // Encode và lưu
        // `try?` = thử thực hiện, nếu lỗi thì trả nil (không crash)
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    /// Đọc lịch sử từ UserDefaults.
    func loadHistory() -> [MatchRecord] {
        // ─────────────────────────────────────────────────────────
        // 📖 KHÁI NIỆM: guard let với nhiều điều kiện
        // ─────────────────────────────────────────────────────────
        // `guard let a = ..., let b = ...` = kiểm tra cả hai cùng lúc
        // Nếu một trong hai thất bại → vào else block
        // ─────────────────────────────────────────────────────────
        guard
            let data    = UserDefaults.standard.data(forKey: historyKey),
            let records = try? JSONDecoder().decode([MatchRecord].self, from: data)
        else { return [] }  // không có dữ liệu → trả mảng rỗng
        
        return records
    }

    /// Xóa toàn bộ lịch sử.
    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
}
