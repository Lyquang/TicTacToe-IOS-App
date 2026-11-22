//
//  ViewController.swift
//  TicTacToe
//
//  Created by CallumHill on 30/7/21.
//

import UIKit

// FILE THAM KHẢO: màn hình Tic-Tac-Toe 3×3 của starter ban đầu.
// Hiện SceneDelegate mở GameViewController, nên code trong lớp này không điều khiển
// game 5 quân. Giữ lại để so sánh cách ghép UI/logic cũ với kiến trúc MVVM mới.
// Các IBOutlet bên dưới cần Storyboard kết nối; không tạo lớp này bằng init rồi
// truy cập outlet khi chưa tải giao diện, vì những giá trị đó chưa được gán.
class ViewController: UIViewController
{
    // Enum nằm trong một class là kiểu lồng nhau, có thể gọi ViewController.Turn.
    // Nought/Cross là cách đặt tên của code cũ; model mới dùng nought/cross.
	enum Turn {
		case Nought
		case Cross
	}
	
    // @IBOutlet cho Interface Builder kết nối thành phần Storyboard vào biến Swift.
    // weak là tham chiếu yếu: hệ thống view giữ đối tượng, outlet không cần giữ thêm.
    // UILabel! là Optional mở ngầm: compiler cho dùng như có giá trị, nhưng nếu
    // chưa nối outlet hoặc đọc trước khi view tải thì có thể crash vì nil.
    // a1...c3 là chín nút tương ứng chín ô trên bàn 3×3.
	@IBOutlet weak var turnLabel: UILabel!
	@IBOutlet weak var a1: UIButton!
	@IBOutlet weak var a2: UIButton!
	@IBOutlet weak var a3: UIButton!
	@IBOutlet weak var b1: UIButton!
	@IBOutlet weak var b2: UIButton!
	@IBOutlet weak var b3: UIButton!
	@IBOutlet weak var c1: UIButton!
	@IBOutlet weak var c2: UIButton!
	@IBOutlet weak var c3: UIButton!
	
    // firstTurn nhớ ai mở đầu ván; currentTurn là ai đang đến lượt trong ván.
    // Swift suy ra kiểu Turn và String từ giá trị khởi tạo phía bên phải.
	var firstTurn = Turn.Cross
	var currentTurn = Turn.Cross
	
	var NOUGHT = "O"
	var CROSS = "X"
    // [UIButton]() tạo mảng rỗng chứa tham chiếu tới các nút.
    // Bản cũ đọc trạng thái từ chữ trên UIButton; bản mới lưu trạng thái trong Model.
	var board = [UIButton]()
	
	var noughtsScore = 0
	var crossesScore = 0
	
    // override thay hàm của UIViewController; super giữ phần xử lý của lớp cha.
    // initBoard ở đây chỉ gom các outlet đã kết nối thành mảng để tiện duyệt.
	override func viewDidLoad()
	{
		super.viewDidLoad()
		initBoard()
	}
	
	func initBoard()
	{
		board.append(a1)
		board.append(a2)
		board.append(a3)
		board.append(b1)
		board.append(b2)
		board.append(b3)
		board.append(c1)
		board.append(c2)
		board.append(c3)
	}

    // @IBAction cho Storyboard nối sự kiện nút đến hàm. sender chính là nút vừa chạm.
    // `_ sender` bỏ nhãn tham số ở nơi gọi, bên trong vẫn dùng tên sender.
    // Hàm đặt quân rồi kiểm tra thắng X, thắng O và bàn đầy theo ba if độc lập.
    // Hạn chế code cũ: nước cuối vừa thắng vừa đầy bàn có thể yêu cầu hai alert;
    // logic mới dùng một nhánh kết thúc ván và trạng thái gameResult để tránh điều này.
	@IBAction func boardTapAction(_ sender: UIButton)
	{
		addToBoard(sender)
		
		if checkForVictory(CROSS)
		{
			crossesScore += 1
			resultAlert(title: "Crosses Win!")
		}
		
		if checkForVictory(NOUGHT)
		{
			noughtsScore += 1
			resultAlert(title: "Noughts Win!")
		}
		
		if(fullBoard())
		{
			resultAlert(title: "Draw")
		}
	}
	
