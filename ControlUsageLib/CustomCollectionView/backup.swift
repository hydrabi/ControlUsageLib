//   backup.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/11/17
//   


import Foundation

struct GridConfig {
    
    /// 最大行数
    static let itemMaxRow:Int = 100
    
    /// 最大列数
    static let itemMaxColumn:Int = 100
    
    /// item最小宽度
    static let itemMinWidth:CGFloat = 4
    
    /// item最小高度
    static let itemMinHeight:CGFloat = 4
    
    /// grid最小size
    static let gridMinSize:CGSize = CGSize(width: CGFloat(GridConfig.itemMaxColumn) * GridConfig.itemMinWidth,
                                           height: CGFloat(GridConfig.itemMaxRow) * GridConfig.itemMinHeight)
    /// 常规item宽度
    static let itemMaxWidth:CGFloat = 100
    
    /// 常规item高度
    static let itemMaxHeight:CGFloat = 100
    
    // 总尺寸
    static let gridMaxSize:CGSize = CGSize(width: CGFloat(GridConfig.itemMaxColumn) * GridConfig.itemMaxWidth,
                                         height: CGFloat(GridConfig.itemMaxRow) * GridConfig.itemMaxHeight)
    
    /// 方格图左边距
    static var gridViewLeading:CGFloat = 0
    
    /// 方格图上边距
    static var gridViewTop:CGFloat = 0
    
    /// scale超过多少可以画序号
    static var gridShouldDrawNumScale:CGFloat = 0.8
}

class TestGridViewController: UIViewController {
    
    var scrollView: UIScrollView!
    var gridView = GridView()
    
    /// gridView 与 scrollView 的边距
    var padding:CGFloat = 100
    
    var zoomBeginOffset:CGPoint = .zero
    
    lazy var bgView:UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    /// 记录捏合开始时在 gridView 内的中心点
    private var pinchCenterInGrid: CGPoint?
    
    /// 记录捏合开始时在 gridView 内的中心点（针对所有scale，都要用相对比例存储！）
    private var pinchCenterRatio: CGPoint?
    
    private var pinchContentOffsetRatio:CGPoint = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationController?.navigationBar.isHidden = true
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        GridConfig.gridViewLeading = (view.bounds.width - GridConfig.gridMinSize.width) / 2
        GridConfig.gridViewTop = (view.bounds.height - GridConfig.gridMinSize.height) / 2
        
        // 创建 UIScrollView
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 20, width: view.bounds.width, height: view.bounds.height))
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.04
        scrollView.maximumZoomScale = 1
        scrollView.zoomScale = 1.0
        scrollView.bouncesZoom = false
        scrollView.contentInset = UIEdgeInsets(top: GridConfig.gridViewTop,
                                               left: GridConfig.gridViewLeading,
                                               bottom: GridConfig.gridViewTop,
                                               right: GridConfig.gridViewLeading)
        
//        bgView.addSubview(gridView)
        
        view.addSubview(scrollView)
        
        // 创建网格视图
        gridView.configureGrid(totalSize: GridConfig.gridMaxSize)
        gridView.drawScaleAxisPath(rows: GridConfig.itemMaxRow,
                                   columns: GridConfig.itemMaxColumn,
                                   totalSize: GridConfig.gridMaxSize,
                                   scale: scrollView.zoomScale)
        
        
        // 添加到 scrollView
        scrollView.addSubview(gridView)

        updateContentSize()
        createVisableTextLayers()
    }

    
    // 更新 contentSize，确保包含边距
    private func updateContentSize() {
        let currentSize = gridView.frame.size
        scrollView.contentSize = CGSize(
            width: currentSize.width + GridConfig.gridViewLeading * 2,
            height: currentSize.height + GridConfig.gridViewTop * 2
        )
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
    
    /// 格局可视范围绘制坐标数字
    func createVisableTextLayers() {
        //获取可视范围
        let visableRect = currentVisibleRect()
        //根据可视范围绘制坐标
        gridView.createNumberLayers(visableRect: visableRect)
    }
}

