//
//  InfiniteBoardView.swift
//  TicTacToe
//
//  📌 MỤC ĐÍCH: Vẽ bàn cờ vô hạn bằng CoreGraphics.
//  Được tối ưu với CATiledLayer — chỉ vẽ phần đang nhìn thấy → 60fps.
//
//  ─────────────────────────────────────────────────────────────────
//  📖 LUỒNG RENDER trong iOS:
//  ─────────────────────────────────────────────────────────────────
//  UIView  →  CALayer  →  GPU  →  Màn hình
//   ↑              ↑
//  Code của    Backing layer (mặc định là CALayer)
//  chúng ta    Chúng ta thay bằng CATiledLayer để xử lý canvas lớn
//  ─────────────────────────────────────────────────────────────────
//

import UIKit  // UIKit bao gồm UIView, UIColor, CGRect, CGPoint...

// ─────────────────────────────────────────────────────────────────
// 📖 KHÁI NIỆM: `final class` kế thừa từ `UIView`
// ─────────────────────────────────────────────────────────────────
// `UIView` là class cơ bản của mọi phần tử giao diện trong UIKit.
// Bằng cách kế thừa (`class InfiniteBoardView: UIView`), ta có được:
// - Tất cả tính năng sẵn có: frame, bounds, backgroundColor, addSubview...
// - Và có thể OVERRIDE (ghi đè) các hàm như draw() để vẽ tùy chỉnh
// ─────────────────────────────────────────────────────────────────
final class InfiniteBoardView: UIView {

    // MARK: - Ghi đè backing layer

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: Type Property + Override
    // ─────────────────────────────────────────────────────────────
    // `override class var layerClass` = ghi đè thuộc tính STATIC của class
    // `layerClass` là thuộc tính trong UIView — quy định loại CALayer dùng.
    //
    // CATiledLayer là đặc biệt:
    //   - Chia canvas lớn thành nhiều "tile" (ô vuông nhỏ 256×256pt)
    //   - Mỗi tile được render trên thread riêng → không block UI
    //   - Chỉ render tile đang VISIBLE → tiết kiệm tài nguyên
    //
    // Nếu không dùng CATiledLayer, canvas 6000×6000pt sẽ KHÔNG render được!
    // ─────────────────────────────────────────────────────────────
    override class var layerClass: AnyClass {
        return CATiledLayer.self
        // `AnyClass` = kiểu đại diện cho bất kỳ class nào
        // `CATiledLayer.self` = bản thân class CATiledLayer (không phải instance)
    }

    /// Tiện ích để truy cập layer đã được cast sang CATiledLayer.
    private var tiledLayer: CATiledLayer {
        // ─────────────────────────────────────────────────────────
        // 📖 KHÁI NIỆM: Type Casting (`as!`)
        // ─────────────────────────────────────────────────────────
        // `layer` là `CALayer` theo kiểu Swift (từ UIView)
        // `as! CATiledLayer` = ép kiểu (force cast) — ta CHẮC nó là CATiledLayer
        // `as!` có thể crash nếu kiểu sai — nhưng ở đây an toàn vì ta đã
        // override layerClass trả về CATiledLayer.
        // Nếu không chắc → dùng `as? CATiledLayer` (optional, không crash)
        // ─────────────────────────────────────────────────────────
        return layer as! CATiledLayer
    }

    // MARK: - Cấu hình

    /// Kích thước mỗi ô cờ (điểm — point, không phải pixel).
    // 📖 Note: Point ≠ Pixel. Trên màn hình Retina (3x), 1pt = 3px.
    // Ta làm việc với point — iOS tự lo việc scale lên pixel.
    var cellSize: CGFloat = 48
    // `CGFloat` = kiểu số thực dùng trong CoreGraphics (khác Float/Double)
    // Dùng CGFloat cho mọi tính toán liên quan đến tọa độ/kích thước UI.

    // MARK: - Dữ liệu bàn cờ

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: Property Observer (didSet)
    // ─────────────────────────────────────────────────────────────
    // `didSet` = đoạn code chạy TỰ ĐỘNG sau mỗi lần thuộc tính thay đổi giá trị.
    // Tương tự computed setter, nhưng đơn giản hơn.
    //
    // Ứng dụng ở đây: bất cứ khi nào bàn cờ thay đổi,
    // tự động gọi setNeedsDisplay() để iOS vẽ lại view.
    //
    // `setNeedsDisplay()` = đánh dấu "view này cần vẽ lại"
    // iOS không vẽ ngay — nó gom các request lại và vẽ 1 lần
    // trước frame tiếp theo (60fps = mỗi ~16ms vẽ 1 lần).
    // ─────────────────────────────────────────────────────────────