    // s là ký hiệu cần kiểm tra. && yêu cầu cả ba điều kiện đều đúng.
    // Liệt kê sẵn 3 hàng + 3 cột + 2 đường chéo, chỉ phù hợp bàn 3×3 cố định.
    // Game mới thay cách này bằng kiểm tra bốn trục đi qua nước mới.
	func checkForVictory(_ s :String) -> Bool
	{
		// Horizontal Victory
		if thisSymbol(a1, s) && thisSymbol(a2, s) && thisSymbol(a3, s)
		{
			return true
		}
		if thisSymbol(b1, s) && thisSymbol(b2, s) && thisSymbol(b3, s)
		{
			return true
		}
		if thisSymbol(c1, s) && thisSymbol(c2, s) && thisSymbol(c3, s)
		{
			return true
		}
		
		// Vertical Victory
		if thisSymbol(a1, s) && thisSymbol(b1, s) && thisSymbol(c1, s)
		{
			return true
		}
		if thisSymbol(a2, s) && thisSymbol(b2, s) && thisSymbol(c2, s)
		{
			return true
		}
		if thisSymbol(a3, s) && thisSymbol(b3, s) && thisSymbol(c3, s)
		{
			return true
		}
		
		// Diagonal Victory
		if thisSymbol(a1, s) && thisSymbol(b2, s) && thisSymbol(c3, s)
		{
			return true
		}
		if thisSymbol(a3, s) && thisSymbol(b2, s) && thisSymbol(c1, s)
		{
			return true
		}
		
		return false
	}
	
    // title(for: .normal) trả String?; so sánh với symbol để biết nút có ký hiệu đó không.
	func thisSymbol(_ button: UIButton, _ symbol: String) -> Bool
	{
		return button.title(for: .normal) == symbol
	}
	
    // Ghép chuỗi bằng +; String(Int) chuyển số thành chuỗi; \n tạo dòng mới.
    // Alert kiểu actionSheet hiện lựa chọn; closure handler được gọi khi chọn Reset.
    // Đây là UI cũ: nếu dùng actionSheet trên iPad còn phải cấu hình điểm neo popover.
	func resultAlert(title: String)
	{
		let message = "\nNoughts " + String(noughtsScore) + "\n\nCrosses " + String(crossesScore)
		let ac = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
		ac.addAction(UIAlertAction(title: "Reset", style: .default, handler: { (_) in
			self.resetBoard()
		}))
		self.present(ac, animated: true)
	}
	
    // for-in duyệt chín nút, xóa chữ và bật lại khả năng chạm.
    // Sau mỗi ván đổi người bắt đầu, rồi đặt currentTurn bằng firstTurn.
    // Khác game mới: game mới hiện luôn cho X mở đầu.
	func resetBoard()
	{
		for button in board
		{
			button.setTitle(nil, for: .normal)
			button.isEnabled = true
		}
		if firstTurn == Turn.Nought
		{
			firstTurn = Turn.Cross
			turnLabel.text = CROSS
		}
		else if firstTurn == Turn.Cross
		{
			firstTurn = Turn.Nought
			turnLabel.text = NOUGHT
		}
		currentTurn = firstTurn
	}
	
    // Nếu bất kỳ nút nào chưa có chữ thì bàn chưa đầy → return false ngay.
    // Duyệt hết mà không gặp ô trống thì return true.
	func fullBoard() -> Bool
	{
		for button in board
		{
			if button.title(for: .normal) == nil
			{
				return false
			}
		}
		return true
	}
	
    // Chỉ gán quân nếu nút đang trống; sau đó đổi lượt, cập nhật nhãn và tắt nút.
    // Code cũ dùng trạng thái UIButton làm dữ liệu game; vì vậy khó test độc lập UI.
	func addToBoard(_ sender: UIButton)
	{
		if(sender.title(for: .normal) == nil)
		{
			if(currentTurn == Turn.Nought)
			{
				sender.setTitle(NOUGHT, for: .normal)
				currentTurn = Turn.Cross
				turnLabel.text = CROSS
			}
			else if(currentTurn == Turn.Cross)
			{
				sender.setTitle(CROSS, for: .normal)
				currentTurn = Turn.Nought
				turnLabel.text = NOUGHT
			}
			sender.isEnabled = false
		}
	}
	
}

