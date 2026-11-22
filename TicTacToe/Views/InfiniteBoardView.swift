import UIKit

/// A large tiled canvas. UIScrollView handles panning and pinch-to-zoom.
// UIView là một vùng giao diện; ở đây ta tự vẽ thay vì dùng hàng nghìn UIButton.
// Tên InfiniteBoardView là tên lớp; canvas thực tế hiện là 6000×6000pt (125×125 ô).
final class InfiniteBoardView: UIView {
    // `override` thay cách lớp cha thực hiện một thuộc tính/hàm.
    // Mỗi UIView có CALayer phía dưới để hiển thị nội dung. layerClass chọn loại layer.
    // CATiledLayer chia mặt vẽ thành tile và có thể vẽ tile trên nhiều luồng nền.
    // AnyClass mô tả một kiểu class; CATiledLayer.self là kiểu, không phải instance.
    override class var layerClass: AnyClass { CATiledLayer.self }

    // CGFloat là kiểu số thực UIKit/Core Graphics sử dụng cho kích thước, tọa độ.
    // Đơn vị là point, khác pixel: màn hình 3× có 3 pixel trên mỗi point mỗi chiều.
    // cellSize được cấu hình trước khi vẽ; app hiện không thay nó trong lúc render.
    var cellSize: CGFloat = 48

    // CATiledLayer may draw tiles concurrently. Readers take a value snapshot
    // under the same lock used by the main-thread writer, then render unlocked.
    // struct là kiểu giá trị. RenderState gom bàn cờ và các ô thắng thành một trạng thái.
    // Set<Coordinate> chứa ô thắng không trùng nhau, tra cứu contains trung bình O(1).
    private struct RenderState {
        var board: [Coordinate: Player] = [:]
        var winners: Set<Coordinate> = []
    }
    // NSLock bảo vệ dữ liệu dùng chung: chỉ một luồng được vào vùng đã khóa mỗi lúc.
    // Main thread cập nhật state; các luồng render lấy snapshot từ cùng state này.
    // UIColor dùng cho UIKit; .cgColor chuyển sang CGColor cho Core Graphics.
    // alpha là độ đục: 0 trong suốt, 1 hoàn toàn đục.
    private let stateLock = NSLock()
    private var state = RenderState()
    private let background = UIColor(red: 0.11, green: 0.11, blue: 0.18, alpha: 1).cgColor
    private let grid = UIColor(red: 0.32, green: 0.32, blue: 0.48, alpha: 1).cgColor
    private let accent = UIColor(red: 0.40, green: 0.40, blue: 0.60, alpha: 1).cgColor
    private let highlight = UIColor(red: 1, green: 0.84, blue: 0, alpha: 0.3).cgColor
    private let crossColor = Player.cross.color.cgColor
    private let noughtColor = Player.nought.color.cgColor
    private let winnerColor = UIColor(red: 1, green: 0.7, blue: 0.1, alpha: 1).cgColor