    /// Dictionary lưu bàn cờ: key = tọa độ, value = người chơi.
    var board: [Coordinate: Player] = [:] {
        didSet { setNeedsDisplay() }  // tự động vẽ lại khi board thay đổi
    }

    /// Tọa độ các ô thắng (highlight màu vàng).
    var winningLine: [Coordinate]? = nil {
        didSet { setNeedsDisplay() }
    }
    // `[Coordinate]?` = Optional Array — có thể nil (chưa có đường thắng)

    // MARK: - Màu sắc

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: `private let` — hằng số private
    // ─────────────────────────────────────────────────────────────
    // `private` = chỉ dùng được trong file này
    // `let`     = không thể thay đổi sau khi gán
    // Màu sắc thường không đổi → dùng let
    // ─────────────────────────────────────────────────────────────
    private let bgColor     = UIColor(red: 0.11, green: 0.11, blue: 0.18, alpha: 1)
    private let gridColor   = UIColor(red: 0.32, green: 0.32, blue: 0.48, alpha: 1)
    private let accentColor = UIColor(red: 0.40, green: 0.40, blue: 0.60, alpha: 1)
    private let winBgColor  = UIColor(red: 1.0,  green: 0.84, blue: 0.0,  alpha: 0.30)

    // MARK: - Khởi tạo

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: Hai loại initializer bắt buộc khi kế thừa UIView
    // ─────────────────────────────────────────────────────────────
    // 1. `init(frame:)` — dùng khi tạo view bằng code:
    //    let view = InfiniteBoardView(frame: CGRect(...))
    //
    // 2. `required init?(coder:)` — dùng khi load từ Storyboard/XIB.
    //    Ta không dùng Storyboard nhưng Swift/UIKit vẫn BẮT BUỘC phải có.
    //    `required` = mọi subclass đều phải implement cái này.
    //    `?` sau init = failable initializer (có thể trả nil nếu thất bại).
    // ─────────────────────────────────────────────────────────────
    override init(frame: CGRect) {
        super.init(frame: frame)  // gọi init của class cha (UIView)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    /// Cấu hình chung cho cả 2 init — tránh lặp code.
    private func setup() {
        backgroundColor = bgColor  // màu nền view
        isOpaque = true            // view đục hoàn toàn → iOS bỏ qua alpha blend → nhanh hơn

        // Cấu hình CATiledLayer
        tiledLayer.levelsOfDetail     = 4  // số mức zoom được cache
        tiledLayer.levelsOfDetailBias = 2  // ưu tiên zoom-in hơn zoom-out
        tiledLayer.tileSize = CGSize(width: 256, height: 256)
        // Mỗi tile 256×256pt — iOS render từng tile riêng trên background thread
    }

    // MARK: - Vẽ (draw) — được gọi bởi CATiledLayer cho từng tile

    // ─────────────────────────────────────────────────────────────
    // 📖 KHÁI NIỆM: Override draw(_ rect:)
    // ─────────────────────────────────────────────────────────────
    // Đây là hàm VẼ chính của UIView. Gọi nó trực tiếp là SAI.
    // Thay vào đó: gọi setNeedsDisplay() → iOS tự gọi draw() đúng lúc.
    //
    // `rect` = vùng cần vẽ (dirty rect) — có thể nhỏ hơn bounds.
    // CATiledLayer gọi draw() với rect = kích thước 1 tile (256×256pt).
    // → Chỉ vẽ những gì nằm trong rect đó → hiệu quả!
    //
    // `CGRect` = hình chữ nhật: { x, y, width, height }
    // ─────────────────────────────────────────────────────────────
    override func draw(_ rect: CGRect) {
        // Lấy Context đồ họa hiện tại — là "bút vẽ" của CoreGraphics
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        // `guard let` = thoát sớm nếu context nil (rất hiếm xảy ra)

        drawBackground(ctx: ctx, rect: rect)  // vẽ nền
        drawGrid(ctx: ctx, rect: rect)        // vẽ lưới ô cờ
        drawPieces(ctx: ctx, rect: rect)      // vẽ quân X và O
    }

    // MARK: - Vẽ nền

    private func drawBackground(ctx: CGContext, rect: CGRect) {
        bgColor.setFill()  // đặt màu fill
        ctx.fill(rect)     // tô màu vùng rect
    }

    // MARK: - Vẽ lưới

    private func drawGrid(ctx: CGContext, rect: CGRect) {
        // ─────────────────────────────────────────────────────────
        // Tính phạm vi hàng/cột CẦN VẼ trong tile này
        // Chỉ vẽ những đường nằm trong rect → tối ưu
        // ─────────────────────────────────────────────────────────
        let startCol = Int(floor(rect.minX / cellSize))  // cột đầu tiên
        let endCol   = Int(ceil(rect.maxX  / cellSize))  // cột cuối cùng
        let startRow = Int(floor(rect.minY / cellSize))
        let endRow   = Int(ceil(rect.maxY  / cellSize))

        // `guard` bảo vệ tránh crash khi range rỗng
        guard startCol <= endCol, startRow <= endRow else { return }

        let boardWidth  = bounds.width   // tổng chiều rộng canvas (6000pt)
        let boardHeight = bounds.height  // tổng chiều cao canvas (6000pt)

        // Vẽ đường DỌCLEFT (vertical lines)
        for col in startCol...endCol {
            let x = CGFloat(col) * cellSize  // vị trí x của đường này
            
            // Cứ mỗi 5 cột: vẽ đường sáng hơn (như bàn cờ Go)
            let isAccent = (col % 5 == 0)   // `%` = chia lấy dư (modulo)
            ctx.setStrokeColor(isAccent ? accentColor.cgColor : gridColor.cgColor)
            // `condition ? a : b` = toán tử 3 ngôi (ternary)
            // `.cgColor` = chuyển UIColor → CGColor (CoreGraphics dùng CGColor)
            
            ctx.setLineWidth(isAccent ? 1.0 : 0.8)
            ctx.move(to:    CGPoint(x: x, y: 0))           // điểm đầu
            ctx.addLine(to: CGPoint(x: x, y: boardHeight)) // điểm cuối
            ctx.strokePath()  // vẽ đường (stroke = đường viền, fill = tô màu)
        }

        // Vẽ đường NGANG (horizontal lines)
        for row in startRow...endRow {
            let y = CGFloat(row) * cellSize
            let isAccent = (row % 5 == 0)
            ctx.setStrokeColor(isAccent ? accentColor.cgColor : gridColor.cgColor)
            ctx.setLineWidth(isAccent ? 1.0 : 0.8)
            ctx.move(to:    CGPoint(x: 0,          y: y))
            ctx.addLine(to: CGPoint(x: boardWidth,  y: y))
            ctx.strokePath()
        }

        // Vẽ dấu chấm ở giao điểm (star points — như bàn Go)
        let centerCol = Int(bounds.width  / 2 / cellSize)
        let centerRow = Int(bounds.height / 2 / cellSize)

        // Mảng tuple: 9 vị trí star point xung quanh trung tâm
        let starOffsets: [(Int, Int)] = [
            (-5,-5), (0,-5), (5,-5),
            (-5, 0), (0, 0), (5, 0),
            (-5, 5), (0, 5), (5, 5)
        ]

        for (dc, dr) in starOffsets {
            // ─────────────────────────────────────────────────────
            // 📖 KHÁI NIỆM: Tuple Destructuring
            // ─────────────────────────────────────────────────────
            // `for (dc, dr) in starOffsets` = loop và "giải nén" tuple
            // Mỗi phần tử (Int, Int) → gán thành dc và dr
            // Tương tự JavaScript: for (const [dc, dr] of starOffsets)
            // ─────────────────────────────────────────────────────
            let sx = CGFloat(centerCol + dc) * cellSize
            let sy = CGFloat(centerRow + dr) * cellSize
            if rect.insetBy(dx: -6, dy: -6).contains(CGPoint(x: sx, y: sy)) {
                drawStarDot(ctx: ctx, x: sx, y: sy, r: 3)
            }
        }
    }

    /// Vẽ chấm tròn nhỏ tại (x, y) với bán kính r.
    private func drawStarDot(ctx: CGContext, x: CGFloat, y: CGFloat, r: CGFloat) {
        ctx.setFillColor(accentColor.cgColor)
        // CGRect(x:y:width:height) định nghĩa hình chữ nhật bao quanh hình ellipse
        ctx.fillEllipse(in: CGRect(x: x-r, y: y-r, width: r*2, height: r*2))
    }

    // MARK: - Vẽ quân cờ

    private func drawPieces(ctx: CGContext, rect: CGRect) {
        // Chuyển winningLine (Array?) sang Set để tra cứu O(1)
        // Set = tập hợp không thứ tự, tra cứu nhanh hơn Array O(n)
        let winSet: Set<Coordinate> = winningLine.map { Set($0) } ?? []
        // `.map { Set($0) }` = nếu winningLine != nil, chuyển array → Set
        // `?? []` = nếu nil, dùng Set rỗng

        // Phạm vi tọa độ cần xét (chỉ những ô trong tile này + buffer)
        let startCol = Int(floor(rect.minX / cellSize)) - 1
        let endCol   = Int(ceil(rect.maxX  / cellSize)) + 1
        let startRow = Int(floor(rect.minY / cellSize)) - 1
        let endRow   = Int(ceil(rect.maxY  / cellSize)) + 1

        // Duyệt qua tất cả quân trên bàn (chỉ ô có quân mới có trong dict)
        for (coord, player) in board {
            // Bỏ qua ô nằm ngoài vùng đang vẽ
            guard coord.col >= startCol, coord.col <= endCol,
                  coord.row >= startRow, coord.row <= endRow else { continue }
            // `continue` = bỏ qua iteration này, tiếp tục vòng lặp tiếp theo

            // Tính tâm điểm của ô này (giữa ô)
            let cx = CGFloat(coord.col) * cellSize + cellSize / 2
            let cy = CGFloat(coord.row) * cellSize + cellSize / 2
            let isWinner = winSet.contains(coord)  // ô này có nằm trong đường thắng không?

            if isWinner {
                // Vẽ nền vàng cho ô thắng
                let hlRect = CGRect(x: CGFloat(coord.col) * cellSize,
                                    y: CGFloat(coord.row) * cellSize,
                                    width: cellSize, height: cellSize)
                ctx.setFillColor(winBgColor.cgColor)
                ctx.fill(hlRect)
            }

            // Vẽ X hoặc O tùy theo người chơi
            switch player {
            case .cross:  drawCross(ctx: ctx, cx: cx, cy: cy, isWinner: isWinner)
            case .nought: drawNought(ctx: ctx, cx: cx, cy: cy, isWinner: isWinner)
            }
        }
    }

    /// Vẽ chữ X tại tâm (cx, cy).
    private func drawCross(ctx: CGContext, cx: CGFloat, cy: CGFloat, isWinner: Bool) {
        let color = isWinner
            ? UIColor(red: 1.0, green: 0.7, blue: 0.1, alpha: 1)  // vàng khi thắng
            : Player.cross.color                                     // đỏ bình thường

        let margin:    CGFloat = cellSize * 0.20  // khoảng cách từ mép ô đến đầu nét
        let lineWidth: CGFloat = max(cellSize * 0.13, 2.5)
        // `max(a, b)` = lấy giá trị lớn hơn — đảm bảo nét đủ dày dù cellSize nhỏ
        
        let half = cellSize / 2 - margin  // độ dài nửa nét từ tâm

        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineCap(.round)  // đầu nét bo tròn → trông đẹp hơn

        // Nét chéo \ (từ trái-trên đến phải-dưới)
        ctx.move(to:    CGPoint(x: cx - half, y: cy - half))
        ctx.addLine(to: CGPoint(x: cx + half, y: cy + half))

        // Nét chéo / (từ phải-trên đến trái-dưới)
        ctx.move(to:    CGPoint(x: cx + half, y: cy - half))
        ctx.addLine(to: CGPoint(x: cx - half, y: cy + half))

        ctx.strokePath()  // thực sự vẽ 2 nét vừa định nghĩa
    }

    /// Vẽ chữ O (hình tròn) tại tâm (cx, cy).
    private func drawNought(ctx: CGContext, cx: CGFloat, cy: CGFloat, isWinner: Bool) {
        let color = isWinner
            ? UIColor(red: 1.0, green: 0.7, blue: 0.1, alpha: 1)
            : Player.nought.color

        let margin:    CGFloat = cellSize * 0.20
        let lineWidth: CGFloat = max(cellSize * 0.10, 2.0)
        let radius = cellSize / 2 - margin

        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(lineWidth)
        // Vẽ hình ellipse (hình tròn khi width == height)
        ctx.strokeEllipse(in: CGRect(x: cx - radius, y: cy - radius,
                                     width: radius * 2, height: radius * 2))
    }

    // MARK: - Helper tọa độ

    /// Chuyển điểm chạm (point trong view) → tọa độ ô cờ.
    func coordinate(for point: CGPoint) -> Coordinate {
        // Chia lấy phần nguyên (floor) → xác định ô nào
        let col = Int(floor(point.x / cellSize))
        let row = Int(floor(point.y / cellSize))
        return Coordinate(row: row, col: col)
    }

    /// Tính điểm tâm của một ô cờ (dùng cho animation).
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
        CATransaction.begin()
        CATransaction.setCompletionBlock { ring.removeFromSuperlayer() }
        // `{ ring.removeFromSuperlayer() }` = closure — xóa layer tạm sau khi xong
        ring.add(scaleAnim, forKey: "scale")
        ring.add(opacAnim,  forKey: "opacity")
        CATransaction.commit()  // bắt đầu chạy animation
    }

    /// Hiệu ứng flash vàng cho đường thắng.
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
