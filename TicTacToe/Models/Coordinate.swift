//
//  Coordinate.swift
//  TicTacToe
//
//  📌 MỤC ĐÍCH: Đại diện cho một vị trí ô trên bàn cờ vô hạn.
//  Thay vì dùng mảng 2 chiều [row][col], ta dùng struct này như một "key"
//  trong Dictionary để lưu trạng thái bàn cờ hiệu quả hơn.
//

import Foundation

// ─────────────────────────────────────────────────────────────────
// 📖 KHÁI NIỆM SWIFT: struct vs class
// ─────────────────────────────────────────────────────────────────
// - `struct` là kiểu VALUE TYPE: khi gán cho biến khác, nó được SAO CHÉP.
//   Ví dụ: let a = Coordinate(row:0, col:0); var b = a
//   b = Coordinate(row:5, col:0) → a.row vẫn là 0, b.row là 5.
//   Không thể viết b.row = 5 trong kiểu này vì row được khai báo let.
//
// - `class` là kiểu REFERENCE TYPE: khi gán, cả hai biến trỏ cùng một object.
//
// → Nên dùng `struct` cho dữ liệu đơn giản, bất biến (immutable) như tọa độ.
// ─────────────────────────────────────────────────────────────────

// Protocol sau dấu : là các khả năng kiểu này cung cấp, không phải lớp cha:
// Hashable: dùng làm key Dictionary/phần tử Set; Equatable: so sánh bằng ==;
// Codable: có thể encode/decode. Hashable vốn đã yêu cầu Equatable.
// Với các thuộc tính này, Swift có thể tự sinh hash và ==; ở đây viết ra để học.
// Swift tự cấp init(row:col:), nên có thể gọi Coordinate(row: 2, col: 3).
struct Coordinate: Hashable, Equatable, Codable {
    // `let` = hằng số (constant) — không thể thay đổi sau khi tạo
    // `var` = biến (variable) — có thể thay đổi
    let row: Int  // hàng (dọc)
    let col: Int  // cột (ngang)

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: Hashable protocol
    // ─────────────────────────────────────────────────────────────
    // Để dùng `Coordinate` làm KEY trong Dictionary ([Coordinate: Player]),
    // Swift cần biết cách "băm" (hash) nó thành một số nguyên.
    // Chúng ta implement hàm `hash(into:)` để nói với Swift cách tính.
    //
    // `hasher.combine(row)` → đưa giá trị row vào bộ tính hash
    // `hasher.combine(col)` → đưa cả cột vào phép băm; kết quả không bảo đảm duy nhất.
    // ─────────────────────────────────────────────────────────────
    // `inout` cho phép hàm cập nhật Hasher được bên gọi truyền vào.
    // Bên gọi Swift thường dùng &variable cho đối số inout; Dictionary tự gọi hàm này.
    // Hàm băm cần nhất quán với ==: hai tọa độ bằng nhau phải có cùng giá trị băm.
    // Hai tọa độ khác nhau vẫn có thể trùng hash; Dictionary tiếp tục dùng == để phân biệt.
    func hash(into hasher: inout Hasher) {
        hasher.combine(row)
        hasher.combine(col)
    }

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: Equatable protocol
    // ─────────────────────────────────────────────────────────────
    // Để so sánh hai Coordinate bằng toán tử `==`, ta implement hàm này.
    // `static func` = hàm thuộc về kiểu dữ liệu, không phải instance.
    // `lhs` = left-hand side (vế trái), `rhs` = right-hand side (vế phải)
    // Ví dụ: Coordinate(row:1,col:2) == Coordinate(row:1,col:2) → true
    // ─────────────────────────────────────────────────────────────
    static func == (lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.row == rhs.row && lhs.col == rhs.col
    }

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: Method (hàm instance)
    // ─────────────────────────────────────────────────────────────
    // Hàm này trả về một Coordinate mới ở hướng (dr, dc) so với ô hiện tại.
    // dr = delta row (thay đổi hàng), dc = delta col (thay đổi cột)
    //
    // Ví dụ kiểm tra 5 ô liên tiếp theo chiều ngang:
    // Bắt đầu từ (5,3), gọi neighbour(dr:0, dc:1) → (5,4) → (5,5) → ...
    // ─────────────────────────────────────────────────────────────
    func neighbour(dr: Int, dc: Int) -> Coordinate {
        // Tạo Coordinate mới với tọa độ dịch chuyển
        return Coordinate(row: row + dr, col: col + dc)
    }
}