// MARK: - UIScrollViewDelegate
extension TestGridViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return gridView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // 更新 contentSize
        updateContentSize()
        gridView.drawScaleAxisPath(rows: GridConfig.itemMaxRow,
                                      columns: GridConfig.itemMaxColumn,
                                      totalSize: GridConfig.gridMaxSize,
                                      scale: scrollView.zoomScale)
        createVisableTextLayers()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        // 更新 contentSize
        updateContentSize()
        createVisableTextLayers()
        self.scrollView.isScrollEnabled = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        createVisableTextLayers()
        print("gridView的偏移量为\(scrollView.contentOffset)")
        print("gridView的frame为\(gridView.frame)")
        print("scrollview的frame为\(scrollView.frame)")
        print("scrollview的contentSize为\(scrollView.contentSize)")
        print("scrollView的scale为\(scrollView.zoomScale)")
    }
    
    private func currentVisibleRect() -> CGRect {
        //将scrollview的坐标系转换为GridView的坐标系
        let rectInGrid = scrollView.convert(scrollView.bounds, to: gridView)
        let visableRect = gridView.bounds.intersection(rectInGrid)
        print("转换后的GridView范围为\(rectInGrid),可视范围为\(visableRect)")
        
        return visableRect
    }
    
}


final class GridView:UIView {
    /// 是否应该绘制坐标数字
    var shouldDrawNum:Bool {
        get {
            return scale >= GridConfig.gridShouldDrawNumScale
        }
    }
    
    // 使用 CALayer 来提高性能
    private var gridLayers: [CALayer] = []
    
    // scale较低时的CAShapeLayer网格实现
    var minScaleAxisLayer:CAShapeLayer = CAShapeLayer()
    
    // scale较低时的CAShapeLayer边界分区线条实现
    var minScaleBorderLayer:CAShapeLayer = CAShapeLayer()
    
    // scale最大时的CAShapeLayer边界分区线条实现
    var maxScaleAxisLayer:CAShapeLayer = CAShapeLayer()
    
    var scales:[(Int,Int)] = [(1,5),(5,10),(10,15),(20,20)]
    
    var scale:CGFloat = 0
    
    func configureGrid(totalSize: CGSize) {
        // 设置视图的frame
        self.frame = CGRect(x: 0,
                            y: 0,
                            width: totalSize.width,
                            height: totalSize.height)
        self.backgroundColor = .black
        
    }
    
    func drawScaleAxisPath(rows:Int,columns:Int,totalSize:CGSize,scale:CGFloat = 1) {
        guard self.scale != scale else {return}
        
        minScaleAxisLayer.removeFromSuperlayer()
        minScaleBorderLayer.removeFromSuperlayer()
        maxScaleAxisLayer.removeFromSuperlayer()
        
        if scale >= 1 {
            drawMaxScaleAxisPath(rows: rows, columns: columns, totalSize: totalSize)
        }
        else {
            drawMinScaleAxisPath(rows: rows, columns: columns, totalSize: totalSize,scale:scale)
        }
        
        self.scale = scale
    }
    
    /// 绘制网格图层
    /// - Parameters:
    ///   - rows: 行
    ///   - columns: 列
    ///   - totalSize: 宽高
    func drawMinScaleAxisPath(rows: Int, columns: Int, totalSize: CGSize,scale:CGFloat = 1) {
        minScaleAxisLayer.removeFromSuperlayer()
        minScaleBorderLayer.removeFromSuperlayer()
        maxScaleAxisLayer.removeFromSuperlayer()
        
        //根据缩放scale重新计算lineWidth 防止缩放时线条变模糊
        let baseLineWidth:CGFloat = 1 / scale
        let baseBorderLineWidth:CGFloat = 2 / scale
        
        
        let path = UIBezierPath()
        
        // 计算每个方格的大小
        let cellWidth:CGFloat = totalSize.width / CGFloat(columns)
        let cellHeight:CGFloat = totalSize.height / CGFloat(rows)
        for i in 0...rows {
            path.move(to: CGPoint(x:0, y: cellHeight * CGFloat(i)))
            path.addLine(to: CGPoint(x: totalSize.width, y: cellHeight * CGFloat(i)))
        }
        
        for i in 0...columns {
            path.move(to: CGPoint(x: cellWidth * CGFloat(i), y: 0))
            path.addLine(to: CGPoint(x: cellWidth * CGFloat(i), y: totalSize.height))
        }
        
        minScaleAxisLayer.path = path.cgPath
        minScaleAxisLayer.lineWidth = baseLineWidth
        minScaleAxisLayer.strokeColor = RGB(r: 179, g: 179, b: 179).cgColor
        self.layer.addSublayer(minScaleAxisLayer)
        
        let borderPath = UIBezierPath(roundedRect: CGRect(x: 0,
                                                                  y: 0,
                                                          width: totalSize.width,
                                                          height: totalSize.height),
                                      cornerRadius: 2.5)
        //分成4*4大块
        for i in 1..<4 {
            //画4*4分区的横线
            borderPath.move(to: CGPoint(x: 0,
                                                y: totalSize.height / CGFloat(4) * CGFloat(i)))
            borderPath.addLine(to: CGPoint(x: totalSize.width,
                                                   y: totalSize.height / CGFloat(4) * CGFloat(i)))
            //画4*4分区的竖线
            borderPath.move(to: CGPoint(x: totalSize.width / CGFloat(4) * CGFloat(i),
                                                y: 0))
            borderPath.addLine(to: CGPoint(x: totalSize.width / CGFloat(4) * CGFloat(i),
                                                   y: totalSize.height))
        }
        
        minScaleBorderLayer.path = borderPath.cgPath
        minScaleBorderLayer.lineWidth = baseBorderLineWidth
        minScaleBorderLayer.fillColor = UIColor.clear.cgColor
        minScaleBorderLayer.strokeColor = RGB(r: 179, g: 179, b: 179).cgColor
        self.layer.addSublayer(minScaleBorderLayer)
    }
    
