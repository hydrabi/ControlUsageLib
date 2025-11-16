import UIKit

class GridView: UIView {
    var numberOfRows: Int = 0
    var numberOfColumns: Int = 0
    var gridSize: CGSize = .zero
    
    // 存储方格数据的数组
    var gridData: [[UIColor]] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .white
    }
    
    // 配置网格
    func configureGrid(rows: Int, columns: Int, totalSize: CGSize) {
        self.numberOfRows = rows
        self.numberOfColumns = columns
        
        // 计算每个方格的大小
        let cellWidth = totalSize.width / CGFloat(columns)
        let cellHeight = totalSize.height / CGFloat(rows)
        self.gridSize = CGSize(width: cellWidth, height: cellHeight)
        
        // 设置视图的frame
        self.frame = CGRect(origin: .zero, size: totalSize)
        
        // 生成随机颜色数据用于演示
        generateRandomGridData()
        
        // 标记需要重绘
        setNeedsDisplay()
    }
    
    // 生成随机的网格颜色数据
    private func generateRandomGridData() {
        gridData = []
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemTeal]
        
        for _ in 0..<numberOfRows {
            var row: [UIColor] = []
            for _ in 0..<numberOfColumns {
                let randomColor = colors.randomElement() ?? .systemGray
                row.append(randomColor)
            }
            gridData.append(row)
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // 绘制所有方格
        for row in 0..<numberOfRows {
            for column in 0..<numberOfColumns {
                drawGridCell(context: context, row: row, column: column)
            }
        }
    }
    
    // 绘制单个方格
    private func drawGridCell(context: CGContext, row: Int, column: Int) {
        let x = CGFloat(column) * gridSize.width
        let y = CGFloat(row) * gridSize.height
        
        let cellRect = CGRect(x: x, y: y, width: gridSize.width, height: gridSize.height)
        
        // 设置方格颜色
        let color = gridData[row][column]
        context.setFillColor(color.cgColor)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(0.5)
        
        // 绘制方格填充和边框
        context.fill(cellRect)
        context.stroke(cellRect)
        
        // 绘制序号
        drawGridNumber(context: context, rect: cellRect, number: row * numberOfColumns + column + 1)
    }
    
    // 绘制方格序号
    private func drawGridNumber(context: CGContext, rect: CGRect, number: Int) {
        let numberString = "\(number)" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 4, weight: .medium),
            .foregroundColor: UIColor.white
        ]
        
        let textSize = numberString.size(withAttributes: attributes)
        let textRect = CGRect(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        numberString.draw(in: textRect, withAttributes: attributes)
    }
}

class GridViewController: UIViewController {
    
    var scrollView: UIScrollView!
    var gridView: GridView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGrid()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 创建 UIScrollView
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        
        // 设置缩放参数
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 10.0
        scrollView.zoomScale = 1.0
        
        view.addSubview(scrollView)
        
        // 添加双击手势
        setupDoubleTapGesture()
    }
    
    private func setupGrid() {
        // 配置 40x25 = 1000 个方格
        let rows = 100
        let columns = 100
        
        // 计算总尺寸 (每个方格 40x40)
        let totalWidth = CGFloat(columns) * 10
        let totalHeight = CGFloat(rows) * 10
        
        // 创建网格视图
        gridView = GridView()
        gridView.configureGrid(rows: rows, columns: columns, totalSize: CGSize(width: totalWidth, height: totalHeight))
        
        // 添加到 scrollView
        scrollView.addSubview(gridView)
        
        // 设置 contentSize
        scrollView.contentSize = CGSize(width: totalWidth, height: totalHeight)
        
        // 初始居中显示
        centerGridView()
    }
    
    // 设置双击手势
    private func setupDoubleTapGesture() {
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapRecognizer)
    }
    
    @objc private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            // 如果已放大，则缩小
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            // 如果已缩小，则放大到中等比例
            scrollView.setZoomScale(2.0, animated: true)
        }
    }
    
    // 居中显示网格
    private func centerGridView() {
        let boundsSize = scrollView.bounds.size
        var contentFrame = gridView.frame
        
        // 水平居中
        if contentFrame.size.width < boundsSize.width {
            contentFrame.origin.x = (boundsSize.width - contentFrame.size.width) / 2.0
        } else {
            contentFrame.origin.x = 0.0
        }
        
        // 垂直居中
        if contentFrame.size.height < boundsSize.height {
            contentFrame.origin.y = (boundsSize.height - contentFrame.size.height) / 2.0
        } else {
            contentFrame.origin.y = 0.0
        }
        
        gridView.frame = contentFrame
    }
}

// MARK: - UIScrollViewDelegate
extension GridViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return gridView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // 缩放时保持内容居中
        centerGridView()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        // 缩放结束后可以在这里处理额外逻辑
        print("当前缩放比例: \(scale)")
    }
}

class OptimizedGridView: UIView {
    var numberOfRows: Int = 0
    var numberOfColumns: Int = 0
    var gridSize: CGSize = .zero
    
    // 使用 CALayer 来提高性能
    private var gridLayers: [CALayer] = []
    
    func configureGrid(rows: Int, columns: Int, totalSize: CGSize) {
        self.numberOfRows = rows
        self.numberOfColumns = columns
        
        // 计算每个方格的大小
        let cellWidth = totalSize.width / CGFloat(columns)
        let cellHeight = totalSize.height / CGFloat(rows)
        self.gridSize = CGSize(width: cellWidth, height: cellHeight)
        
        // 设置视图的frame
        self.frame = CGRect(origin: .zero, size: totalSize)
        
        // 创建网格图层
        createGridLayers()
    }
    
    private func createGridLayers() {
        // 清除旧图层
        gridLayers.forEach { $0.removeFromSuperlayer() }
        gridLayers.removeAll()
        
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemTeal]
        
        for row in 0..<numberOfRows {
            for column in 0..<numberOfColumns {
                let layer = createGridLayer(
                    row: row,
                    column: column,
                    color: colors.randomElement() ?? .systemGray,
                    number: row * numberOfColumns + column + 1
                )
                self.layer.addSublayer(layer)
                gridLayers.append(layer)
            }
        }
    }
    
    private func createGridLayer(row: Int, column: Int, color: UIColor, number: Int) -> CALayer {
        let x = CGFloat(column) * gridSize.width
        let y = CGFloat(row) * gridSize.height
        
        let layer = CALayer()
        layer.frame = CGRect(x: x, y: y, width: gridSize.width, height: gridSize.height)
        layer.backgroundColor = color.cgColor
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        
        // 添加序号文本
        addNumberToLayer(layer, number: number)
        
        return layer
    }
    
    private func addNumberToLayer(_ layer: CALayer, number: Int) {
        let textLayer = CATextLayer()
        textLayer.string = "\(number)"
        textLayer.fontSize = 4
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        
        textLayer.frame = CGRect(
            x: 0,
            y: layer.bounds.midY - 6,
            width: layer.bounds.width,
            height: 12
        )
        
        layer.addSublayer(textLayer)
    }
}
