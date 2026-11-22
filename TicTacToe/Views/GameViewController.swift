//
//  GameViewController.swift
//  TicTacToe
//
//  📌 MỤC ĐÍCH: Màn hình game chính.
//  Không dùng Storyboard — UI được tạo hoàn toàn bằng code.
//
//  ─────────────────────────────────────────────────────────────────
//  📖 UIViewController là gì?
//  ─────────────────────────────────────────────────────────────────
//  UIViewController = "Bộ điều khiển" của một màn hình.
//  Mỗi màn hình trong app thường có 1 ViewController.
//  Nó quản lý: vòng đời (lifecycle), views, input người dùng.
//
//  Vòng đời quan trọng:
//  viewDidLoad()         → view đã tải xong, chưa hiển thị
//  viewDidLayoutSubviews() → layout đã hoàn tất, kích thước xác định
//  viewDidAppear()       → view đang hiển thị trên màn hình
//  ─────────────────────────────────────────────────────────────────
//

import UIKit

// extension thêm khả năng cho một kiểu đã có, không sửa phần định nghĩa gốc.
// Màu sắc nằm ở tầng View (UIKit); Player trong Model chỉ giữ danh tính X/O.
// switch phải xử lý mọi case; nếu thêm người chơi mới compiler sẽ yêu cầu cập nhật.
extension Player {
    var color: UIColor {
        switch self {
        case .cross: return UIColor(red: 1, green: 0.23, blue: 0.19, alpha: 1)
        case .nought: return UIColor(white: 0.9, alpha: 1)
        }
    }
}

// UIViewController quản lý một màn hình: tạo view, nhận thao tác và điều phối.
// Nó giao luật chơi cho ViewModel và giao việc vẽ cho InfiniteBoardView.
// Đây là màn hình thực tế được SceneDelegate đặt làm rootViewController.
final class GameViewController: UIViewController {

    // MARK: - Hằng số

    /// Canvas 6000×6000pt — đủ lớn để chơi hàng trăm nước.
    // private let: tham chiếu/giá trị này được gán một lần và không lộ ra bên ngoài.
    // Dùng `let viewModel` vẫn gọi được place/reset: let không đóng băng đối tượng class.
    private let canvasSize: CGFloat = 6000

    /// Kích thước mỗi ô cờ (đồng bộ với InfiniteBoardView).
    private let cellSize: CGFloat = 48

    // MARK: - ViewModel

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: Dependency trong MVVM
    // ─────────────────────────────────────────────────────────────
    // ViewController "sở hữu" ViewModel.
    // `private let` → không thể thay thế sau khi tạo (strong reference)
    // Khi ViewController bị hủy → ViewModel cũng bị hủy theo (ARC)
    //
    // ARC = Automatic Reference Counting = Swift tự quản lý bộ nhớ.
    // Khác C/C++ phải free() thủ công, khác Java có GC.
    // ─────────────────────────────────────────────────────────────
    private let viewModel = GameViewModel()

    // MARK: - UI Components

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: `lazy var`
    // ─────────────────────────────────────────────────────────────
    // `lazy` = chỉ tạo object KHI LẦN ĐẦU TIÊN được truy cập.
    // Lợi ích: tiết kiệm bộ nhớ nếu property không bao giờ dùng.
    //
    // Tại sao dùng cho UI components?
    // - Trong `init`, `self` chưa hoàn toàn sẵn sàng
    // - `lazy var` được tạo sau init, khi `self` đã hoàn chỉnh
    // - Cho phép dùng `self` bên trong closure khởi tạo
    //
    // Cú pháp: lazy var tên: Kiểu = { ... return giá_trị ... }()
    //          ← closure tự gọi ngay (immediately invoked)
    // ─────────────────────────────────────────────────────────────

