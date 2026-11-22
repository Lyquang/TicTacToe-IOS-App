//
//  MatchRecord.swift
//  TicTacToe
//
//  📌 MỤC ĐÍCH: Lưu thông tin một ván đấu đã kết thúc.
//  Được lưu vào UserDefaults (bộ nhớ thiết bị) qua JSON encoding.
//

import Foundation

// ─────────────────────────────────────────────────────────────────
// 📖 KHÁI NIỆM: enum với Raw Value kiểu String
// ─────────────────────────────────────────────────────────────────
// `Codable` = có thể chuyển sang JSON và ngược lại tự động.
// Swift tự làm tất cả, không cần viết code encode/decode thủ công!
// ─────────────────────────────────────────────────────────────────

/// Kết quả của một ván đấu.
enum MatchResult: String, Codable {
    case crossWin  = "X Wins"   // rawValue = "X Wins" (chuỗi lưu vào JSON)
    case noughtWin = "O Wins"
    case draw      = "Draw"

    /// Chuỗi hiển thị có emoji — dùng cho UI.
    var emoji: String {
        switch self {
        case .crossWin:  return "🔴 X Wins"
        case .noughtWin: return "⚪ O Wins"
        case .draw:      return "🤝 Draw"
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// 📖 KHÁI NIỆM: Codable = Encodable + Decodable
// ─────────────────────────────────────────────────────────────────
// Khi struct tuân theo `Codable`, Swift tự động:
//   1. Encode (struct → JSON): JSONEncoder().encode(record)
//   2. Decode (JSON → struct): JSONDecoder().decode(MatchRecord.self, from: data)
//
// `Identifiable` → yêu cầu có thuộc tính `id` duy nhất.
// Dùng trong SwiftUI List, nhưng cũng tốt để dùng ở đây cho rõ ràng.
// ─────────────────────────────────────────────────────────────────

/// Thông tin một ván đấu đã kết thúc.
struct MatchRecord: Codable, Identifiable {
    
    // UUID = Universally Unique Identifier — chuỗi 128-bit duy nhất
    // Ví dụ: "550e8400-e29b-41d4-a716-446655440000"
    // Dùng để phân biệt từng record, không bao giờ trùng nhau.
    let id: UUID
    
    // Date = kiểu ngày giờ của Swift (tương tự Date object trong JS)
    let date: Date
    
    let result: MatchResult  // kết quả ván đấu
    let totalMoves: Int      // tổng số nước đã đánh

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: Custom Initializer (hàm khởi tạo tùy chỉnh)
    // ─────────────────────────────────────────────────────────────
    // Mặc định, Swift tự tạo `init` với đầy đủ tham số (memberwise init):
    //   MatchRecord(id: ..., date: ..., result: ..., totalMoves: ...)
    //
    // Ta viết init tùy chỉnh để:
    //   1. Tự tạo UUID mới → người dùng không cần truyền vào
    //   2. Tự lấy thời gian hiện tại → không cần truyền date
    //
    // Kết quả: Gọi đơn giản hơn: MatchRecord(result: .crossWin, totalMoves: 10)
    // ─────────────────────────────────────────────────────────────
    init(result: MatchResult, totalMoves: Int) {
        self.id         = UUID()    // tạo UUID ngẫu nhiên
        self.date       = Date()    // lấy thời điểm hiện tại
        self.result     = result
        self.totalMoves = totalMoves
    }
}

// ─────────────────────────────────────────────────────────────────
// 📖 TẠI SAO DÙNG UserDefaults?
// ─────────────────────────────────────────────────────────────────
// UserDefaults là nơi lưu dữ liệu nhỏ, đơn giản trên thiết bị.
// Tương tự localStorage trong JavaScript browser.
//
// UserDefaults.standard.set(value, forKey: "key")   // lưu
// UserDefaults.standard.data(forKey: "key")          // đọc
// UserDefaults.standard.removeObject(forKey: "key")  // xóa
//
// Vì MatchRecord là Codable, ta có thể:
//   let data = try JSONEncoder().encode(records)  // struct → Data (bytes)
//   UserDefaults.standard.set(data, forKey: "history")
// ─────────────────────────────────────────────────────────────────
