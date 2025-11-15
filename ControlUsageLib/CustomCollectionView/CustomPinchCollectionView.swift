import UIKit
import CoreText

// MARK: - GridLayer: 负责绘制网格（可见区域优化）
class GridLayer: CALayer {
    // 数据源：格子数量
    var itemCount: Int = 1000 { didSet { setNeedsDisplay() } }
    // 单元格大小（逻辑像素）
    var cellSize: CGFloat = 80 { didSet { setNeedsDisplay() } }
    // 内容偏移（用于平移）
    var contentOffset: CGPoint = .zero { didSet { setNeedsDisplay() } }
    // 行列数推导（不强制）
    var columns: Int { max(1, Int(bounds.width / cellSize) + 2) }
    // 用来高亮拖拽中项
    var draggingIndex: Int? { didSet { setNeedsDisplay() } }
    // 拖拽浮层位置（屏幕坐标）
    var dragPosition: CGPoint? { didSet { setNeedsDisplay() } }
    // 文字属性缓存
    private var font: CTFont = CTFontCreateWithName("Helvetica" as CFString, 14, nil)

    override init() {
        super.init()
        contentsScale = UIScreen.main.scale
        isOpaque = true
        needsDisplayOnBoundsChange = true
        setNeedsDisplay()
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(in ctx: CGContext) {
        guard itemCount > 0 else { return }
        UIGraphicsPushContext(ctx)
        ctx.saveGState()

        // clear
        ctx.setFillColor(UIColor.systemBackground.cgColor)
        ctx.fill(bounds)

        // apply contentOffset (world -> view)
        ctx.translateBy(x: -contentOffset.x, y: -contentOffset.y)

        // compute visible rect in world coords
        let visibleRect = CGRect(origin: contentOffset, size: bounds.size)

        // compute visible rows/cols (with padding)
        let minCol = max(0, Int(floor(visibleRect.minX / cellSize)) - 1)
        let maxCol = Int(ceil(visibleRect.maxX / cellSize)) + 1
        let minRow = max(0, Int(floor(visibleRect.minY / cellSize)) - 1)
        let maxRow = Int(ceil(visibleRect.maxY / cellSize)) + 1

        // grid line style
        ctx.setLineWidth(1.0 / contentsScale)
        ctx.setStrokeColor(UIColor.secondaryLabel.cgColor)

        // draw vertical lines
        var x = CGFloat(minCol) * cellSize
        if minCol <= maxCol {
            for col in minCol...maxCol {
                ctx.move(to: CGPoint(x: x, y: CGFloat(minRow) * cellSize))
                ctx.addLine(to: CGPoint(x: x, y: CGFloat(maxRow) * cellSize))
                x += cellSize
            }
        }
        
        // draw horizontal lines
        var y = CGFloat(minRow) * cellSize
        if minRow <= maxRow {
            for row in minRow...maxRow {
                ctx.move(to: CGPoint(x: CGFloat(minCol) * cellSize, y: y))
                ctx.addLine(to: CGPoint(x: CGFloat(maxCol) * cellSize, y: y))
                y += cellSize
            }
            ctx.strokePath()
        }
        

        // draw items (only visible ones)
        let colsPerRow = max(1, columns)
        for row in minRow...maxRow {
            for col in minCol...maxCol {
                let idx = row * colsPerRow + col
                if idx < 0 || idx >= itemCount { continue }
                let cellRect = CGRect(x: CGFloat(col) * cellSize,
                                      y: CGFloat(row) * cellSize,
                                      width: cellSize,
                                      height: cellSize)
                // cell background for dragging highlight
                if let dragIdx = draggingIndex, dragIdx == idx {
                    // skip drawing underlying if dragging (we'll draw floating representation elsewhere)
                    ctx.setFillColor(UIColor.systemGray4.cgColor)
                    ctx.fill(cellRect.insetBy(dx: 2, dy: 2))
                }

                // draw index text centered
                let text = "\(idx)"
                drawCentered(text: text, in: cellRect, ctx: ctx)
            }
        }

        // draw floating drag snapshot if exists
        if let dragIndex = draggingIndex, let dragPos = dragPosition, dragIndex < itemCount {
            // draw a floating rounded rect with index
            ctx.restoreGState() // go to screen coords
            let size = CGSize(width: cellSize * 0.95, height: cellSize * 0.95)
            let r = CGRect(origin: CGPoint(x: dragPos.x - size.width/2, y: dragPos.y - size.height/2), size: size)
            ctx.saveGState()
            let path = UIBezierPath(roundedRect: r, cornerRadius: 8)
            ctx.setFillColor(UIColor.systemBlue.withAlphaComponent(0.95).cgColor)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
            // text
            ctx.translateBy(x: 0, y: 0)
            drawCentered(text: "\(dragIndex)", in: r, ctx: ctx, color: UIColor.white)
        }

        ctx.restoreGState()
        UIGraphicsPopContext()
    }

    private func drawCentered(text: String, in rect: CGRect, ctx: CGContext, color: UIColor = .label) {
        // use CoreText quick draw
        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: min(16, rect.width * 0.2)),
            .foregroundColor: color
        ]
        let attrStr = NSAttributedString(string: text, attributes: attr)
        let line = CTLineCreateWithAttributedString(attrStr as CFAttributedString)
        ctx.saveGState()
        ctx.translateBy(x: rect.midX, y: rect.midY)
        // CoreText draws text baseline at (0,0), so move down by half ascent-descent:
        let runs = CTLineGetGlyphRuns(line) as? [CTRun]
        // Simple: use CTLineGetTypographicBounds to center vertically
        var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
        let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
        ctx.translateBy(x: -CGFloat(width)/2.0, y: -CGFloat((ascent - descent)/2.0))
        ctx.setTextDrawingMode(.fill)
        ctx.setFillColor(color.cgColor)
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }
}