    // Hai đường khởi tạo UIView: bằng code (frame) hoặc giải mã giao diện (coder).
    // `super` là phần triển khai của lớp cha; khởi tạo lớp cha rồi cấu hình lớp con.
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    // required yêu cầu lớp con tiếp tục cung cấp initializer này nếu cần.
    // Dấu ? sau init nghĩa khởi tạo có thể thất bại (trả nil). NSCoder là bộ giải mã,
    // thường xuất hiện khi UIKit tải một view từ Storyboard/XIB.
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = UIColor(cgColor: background)
        // Vì draw tô kín nền nên khai báo opaque là phù hợp: không cần trong suốt.
        isOpaque = true
        // `as!` ép kiểu bắt buộc, sẽ crash nếu sai kiểu. Ở đây layerClass đã
        // quyết định layer là CATiledLayer. Cấu hình detail hỗ trợ nhiều mức zoom.
        // tileSize của CATiledLayer dùng đơn vị pixel, không phải kích thước ô cờ.
        let tiles = layer as! CATiledLayer
        tiles.levelsOfDetail = 4
        tiles.levelsOfDetailBias = 2
        tiles.tileSize = CGSize(width: 256, height: 256)
    }

    /// Publish board and win highlight together, avoiding partially updated tiles.
    // Hàm được ViewController gọi sau mỗi nước. Cập nhật board và winners cùng lúc.
    // winningLine ?? []: nếu Optional nil thì dùng mảng rỗng trước khi đổi thành Set.
    func update(board: [Coordinate: Player], winningLine: [Coordinate]?) {
        stateLock.lock()
        state = RenderState(board: board, winners: Set(winningLine ?? []))
        stateLock.unlock()
        // Đề nghị hệ thống vẽ lại khi có thể; không gọi draw trực tiếp từ đây.
        // Đã unlock để luồng vẽ có thể đọc trạng thái, không bị giữ khóa trong lúc vẽ.
        setNeedsDisplay()
    }

    // UIKit/CATiledLayer cung cấp rect cần vẽ và một context: xem như bộ công cụ vẽ.
    // CGRect chứa gốc x/y cùng chiều rộng/cao; rect ở đây là vùng tile được yêu cầu.
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        stateLock.lock()
        // Lấy một bản giá trị nhất quán rồi nhả khóa sớm. Dictionary có copy-on-write:
        // có thể chia sẻ vùng nhớ khi chưa sửa; nếu một bản sửa thì tách dữ liệu cần thiết.
        // Khóa vẫn cần để đồng bộ thao tác đọc/ghi state giữa các luồng.
        let snapshot = state
        stateLock.unlock()
        let size = cellSize
        guard size > 0 else { return }
        ctx.setFillColor(background)
        ctx.fill(rect)

        // Đổi giới hạn theo point sang chỉ số ô: x/cellSize → cột, y/cellSize → hàng.
        // floor làm tròn xuống, ceil làm tròn lên để phủ cả ô cắt qua mép tile.
        // Int(...) chuyển số thực thành số nguyên dùng làm chỉ số.
        let firstCol = Int(floor(rect.minX / size))
        let lastCol = Int(ceil(rect.maxX / size))
        let firstRow = Int(floor(rect.minY / size))
        let lastRow = Int(ceil(rect.maxY / size))
        guard firstCol <= lastCol, firstRow <= lastRow else { return }

        // a...b gồm cả a và b; khác a..<b không gồm b.
        // `%` là phần dư: cứ mỗi 5 ô thì nét lưới dùng màu accent sáng hơn.
        // move đặt đầu bút, addLine tạo đường, strokePath tô nét đường đã tạo.
        for col in firstCol...lastCol {
            ctx.setStrokeColor(col % 5 == 0 ? accent : grid)
            ctx.setLineWidth(col % 5 == 0 ? 1 : 0.8)
            ctx.move(to: CGPoint(x: CGFloat(col) * size, y: rect.minY))
            ctx.addLine(to: CGPoint(x: CGFloat(col) * size, y: rect.maxY))
            ctx.strokePath()
        }
        for row in firstRow...lastRow {
            ctx.setStrokeColor(row % 5 == 0 ? accent : grid)
            ctx.setLineWidth(row % 5 == 0 ? 1 : 0.8)
            ctx.move(to: CGPoint(x: rect.minX, y: CGFloat(row) * size))
            ctx.addLine(to: CGPoint(x: rect.maxX, y: CGFloat(row) * size))
            ctx.strokePath()
        }

        // Look up only cells intersecting this tile. Rendering cost does not
        // grow with the number of occupied cells elsewhere on the canvas.
        // Chỉ kiểm tra các ô giao vùng tile, không duyệt mọi quân trên toàn bàn.
        // guard let lấy quân trong snapshot; continue bỏ qua ô trống và sang ô kế.
        // Tọa độ trên mặt vẽ: x = cột × kích thước ô, y = hàng × kích thước ô.
        for row in firstRow...lastRow {
            for col in firstCol...lastCol {
                let coordinate = Coordinate(row: row, col: col)
                guard let player = snapshot.board[coordinate] else { continue }
                let cell = CGRect(x: CGFloat(col) * size, y: CGFloat(row) * size,
                                  width: size, height: size)
                let winning = snapshot.winners.contains(coordinate)
                if winning {
                    ctx.setFillColor(highlight)
                    ctx.fill(cell)
                }
                ctx.setStrokeColor(winning ? winnerColor : (player == .cross ? crossColor : noughtColor))
                ctx.setLineWidth(max(size * 0.1, 2.5))
                ctx.setLineCap(.round)
                // insetBy thu nhỏ hình chữ nhật để quân không chạm đường lưới.
                // X gồm hai đường chéo; O là ellipse trong khung vuông nên thành hình tròn.
                // max(..., 2.5) giữ độ dày nét tối thiểu; lineCap.round làm đầu nét tròn.
                let inset = cell.insetBy(dx: size * 0.2, dy: size * 0.2)
                if player == .cross {
                    ctx.move(to: CGPoint(x: inset.minX, y: inset.minY))
                    ctx.addLine(to: CGPoint(x: inset.maxX, y: inset.maxY))
                    ctx.move(to: CGPoint(x: inset.maxX, y: inset.minY))
                    ctx.addLine(to: CGPoint(x: inset.minX, y: inset.maxY))
                    ctx.strokePath()
                } else {
                    ctx.strokeEllipse(in: inset)
                }
            }
        }
    }

    // MARK: - Helper tọa độ

    /// Chuyển điểm chạm (point trong view) → tọa độ ô cờ.
    // UITapGestureRecognizer trả điểm đã quy về hệ tọa độ boardView,
    // nên công thức này vẫn dùng được khi scroll view đang pan/zoom.
    // Ví dụ x=120,y=70, cellSize=48 → cột 2, hàng 1 (chỉ số bắt đầu từ 0).
    func coordinate(for point: CGPoint) -> Coordinate {
        // Chia lấy phần nguyên (floor) → xác định ô nào
        let col = Int(floor(point.x / cellSize))
        let row = Int(floor(point.y / cellSize))
        return Coordinate(row: row, col: col)
    }

    /// Tính điểm tâm của một ô cờ (dùng cho animation).
    // Tâm ô bằng tọa độ góc trái trên cộng nửa kích thước ô ở cả x lẫn y.
    func centerPoint(for coordinate: Coordinate) -> CGPoint {
        let x = CGFloat(coordinate.col) * cellSize + cellSize / 2
        let y = CGFloat(coordinate.row) * cellSize + cellSize / 2
        return CGPoint(x: x, y: y)
    }

    // MARK: - Animation khi đặt quân

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: CALayer Animation
    // ─────────────────────────────────────────────────────────────
    // Trong iOS, animation có 2 cách:
    // 1. UIView.animate { ... }    — đơn giản, dùng cho UIView properties
    // 2. CAAnimation               — mạnh hơn, cho phép keyframe, path...
    //
    // CALayer = lớp phía dưới của UIView, thực sự render trên GPU.
    // Thêm layer tạm vào → animate → xóa khi xong.
    // ─────────────────────────────────────────────────────────────

    /// Hiệu ứng bounce khi đặt quân.
    // Animation dùng layer phụ, không sửa dữ liệu board và không quyết định lượt.
    // frame định vị layer; cornerRadius làm góc bo thành vòng tròn với khung vuông.
    // opacity=0 là trạng thái thật sau hiệu ứng; CAAnimation chỉ đổi cách hiển thị.
    func animatePlacement(at coordinate: Coordinate) {
        let center = centerPoint(for: coordinate)
        let size   = cellSize * 0.85

        // Tạo layer tạm (vòng tròn sáng)
        let ring = CALayer()
        ring.frame        = CGRect(x: center.x - size/2, y: center.y - size/2,
                                   width: size, height: size)
        ring.cornerRadius = size / 2
        ring.borderColor  = UIColor.white.withAlphaComponent(0.5).cgColor
        ring.borderWidth  = 2
        ring.opacity      = 0
        layer.addSublayer(ring)  // thêm vào layer của view này

        // Animation scale: 0.3 → 1.4 → 0.85 → 1.0 (bounce effect)
        // keyPath chỉ thuộc tính sẽ animate. values là các mốc độ lớn,
        // keyTimes là mốc thời gian chuẩn hóa 0...1 trong duration (giây).
        let scaleAnim      = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnim.values   = [0.3, 1.4, 0.85, 1.0]  // các giá trị keyframe
        scaleAnim.keyTimes = [0,   0.5, 0.75, 1.0]  // thời điểm tương ứng (0-1)
        scaleAnim.duration = 0.4  // tổng thời gian (giây)

        // Animation opacity: mờ dần
        let opacAnim       = CABasicAnimation(keyPath: "opacity")
        opacAnim.fromValue = 0.8
        opacAnim.toValue   = 0.0
        opacAnim.duration  = 0.4

        // CATransaction = nhóm animation lại, có thể đặt completion block
        // Nhóm thay đổi animation; completion được gọi khi nhóm hoàn tất.
        // removeFromSuperlayer dọn layer tạm để không tích lũy sau nhiều nước.
        CATransaction.begin()
        CATransaction.setCompletionBlock { ring.removeFromSuperlayer() }
        // `{ ring.removeFromSuperlayer() }` = closure — xóa layer tạm sau khi xong
        ring.add(scaleAnim, forKey: "scale")
        ring.add(opacAnim,  forKey: "opacity")
        CATransaction.commit()  // bắt đầu chạy animation
    }

    /// Hiệu ứng flash vàng cho đường thắng.
    // enumerated() trả cả thứ tự i và phần tử coord của mảng.
    // Mỗi ô bắt đầu muộn hơn 0.05 giây để tạo hiệu ứng lan dọc đường thắng.
    // fillMode.forwards + isRemovedOnCompletion=false giữ hình ảnh cuối animation;
    // completion sẽ xóa layer phụ khi xong, còn màu thắng thật vẫn do draw hiển thị.
    func animateWin(line: [Coordinate]) {
        // `enumerated()` = loop kèm theo index
        // Ví dụ: [(0, coord0), (1, coord1), (2, coord2), ...]
        for (i, coord) in line.enumerated() {
            let center = centerPoint(for: coord)
            let size   = cellSize * 0.85
            let flash  = CALayer()
            flash.frame           = CGRect(x: center.x - size/2, y: center.y - size/2,
                                           width: size, height: size)
            flash.cornerRadius    = size / 2
            flash.backgroundColor = UIColor(red: 1, green: 0.84, blue: 0, alpha: 0.7).cgColor
            layer.addSublayer(flash)

            let pulse                    = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue              = 0.9
            pulse.toValue                = 0.0
            pulse.duration               = 0.7
            pulse.beginTime              = CACurrentMediaTime() + Double(i) * 0.05
            // `beginTime` = delay — mỗi ô thắng flash sau nhau 50ms → hiệu ứng gợn sóng
            pulse.fillMode               = .forwards  // giữ trạng thái cuối sau khi xong
            pulse.isRemovedOnCompletion  = false

            CATransaction.begin()
            CATransaction.setCompletionBlock { flash.removeFromSuperlayer() }
            flash.add(pulse, forKey: "pulse")
            CATransaction.commit()
        }
    }
}
