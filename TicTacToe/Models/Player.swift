import Foundation

/// UI-independent player identity used by the game rules and sparse board.
// `enum` mô tả tập các lựa chọn hợp lệ: ở đây chỉ có cross (X), nought (O).
// `: String` cấp rawValue dạng chuỗi: Player.cross.rawValue là "cross".
// `CaseIterable` cho phép lấy tất cả trường hợp qua Player.allCases.
// Model này không import UIKit: luật chơi không cần biết màu sắc hay màn hình.
enum Player: String, CaseIterable {
    case cross
    case nought

    // Đây là computed property: tính giá trị khi đọc, không lưu thêm biến riêng.
    // `self` là case hiện tại. `điều_kiện ? a : b` trả a nếu đúng, b nếu sai.
    // Swift cho phép bỏ `return` trong getter chỉ gồm một biểu thức.
    // `.cross` là cách viết ngắn của Player.cross khi compiler đã biết kiểu.
    var symbol: String { self == .cross ? "X" : "O" }
    // Getter trả đối thủ: X → O, O → X. Dùng để đổi lượt sau nước hợp lệ.
    var opponent: Player { self == .cross ? .nought : .cross }
}
