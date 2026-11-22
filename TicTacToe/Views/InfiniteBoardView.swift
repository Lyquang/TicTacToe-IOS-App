import UIKit

/// A large tiled canvas. UIScrollView handles panning and pinch-to-zoom.
final class InfiniteBoardView: UIView {
    override class var layerClass: AnyClass { CATiledLayer.self }

    var cellSize: CGFloat = 48

    // CATiledLayer may draw tiles concurrently. Readers take a value snapshot
    // under the same lock used by the main-thread writer, then render unlocked.
    private struct RenderState {
        var board: [Coordinate: Player] = [:]
        var winners: Set<Coordinate> = []
    }
    private let stateLock = NSLock()
    private var state = RenderState()
    private let background = UIColor(red: 0.11, green: 0.11, blue: 0.18, alpha: 1).cgColor
    private let grid = UIColor(red: 0.32, green: 0.32, blue: 0.48, alpha: 1).cgColor
    private let accent = UIColor(red: 0.40, green: 0.40, blue: 0.60, alpha: 1).cgColor
    private let highlight = UIColor(red: 1, green: 0.84, blue: 0, alpha: 0.3).cgColor
    private let crossColor = Player.cross.color.cgColor
    private let noughtColor = Player.nought.color.cgColor
    private let winnerColor = UIColor(red: 1, green: 0.7, blue: 0.1, alpha: 1).cgColor

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = UIColor(cgColor: background)
        isOpaque = true
        let tiles = layer as! CATiledLayer
        tiles.levelsOfDetail = 4
        tiles.levelsOfDetailBias = 2
        tiles.tileSize = CGSize(width: 256, height: 256)
    }

    /// Publish board and win highlight together, avoiding partially updated tiles.
    func update(board: [Coordinate: Player], winningLine: [Coordinate]?) {
        stateLock.lock()
        state = RenderState(board: board, winners: Set(winningLine ?? []))
        stateLock.unlock()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        stateLock.lock()
        let snapshot = state
        stateLock.unlock()
        let size = cellSize
        guard size > 0 else { return }
        ctx.setFillColor(background)
        ctx.fill(rect)

        let firstCol = Int(floor(rect.minX / size))
        let lastCol = Int(ceil(rect.maxX / size))
        let firstRow = Int(floor(rect.minY / size))
        let lastRow = Int(ceil(rect.maxY / size))
        guard firstCol <= lastCol, firstRow <= lastRow else { return }

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