// MARK: - GridView: 封装手势、CADisplayLink、拖拽逻辑
class GridView: UIView {
    private let gridLayer = GridLayer()
    private var displayLink: CADisplayLink?

    // model
    private(set) var itemCount: Int = 1000 {
        didSet { gridLayer.itemCount = itemCount }
    }

    // state
    private var cellSize: CGFloat = 80 {
        didSet {
            gridLayer.cellSize = cellSize
        }
    }
    private var contentOffset: CGPoint = .zero {
        didSet {
            gridLayer.contentOffset = contentOffset
        }
    }
    private var velocity = CGPoint.zero // 用于动画（示例）

    // gestures
    private lazy var pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
    private lazy var pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    private lazy var longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))

    // drag
    private var draggingIndex: Int?
    private var dragStartOffset: CGPoint = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        // layer setup
        layer.addSublayer(gridLayer)
        gridLayer.frame = bounds
        gridLayer.contentsScale = UIScreen.main.scale
        gridLayer.itemCount = itemCount
        gridLayer.cellSize = cellSize

        // gestures
        addGestureRecognizer(pinch)
        addGestureRecognizer(pan)
        addGestureRecognizer(longPress)
        pan.require(toFail: longPress) // long press takes precedence for dragging

        // displayLink
        displayLink = CADisplayLink(target: self, selector: #selector(tick(_:)))
        displayLink?.add(to: .main, forMode: .common)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gridLayer.frame = bounds
        gridLayer.setNeedsDisplay()
    }

    deinit {
        displayLink?.invalidate()
    }

    // MARK: - public helpers
    func configure(itemCount: Int, initialCellSize: CGFloat = 80) {
        self.itemCount = itemCount
        self.cellSize = initialCellSize
        gridLayer.cellSize = cellSize
    }

    // MARK: - tick (CADisplayLink)
    @objc private func tick(_ link: CADisplayLink) {
        // If there's an inertial velocity, apply friction (示例)
        if velocity != .zero {
            contentOffset.x += velocity.x / 60.0
            contentOffset.y += velocity.y / 60.0
            velocity.x *= 0.95
            velocity.y *= 0.95
            if abs(velocity.x) < 0.1 && abs(velocity.y) < 0.1 { velocity = .zero }
            gridLayer.contentOffset = contentOffset
            gridLayer.setNeedsDisplay()
        }
    }

    // MARK: - gestures
    @objc private func handlePinch(_ g: UIPinchGestureRecognizer) {
        switch g.state {
        case .began, .changed:
            // 缩放时，保持手势中心位置在相同的世界坐标
            let location = g.location(in: self)
            let worldBefore = CGPoint(x: contentOffset.x + location.x, y: contentOffset.y + location.y)
            let newSize = max(20, min(200, cellSize * g.scale))
            cellSize = newSize
            // adjust contentOffset so that worldBefore maps to same screen point
            let worldAfter = worldBefore
            contentOffset = CGPoint(x: worldAfter.x - location.x, y: worldAfter.y - location.y)
            gridLayer.cellSize = cellSize
            gridLayer.contentOffset = contentOffset
            gridLayer.setNeedsDisplay()
            g.scale = 1.0
        default:
            break
        }
    }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        if draggingIndex != nil {
            // during dragging, we move dragPosition only
            let p = g.location(in: self)
            gridLayer.dragPosition = p
            return
        }
        switch g.state {
        case .began, .changed:
            let t = g.translation(in: self)
            contentOffset.x -= t.x
            contentOffset.y -= t.y
            gridLayer.contentOffset = contentOffset
            gridLayer.setNeedsDisplay()
            g.setTranslation(.zero, in: self)
        case .ended:
            velocity = g.velocity(in: self)
        default:
            break
        }
    }

    @objc private func handleLongPress(_ g: UILongPressGestureRecognizer) {
        let loc = g.location(in: self)
        // map to world coords
        let world = CGPoint(x: contentOffset.x + loc.x, y: contentOffset.y + loc.y)
        let col = Int(floor(world.x / cellSize))
        let row = Int(floor(world.y / cellSize))
        let index = row * max(1, Int(bounds.width / cellSize) + 2) + col

        switch g.state {
        case .began:
            guard index >= 0 && index < itemCount else { return }
            draggingIndex = index
            dragStartOffset = contentOffset
            gridLayer.draggingIndex = index
            gridLayer.dragPosition = loc
            // optionally animate the source cell (e.g. fade)
        case .changed:
            guard draggingIndex != nil else { return }
            gridLayer.dragPosition = loc
            // compute target index under current pos
            let worldPos = CGPoint(x: contentOffset.x + loc.x, y: contentOffset.y + loc.y)
            let targetCol = Int(floor(worldPos.x / cellSize))
            let targetRow = Int(floor(worldPos.y / cellSize))
            let targetIndex = targetRow * max(1, Int(bounds.width / cellSize) + 2) + targetCol
            if targetIndex >= 0 && targetIndex < itemCount && targetIndex != draggingIndex {
                // perform data swap (simple approach: swap positions)
                swapItems(at: draggingIndex!, and: targetIndex)
                draggingIndex = targetIndex
                gridLayer.draggingIndex = draggingIndex
            }
            gridLayer.setNeedsDisplay()
        case .ended, .cancelled:
            // finish drag
            draggingIndex = nil
            gridLayer.draggingIndex = nil
            gridLayer.dragPosition = nil
            gridLayer.setNeedsDisplay()
        default:
            break
        }
    }

    private func swapItems(at a: Int, and b: Int) {
        guard a != b else { return }
        // In real app you maintain an array of models. Here we only care about indices: swapping means their order changed.
        // For demonstration we'll keep itemCount same but this is where you should update your backing data array.
        // Optionally animate the change (not shown) — just trigger redraw.
        // Example: if you had [0,1,2,3,...] you'd swap content of a and b
        // For this sample, we just markNeedsDisplay (user should maintain model)
    }
}
