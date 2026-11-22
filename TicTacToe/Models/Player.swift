//
//  Player.swift
//  TicTacToe
//
//  📌 MỤC ĐÍCH: Đại diện cho người chơi trong game.
//  X (Cross) = màu đỏ, O (Nought) = màu trắng ngà.
//

import UIKit  // Import UIKit để dùng UIColor

// ─────────────────────────────────────────────────────────────────
// 📖 KHÁI NIỆM SWIFT: enum (Enumeration)
// ─────────────────────────────────────────────────────────────────
// `enum` = kiểu dữ liệu liệt kê — chỉ có một số giá trị cố định.
// Thay vì dùng String "X"/"O" hay Int 0/1 (dễ nhầm lẫn),
// ta dùng enum để code rõ ràng và an toàn hơn.
//
// So sánh với JavaScript:
//   JS: const player = "cross"  // có thể nhập sai "Cross", "CROSS"...
//   Swift: let player = Player.cross  // compiler kiểm tra, không nhầm được
// ─────────────────────────────────────────────────────────────────

enum Player: String, CaseIterable {
    // Hai trường hợp (case) của enum này:
    case cross   // Người chơi X — màu đỏ
    case nought  // Người chơi O — màu trắng ngà

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: Computed Property (thuộc tính tính toán)
    // ─────────────────────────────────────────────────────────────
    // Đây là thuộc tính KHÔNG lưu trữ giá trị — nó tính toán mỗi lần đọc.
    // Tương tự như getter trong JavaScript:
    //   get symbol() { return this === 'cross' ? 'X' : 'O' }
    //
    // `var symbol: String` có nghĩa: "thuộc tính symbol, kiểu String"
    // Khối `{ switch self { ... } }` là phần tính toán.
    // ─────────────────────────────────────────────────────────────
    
    /// Ký hiệu hiển thị trên bàn cờ.
    var symbol: String {
        // `switch self` = kiểm tra giá trị của enum hiện tại
        switch self {
        case .cross:  return "X"
        case .nought: return "O"
        }
        // ⚠️ Swift bắt buộc switch phải xử lý TẤT CẢ các case (exhaustive)
        // Nếu thêm case mới vào enum mà không cập nhật switch → lỗi compile
    }

    /// Màu sắc vẽ quân cờ trên bàn.
    var color: UIColor {
        switch self {
        // UIColor(red:green:blue:alpha:) nhận giá trị từ 0.0 đến 1.0
        // (không phải 0-255 như CSS/Android)
        case .cross:
            return UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
            // → Màu đỏ tươi (giống màu đỏ của Apple)
        case .nought:
            return UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
            // → Màu trắng ngà, nhìn rõ trên nền tối
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: Computed Property trả về kiểu chính nó
    // ─────────────────────────────────────────────────────────────
    // `opponent` trả về người chơi còn lại.
    // Dùng trong logic "sau khi X đánh xong → đến lượt O"
    // ─────────────────────────────────────────────────────────────
    
    /// Người chơi đối diện.
    var opponent: Player {
        switch self {
        case .cross:  return .nought  // có thể viết tắt `.nought` thay vì `Player.nought`
        case .nought: return .cross   // Swift tự suy ra kiểu từ ngữ cảnh
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// 📖 THÊM: Tại sao `enum Player: String, CaseIterable`?
// ─────────────────────────────────────────────────────────────────
// `: String` = Raw Value — mỗi case có thể chuyển thành String:
//   Player.cross.rawValue    → "cross"
//   Player(rawValue: "cross") → Player.cross (optional!)
//
// `CaseIterable` → Swift tự tạo mảng tất cả case:
//   Player.allCases → [.cross, .nought]
//   Dùng để loop qua tất cả người chơi nếu cần.
// ─────────────────────────────────────────────────────────────────