    /// 绘制网格图层
    /// - Parameters:
    ///   - rows: 行
    ///   - columns: 列
    ///   - totalSize: 宽高
    func drawMaxScaleAxisPath(rows: Int, columns: Int, totalSize: CGSize) {
        
        let path = UIBezierPath()
        
        // 计算每个方格的大小
        let cellWidth:CGFloat = totalSize.width / CGFloat(columns)
        let cellHeight:CGFloat = totalSize.height / CGFloat(rows)
        for i in 0...rows {
            path.move(to: CGPoint(x:0, y: cellHeight * CGFloat(i)))
            path.addLine(to: CGPoint(x: totalSize.width, y: cellHeight * CGFloat(i)))
        }
        
        for i in 0...columns {
            path.move(to: CGPoint(x: cellWidth * CGFloat(i), y: 0))
            path.addLine(to: CGPoint(x: cellWidth * CGFloat(i), y: totalSize.height))
        }
        
        maxScaleAxisLayer.path = path.cgPath
        maxScaleAxisLayer.lineJoin = .round
        maxScaleAxisLayer.lineDashPattern = [4]
        maxScaleAxisLayer.lineWidth = 1.0
        maxScaleAxisLayer.strokeColor = RGB(r: 179, g: 179, b: 179).cgColor
        self.layer.addSublayer(maxScaleAxisLayer)
    }
    
    /// 根据可视范围创建数字坐标图层
    /// - Parameter visableRect: 可视范围
    func createNumberLayers(visableRect:CGRect) {
        // 清除旧图层
        gridLayers.forEach { $0.removeFromSuperlayer() }
        gridLayers.removeAll()

        if shouldDrawNum {
            //通过可视范围计算
            let minRowNum = min(Int(floor(visableRect.minY / GridConfig.itemMaxHeight)),
                                GridConfig.itemMaxRow)
            let maxRowNum = min(Int(ceil(visableRect.maxY / GridConfig.itemMaxHeight)),
                                GridConfig.itemMaxRow)
            let minColumnNum = min(Int(floor(visableRect.minX / GridConfig.itemMaxWidth)),
                                   GridConfig.itemMaxColumn)
            let maxColumnNum = min(Int(ceil(visableRect.maxX / GridConfig.itemMaxWidth)),
                                   GridConfig.itemMaxColumn)

            for row in minRowNum..<maxRowNum {
                for column in minColumnNum..<maxColumnNum {
                    let textLayer = addNumberToLayer(row: row,
                                                     column: column,
                                                     number: row * GridConfig.itemMaxColumn + column + 1,
                                                     gridSize: GridConfig.gridMaxSize)
                    self.layer.addSublayer(textLayer)
                    gridLayers.append(textLayer)
                }
            }
        }
    }

    /// 创建单个数字坐标图层
    /// - Parameters:
    ///   - row: 行
    ///   - column: 列
    ///   - number: 数字
    /// - Returns: CATextLayer
    private func addNumberToLayer(row: Int, column: Int, number: Int,gridSize:CGSize) -> CATextLayer {
        let itemWidth = gridSize.width / CGFloat(GridConfig.itemMaxColumn)
        let itemHeight = gridSize.height / CGFloat(GridConfig.itemMaxRow)
        let x = CGFloat(column) * itemWidth
        let y = CGFloat(row) * itemHeight
        
        let textLayer = CATextLayer()
        textLayer.string = "\(number)"
        textLayer.fontSize = 10
        textLayer.foregroundColor = RGB(r: 179, g: 179, b: 179).cgColor
        textLayer.alignmentMode = .natural
        textLayer.contentsScale = UIScreen.main.scale
        
        let leading:CGFloat = 4
        
        textLayer.frame = CGRect(x: x + leading,
                                 y: y,
                                 width: itemWidth,
                                 height: itemHeight)
        
        return textLayer
    }
}