    /// ScrollView bao quanh toàn bộ bàn cờ — cho phép pan & zoom.
    // lazy trì hoãn khởi tạo tới lần truy cập đầu, thuận tiện khi cấu hình cần self.
    // `{ ... }()` là closure được gọi để tạo giá trị: tạo view → cấu hình → return.
    // UIScrollView chứa canvas lớn hơn màn hình: contentSize là kích thước nội dung,
    // bounds.size là kích thước vùng đang nhìn và contentOffset là vị trí đang cuộn.
    // delegate nhận các câu hỏi/sự kiện từ scroll view; self sẽ cung cấp view cần zoom.
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        // Tắt chuyển autoresizing mask thành constraint để dùng Auto Layout tự khai báo.
        // Các UIView được bố trí bằng anchor trong setupUI đều dùng lựa chọn này.
        sv.translatesAutoresizingMaskIntoConstraints = false
        // ↑ BẮT BUỘC đặt false khi dùng Auto Layout (constraint-based layout)
        //   Nếu true: iOS tự tạo constraint từ frame → xung đột
        sv.delegate = self  // đặt ViewController làm delegate của ScrollView
        // `delegate` = thiết kế pattern Delegation:
        //   ScrollView không biết ai đang dùng nó
        //   Nó gọi các method của delegate khi có sự kiện
        //   ViewController implement các method đó
        sv.minimumZoomScale = 0.3  // thu nhỏ tối đa 30%
        sv.maximumZoomScale = 3.0  // phóng to tối đa 300%
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator   = false
        sv.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.18, alpha: 1)
        sv.bouncesZoom = true  // hiệu ứng nảy khi zoom quá giới hạn
        return sv
    }()

    /// Bàn cờ vô hạn — subview của scrollView.
    // Khác scrollView được Auto Layout bố trí, canvas con có frame cố định.
    // CGRect(origin:size:) nhận CGPoint vị trí và CGSize kích thước; .zero là (0,0).
    private lazy var boardView: InfiniteBoardView = {
        // CGRect(origin:size:) = hình chữ nhật với điểm gốc và kích thước
        let bv = InfiniteBoardView(frame: CGRect(origin: .zero,
                                                  size: CGSize(width: canvasSize,
                                                               height: canvasSize)))
        // `.zero` = CGPoint(x: 0, y: 0) — shorthand trong Swift
        bv.cellSize = cellSize
        return bv
    }()

    // MARK: - HUD (Heads-Up Display — thanh thông tin trên cùng)

    private lazy var hudView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.14, alpha: 0.97)
        return v
    }()

    /// Chấm tròn màu đỏ/trắng — chỉ lượt ai đang chơi.
    private lazy var turnIndicator: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 5  // bo góc = cornerRadius → hình tròn khi width == height == 10
        v.backgroundColor = Player.cross.color
        return v
    }()

    /// Label hiển thị "X's Turn" hoặc "O's Turn".
    // UILabel hiển thị chữ; UIFont chọn kích thước/độ đậm chữ.
    // turnIndicator là dấu màu, turnLabel là lượt và scoreLabel là điểm trong phiên.
    private lazy var turnLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "X's Turn"
        l.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .white
        return l
    }()

    /// Label điểm số.
    private lazy var scoreLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        // monospacedDigitSystemFont: mỗi chữ số chiếm cùng chiều rộng
        // → điểm số không nhảy vị trí khi thay đổi từ 0→10
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor(white: 0.60, alpha: 1)
        l.text = "X: 0   O: 0"
        return l
    }()

    // UIButton phát sự kiện khi chạm. setTitle/setImage cấu hình trạng thái .normal.
    // UIImage(systemName:) lấy biểu tượng SF Symbols, trả Optional nếu tên không tồn tại.
    // `titleLabel?.font` chỉ gán font khi titleLabel có giá trị, tránh ép mở Optional.
    // contentEdgeInsets tạo khoảng đệm trong nút; tintColor tô biểu tượng/chữ của nút.
    private lazy var historyButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle(" History", for: .normal)
        btn.setImage(UIImage(systemName: "clock.arrow.circlepath"), for: .normal)
        // `UIImage(systemName:)` = SF Symbols — thư viện icon sẵn có của Apple
        btn.tintColor = .white
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        // `titleLabel?` = optional chaining — chỉ truy cập nếu titleLabel != nil
        btn.backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.36, alpha: 1)
        btn.layer.cornerRadius = 14
        btn.contentEdgeInsets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        // UIEdgeInsets = padding bên trong button
        // Target–action: nút gửi sự kiện touchUpInside tới openHistory của self.
        // #selector tạo tham chiếu phương thức cho cơ chế runtime Objective-C của UIKit.
        // Vì vậy hàm nhận sự kiện bên dưới được đánh dấu @objc.
        btn.addTarget(self, action: #selector(openHistory), for: .touchUpInside)
        // addTarget: khi chạm (touchUpInside) → gọi hàm openHistory
        // `#selector(openHistory)` = tham chiếu đến hàm openHistory (Objective-C runtime)
        return btn
    }()

    private lazy var resetButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle(" New Game", for: .normal)
        btn.setImage(UIImage(systemName: "arrow.counterclockwise"), for: .normal)
        btn.tintColor = .white
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        btn.backgroundColor = UIColor(red: 0.18, green: 0.45, blue: 0.90, alpha: 1)
        btn.layer.cornerRadius = 14
        btn.contentEdgeInsets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        btn.addTarget(self, action: #selector(resetGame), for: .touchUpInside)
        return btn
    }()

    private lazy var hudSeparator: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 0.25, green: 0.25, blue: 0.38, alpha: 1)
        return v
    }()

    // MARK: - Trạng thái

    /// True khi game đã kết thúc — chặn input người dùng.
    private var gameEnded = false
    // roundID là UUID riêng của ván: dùng để bỏ callback trễ thuộc ván đã reset.
    private var roundID = UUID()

    /// Flag đảm bảo chỉ center board 1 lần duy nhất.
    private var didCenter = false

    // MARK: - Vòng đời ViewController

    // UIKit gọi viewDidLoad một lần cho mỗi lần view được tải, phù hợp để tạo UI
    // và gán callback. Không nên tự gọi hàm vòng đời này để làm mới màn hình.
    override func viewDidLoad() {
        super.viewDidLoad()  // luôn gọi super trước
        // Thứ tự: viewDidLoad → (layout) → viewDidLayoutSubviews → viewDidAppear
        setupUI()       // tạo và thêm các view
        setupGestures() // cài đặt nhận gesture chạm
        bindViewModel() // kết nối ViewModel với View
    }

    // Có thể được gọi nhiều lần sau bố trí/đổi kích thước. Lúc này bounds đã có số đo.
    // didCenter giúp căn giữa một lần, tránh đang cuộn mà bị kéo lại giữa bàn.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Hàm này được gọi sau khi Auto Layout hoàn tất tính toán kích thước.
        // Ở đây scrollView.bounds.width đã có giá trị chính xác.
        // → An toàn để tính offset centering.
        centerBoardIfNeeded()
    }

    // MARK: - Setup UI

    private func centerBoardIfNeeded() {
        // `guard !didCenter` = nếu đã center rồi thì thoát
        // `scrollView.bounds.width > 0` = chờ layout xong mới center
        guard !didCenter, scrollView.bounds.width > 0 else { return }
        didCenter = true

        // Scroll đến giữa canvas để người dùng bắt đầu từ trung tâm bàn cờ
        // Căn giữa viewport trong canvas: (kích thước canvas - viewport) / 2.
        // Điều này áp dụng lần đầu ở zoom mặc định 1.0.
        let offsetX = (canvasSize - scrollView.bounds.width)  / 2
        let offsetY = (canvasSize - scrollView.bounds.height) / 2
        scrollView.setContentOffset(CGPoint(x: offsetX, y: offsetY), animated: false)
        // setContentOffset = dịch chuyển vùng nhìn thấy của scrollView
        // Không animation (animated: false) để tức thì, không giật
    }

    // addSubview tạo cây giao diện; view được thêm sau nằm phía trên view trước.
    // HUD là thanh lượt/điểm/nút; separator là đường phân cách khỏi bàn cờ.
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.18, alpha: 1)

        // Thêm views vào hierarchy (thứ tự = thứ tự vẽ, sau cùng = trên cùng)
        view.addSubview(scrollView)     // bàn cờ (dưới cùng)
        scrollView.addSubview(boardView) // boardView là CON của scrollView
        scrollView.contentSize = CGSize(width: canvasSize, height: canvasSize)
        // contentSize = tổng kích thước nội dung cuộn được (6000×6000)
        // bounds      = kích thước vùng hiển thị (màn hình)

        view.addSubview(hudView)         // HUD phủ lên trên
        view.addSubview(hudSeparator)    // đường kẻ dưới HUD
        hudView.addSubview(turnIndicator)
        hudView.addSubview(turnLabel)
        hudView.addSubview(scoreLabel)
        hudView.addSubview(historyButton)
        hudView.addSubview(resetButton)

        // ─────────────────────────────────────────────────────────
        // 📖 KHÁI NIỆM: Auto Layout với NSLayoutConstraint
        // ─────────────────────────────────────────────────────────
        // Thay vì đặt frame tuyệt đối (x,y,width,height),
        // Auto Layout dùng constraint (ràng buộc) để xác định vị trí tương đối.
        //
        // Cú pháp: viewA.anchor.constraint(equalTo: viewB.anchor, constant: offset)
        // → "Cạnh trái của A cách cạnh trái của B 16pt"
        //
        // `NSLayoutConstraint.activate([...])` = bật một lúc nhiều constraint
        // ─────────────────────────────────────────────────────────
        let safeTop = view.safeAreaLayoutGuide.topAnchor
        // safeAreaLayoutGuide = vùng an toàn (tránh notch, Dynamic Island, status bar)

        // Auto Layout biểu diễn quan hệ giữa các cạnh, không gán x/y tuyệt đối:
        // leading/trailing: đầu/cuối theo hướng chữ; top/bottom: trên/dưới;
        // centerY: tâm dọc; width/height: kích thước. constant là khoảng cách theo point.
        // Safe Area tránh vùng status bar/notch; activate bật cả mảng constraint.
        // Ví dụ leading +16 đẩy vào từ trái; trailing -16 lùi vào từ phải.
        // intrinsicContentSize giúp UILabel/UIButton tự có kích thước theo nội dung.
        NSLayoutConstraint.activate([
            // HUD: từ topAnchor → chiều cao 100pt
            hudView.topAnchor.constraint(equalTo: view.topAnchor),
            hudView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hudView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hudView.bottomAnchor.constraint(equalTo: safeTop, constant: 66),

            // Đường kẻ: ngay dưới HUD, cao 1pt
            hudSeparator.topAnchor.constraint(equalTo: hudView.bottomAnchor),
            hudSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hudSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hudSeparator.heightAnchor.constraint(equalToConstant: 1),

            // ScrollView: từ đường kẻ → hết màn hình
            scrollView.topAnchor.constraint(equalTo: hudSeparator.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Chấm màu: 10×10pt, bên trái, giữa theo chiều dọc với turnLabel
            turnIndicator.widthAnchor.constraint(equalToConstant: 10),
            turnIndicator.heightAnchor.constraint(equalToConstant: 10),
            turnIndicator.leadingAnchor.constraint(equalTo: hudView.leadingAnchor, constant: 16),
            turnIndicator.centerYAnchor.constraint(equalTo: turnLabel.centerYAnchor),

            // Turn label: sát safeArea top + 10pt
            turnLabel.leadingAnchor.constraint(equalTo: turnIndicator.trailingAnchor, constant: 8),
            turnLabel.topAnchor.constraint(equalTo: safeTop, constant: 10),

            // Score label: ngay dưới turnLabel
            scoreLabel.leadingAnchor.constraint(equalTo: turnLabel.leadingAnchor),
            scoreLabel.topAnchor.constraint(equalTo: turnLabel.bottomAnchor, constant: 4),

            // Nút Reset: cạnh phải, giữa theo chiều dọc với HUD
            resetButton.trailingAnchor.constraint(equalTo: hudView.trailingAnchor, constant: -16),
            resetButton.centerYAnchor.constraint(equalTo: hudView.centerYAnchor, constant: 8),

            // Nút History: sát trái nút Reset
            historyButton.trailingAnchor.constraint(equalTo: resetButton.leadingAnchor, constant: -10),
            historyButton.centerYAnchor.constraint(equalTo: resetButton.centerYAnchor),
        ])
    }

    // Gesture recognizer nhận diện cử chỉ (tap) từ chuỗi sự kiện chạm cấp thấp.
    // boardTapped(_:) có một tham số; dấu : trong selector thể hiện điều đó.
    private func setupGestures() {
        // UITapGestureRecognizer nhận diện cử chỉ chạm (tap)
        let tap = UITapGestureRecognizer(target: self,
                                          action: #selector(boardTapped(_:)))
        // target: self = khi tap xảy ra, gọi method của ViewController này
        // action: #selector = tên method cần gọi
        boardView.addGestureRecognizer(tap)
    }

    // MARK: - Kết nối ViewModel với View (Binding)

    // Binding ở đây là tự gán closure, không phải @Binding của SwiftUI.
    // ARC quản lý vòng đời đối tượng bằng số tham chiếu mạnh. Nếu controller giữ
    // ViewModel và callback trong ViewModel giữ mạnh controller thì tạo vòng giữ nhau.
    // [weak self] làm closure giữ tham chiếu yếu; self có thể nil nếu màn hình đã đóng.
    // guard let self mở Optional và giữ đối tượng sống trong lần callback đang chạy.
    private func bindViewModel() {
        // ─────────────────────────────────────────────────────────
        // 📖 KHÁI NIỆM: [weak self] trong closure
        // ─────────────────────────────────────────────────────────
        // Vấn đề: closure giữ strong reference đến self (ViewController)
        //         ViewModel cũng giữ strong reference đến closure
        //         → ViewController ↔ ViewModel giữ nhau → MEMORY LEAK
        //         → Không bao giờ được giải phóng bộ nhớ!
        //
        // Giải pháp: `[weak self]` = closure chỉ giữ WEAK reference
        //            Nếu ViewController bị hủy → self = nil → không leak
        //
        // `guard let self = self` bên trong closure:
        //            Đảm bảo self vẫn còn tồn tại khi closure chạy
        // ─────────────────────────────────────────────────────────

        viewModel.onMovePlaced = { [weak self] coordinate, winLine in
            guard let self = self else { return }
            self.boardView.update(board: self.viewModel.board, winningLine: winLine)
            self.boardView.animatePlacement(at: coordinate)
            if let line = winLine {
                // Delay 150ms trước khi flash đường thắng
                // Lưu mã ván lúc lên lịch. asyncAfter không chặn UI, chỉ hẹn chạy sau.
                // Main queue dùng cho cập nhật giao diện. Tới lúc chạy, kiểm tra roundID
                // để không hiện hiệu ứng cũ trên một ván mới đã reset.
                let roundID = self.roundID
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                    guard let self = self, self.roundID == roundID else { return }
                    self.boardView.animateWin(line: line)
                }
                // DispatchQueue.main = Main Thread — mọi UI update PHẢI chạy trên main thread
                // asyncAfter = chạy sau một khoảng delay
            }
        }

        // Callback kết thúc cập nhật HUD ngay, rồi đợi 0.8 giây cho hiệu ứng thắng.
        // Nếu đã chuyển ván hoặc đang có một màn hình/modal khác, bỏ hộp thoại trễ.
        viewModel.onGameEnded = { [weak self] result in
            guard let self = self else { return }
            self.gameEnded = true
            self.updateHUD()
            let roundID = self.roundID
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                guard let self = self, self.roundID == roundID,
                      self.presentedViewController == nil else { return }
                self.showResultAlert(result: result)
            }
        }

        viewModel.onScoreUpdated = { [weak self] in
            self?.updateHUD()
            // `self?` = optional chaining — nếu self đã bị hủy (nil) thì bỏ qua
        }
    }

    // MARK: - Actions (Hành động người dùng)

    /// Được gọi khi người dùng chạm vào bàn cờ.
    // @objc cho phép target–action của UIKit gọi phương thức Swift này.
    // Lấy điểm trong hệ tọa độ boardView, kiểm tra nằm trong canvas, đổi thành ô,
    // nhờ ViewModel thử đặt. ViewModel vẫn tự kiểm tra hợp lệ độc lập với View.
    @objc private func boardTapped(_ gesture: UITapGestureRecognizer) {
        // `@objc` bắt buộc vì `#selector` dùng Objective-C runtime
        guard !gameEnded else { return }  // chặn input khi game kết thúc
        
        let point = gesture.location(in: boardView)
        // location(in:) = vị trí tap trong hệ tọa độ của boardView
        
        guard boardView.bounds.contains(point) else { return }
        let coordinate = boardView.coordinate(for: point)
        viewModel.place(at: coordinate)  // ViewModel xử lý logic
        updateHUD()                      // View cập nhật giao diện
    }

    @objc private func resetGame() {
        gameEnded = false
        roundID = UUID()
        viewModel.resetGame()        // ViewModel reset logic
        boardView.update(board: [:], winningLine: nil)
        // forEach chạy closure cho từng layer con; $0 là tham số đầu viết tắt.
        // Dọn hiệu ứng tạm, còn nội dung tile được yêu cầu vẽ lại bởi update.
        boardView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        updateHUD()
    }

    // Truyền cùng ViewModel vào History để đọc/xóa cùng kho dữ liệu.
    // UINavigationController bọc màn hình để có navigation bar với nút đóng/xóa.
    // present mở modal trên màn hình hiện tại; .pageSheet là giao diện dạng tấm trượt.
    @objc private func openHistory() {
        // Tạo HistoryViewController và bọc trong NavigationController
        let vc  = HistoryViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: vc)
        // UINavigationController = container có thanh navigation bar ở trên
        
        nav.modalPresentationStyle = .pageSheet
        // pageSheet = hiển thị từ dưới lên, che một phần màn hình (giống bottom sheet)

        // `if #available(iOS 15.0, *)` = kiểm tra phiên bản iOS
        // Đây là cách Swift xử lý API mới mà thiết bị cũ không có
        // Kiểm tra phiên bản lúc chạy: chỉ dùng API sheet mới trên iOS 15 trở lên.
        // * cho biết các nền tảng khác không bị giới hạn bởi điều kiện iOS này.
        // detents là các mức cao được phép: medium (một phần) và large (gần toàn màn hình).
        if #available(iOS 15.0, *) {
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                // detents = các vị trí dừng của sheet (nửa màn hình / toàn màn hình)
                sheet.prefersGrabberVisible = true  // hiển thị thanh kéo ở trên
            }
        }
        present(nav, animated: true)  // hiển thị modal (từ dưới trượt lên)
    }

    // MARK: - Cập nhật HUD

    // UIView.animate nhận closure mô tả giá trị cuối; UIKit nội suy thay đổi hỗ trợ.
    // `"\(biểu_thức)"` là string interpolation: chèn giá trị vào một chuỗi.
    private func updateHUD() {
        if gameEnded {
            turnLabel.text = "Game Over"
            UIView.animate(withDuration: 0.2) {
                self.turnIndicator.backgroundColor = UIColor(white: 0.5, alpha: 1)
            }
            // UIView.animate = animation đơn giản với thời gian và closure thay đổi UI
        } else {
            let player = viewModel.currentPlayer
            turnLabel.text = "\(player.symbol)'s Turn"
            // `\(...)` = String Interpolation — nhúng giá trị vào chuỗi
            // Tương tự template literal trong JS: `${player.symbol}'s Turn`
            
            UIView.animate(withDuration: 0.2) {
                self.turnIndicator.backgroundColor = player.color
            }
        }
        scoreLabel.text = "X: \(viewModel.crossScore)   O: \(viewModel.noughtScore)"
    }

    // MARK: - Alert kết quả

    // UIAlertController hiển thị kết quả. rawValue của MatchResult là chữ X/O Wins.
    // UIAlertAction là nút trong hộp thoại; closure chạy khi người dùng chọn nút.
    // `_` trong closure nghĩa bỏ qua tham số action vì không cần dùng nó.
    private func showResultAlert(result: MatchResult) {
        // UIAlertController = hộp thoại thông báo của iOS
        let alert = UIAlertController(
            title: result.rawValue,
            message: "Total moves: \(viewModel.totalMoves)",
            preferredStyle: .alert)  // .alert = popup giữa màn hình

        // Thêm các nút vào alert
        alert.addAction(UIAlertAction(title: "New Game", style: .default) { [weak self] _ in
            self?.resetGame()
            // `_` = bỏ qua tham số (UIAlertAction truyền vào nhưng ta không cần)
        })
        alert.addAction(UIAlertAction(title: "View History", style: .default) { [weak self] _ in
            self?.resetGame()
            self?.openHistory()
        })
        present(alert, animated: true)  // hiển thị alert
    }
}

// ─────────────────────────────────────────────────────────────────
// 📖 KHÁI NIỆM: Extension
// ─────────────────────────────────────────────────────────────────
// `extension` = mở rộng thêm tính năng cho một type, ngay cả type của người khác
// Ở đây: thêm UIScrollViewDelegate methods vào GameViewController
// Lý do: giữ code có tổ chức, nhóm code theo chức năng
// ─────────────────────────────────────────────────────────────────

// Extension này khai báo controller tuân thủ UIScrollViewDelegate.
// Khi pinch, scroll view hỏi view nào được phóng/thu; trả boardView để zoom canvas.
// Giá trị UIView? cho phép delegate khác trả nil nếu không hỗ trợ zoom.
extension GameViewController: UIScrollViewDelegate {
    /// Trả về view nào sẽ bị scale khi zoom — chính là bàn cờ.
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        // UIScrollViewDelegate là Protocol — Swift yêu cầu implement các method này
        // Protocol giống Interface trong Java/TypeScript
        return boardView
    }
}
