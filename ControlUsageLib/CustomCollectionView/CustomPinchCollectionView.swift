//import UIKit
//
//struct GridConfig {
//    
//    /// 常规item宽度
//    static let itemNormalWidth:CGFloat = 60
//    
//    /// 常规item高度
//    static let itemNormalHeight:CGFloat = 60
//    
//    /// 最大行数
//    static let itemMaxRow:Int = 100
//    
//    /// 最大列数
//    static let itemMaxColumn:Int = 100
//    
//    // 总尺寸
//    static let totalSize:CGSize = CGSize(width: CGFloat(GridConfig.itemMaxColumn) * GridConfig.itemNormalWidth,
//                                         height: CGFloat(GridConfig.itemMaxRow) * GridConfig.itemNormalHeight)
//    
//    /// 方格图边距
//    static let gridViewPadding:CGFloat = 0
//}
//
//class GridViewController: UIViewController {
//    
//    var scrollView: TwoFingerScrollView!
//    var gridView = OptimizedGridView()
//    
//    /// gridView 与 scrollView 的边距
//    var padding:CGFloat = 100
//    
//    var zoomBeginOffset:CGPoint = .zero
//    
//    /// 记录捏合开始时在 scrollView 坐标系中的中心点位置
//    private var pinchCenterInScroll: CGPoint?
//    
//    /// 记录捏合开始时在 gridView bounds 坐标系中的中心点（相对于 gridView.bounds）
//    private var pinchCenterInGrid: CGPoint?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .black
//        navigationController?.navigationBar.isHidden = true
//        setupUI()
//        setupGrid()
//    }
//    
//    private func setupUI() {
//        view.backgroundColor = .black
//        
//        // 创建 UIScrollView
//        scrollView = TwoFingerScrollView(frame: view.bounds)
//        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        scrollView.delegate = self
//        
//        // 设置缩放参数
//        scrollView.minimumZoomScale = 0.1
//        scrollView.maximumZoomScale = 2
//        scrollView.zoomScale = 1.0
//        
//        view.addSubview(scrollView)
//        
//    }
//    
//    private func setupGrid() {
//        // 创建网格视图
//        gridView.configureGrid(totalSize: GridConfig.totalSize)
//        
//        // 添加到 scrollView
//        scrollView.addSubview(gridView)
//        
//        // 设置 contentSize
//        scrollView.contentSize = CGSize(width: GridConfig.totalSize.width + GridConfig.gridViewPadding * 2,
//                                        height: GridConfig.totalSize.height + GridConfig.gridViewPadding * 2)
//        
//        updateContentSize()
//        
//        gridView.shouldDrawNum = scrollView.zoomScale >= 1
//        createVisableTextLayers()
//    }
//    
//    // 更新 contentSize，确保包含边距
//    private func updateContentSize() {
//        let currentSize = gridView.frame.size
//        scrollView.contentSize = CGSize(
//            width: currentSize.width + GridConfig.gridViewPadding * 2,
//            height: currentSize.height + GridConfig.gridViewPadding * 2
//        )
//    }
//    
//    // 确保 gridView 的位置保持边距为 500
//    private func maintainGridViewPadding() {
//        var frame = gridView.frame
//        frame.origin.x = GridConfig.gridViewPadding
//        frame.origin.y = GridConfig.gridViewPadding
//        gridView.frame = frame
//    }
//    
//    // 设置双击手势
//    private func setupDoubleTapGesture() {
//        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
//        doubleTapRecognizer.numberOfTapsRequired = 2
//        scrollView.addGestureRecognizer(doubleTapRecognizer)
//    }
//    
//    @objc private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
//        if scrollView.zoomScale > scrollView.minimumZoomScale {
//            // 如果已放大，则缩小
//            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
//        } else {
//            // 如果已缩小，则放大到中等比例
//            scrollView.setZoomScale(2.0, animated: true)
//        }
//    }
//    
//    /// 格局可视范围绘制坐标数字
//    func createVisableTextLayers() {
//        //获取可视范围
//        let visableRect = currentVisibleRect()
//        //根据可视范围绘制坐标
//        gridView.createNumberLayers(visableRect: visableRect)
//    }
//}
//
//// MARK: - UIScrollViewDelegate
//extension GridViewController: UIScrollViewDelegate {
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        return gridView
//    }
//    
//    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
//        zoomBeginOffset = scrollView.contentOffset
//        
//        // 记录捏合中心点在 scrollView 和 gridView 坐标系中的位置
//        if let pinch = scrollView.pinchGestureRecognizer {
//            // 获取捏合中心点在 scrollView 坐标系中的位置（相对于 scrollView.bounds）
//            let centerInScroll = pinch.location(in: scrollView)
//            pinchCenterInScroll = centerInScroll
//            
//            // 转换到 gridView 坐标系
//            let centerInGrid = scrollView.convert(centerInScroll, to: gridView)
//            // 转换为相对于 gridView bounds 的坐标（减去 frame.origin 的偏移）
//            pinchCenterInGrid = CGPoint(
//                x: centerInGrid.x - gridView.frame.origin.x,
//                y: centerInGrid.y - gridView.frame.origin.y
//            )
//        } else {
//            // 如果没有捏合手势，使用视图中心
//            let centerInScroll = CGPoint(x: scrollView.bounds.midX, y: scrollView.bounds.midY)
//            pinchCenterInScroll = centerInScroll
//            let centerInGrid = scrollView.convert(centerInScroll, to: gridView)
//            pinchCenterInGrid = CGPoint(
//                x: centerInGrid.x - gridView.frame.origin.x,
//                y: centerInGrid.y - gridView.frame.origin.y
//            )
//        }
//    }
//    
//    func scrollViewDidZoom(_ scrollView: UIScrollView) {
//        // 缩放时保持 gridView 的边距
//        maintainGridViewPadding()
//        // 更新 contentSize
//        updateContentSize()
//        
//        // 调整 contentOffset 以保持捏合中心点在视图中心
//        adjustContentOffsetForZoomCenter(in: scrollView)
//        
//        //scrollview的缩放比率大于等于1时，需要绘制坐标数字
//        gridView.shouldDrawNum = scrollView.zoomScale >= 1
//    }
//    
//    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//        // 缩放时保持 gridView 的边距
//        maintainGridViewPadding()
//        // 更新 contentSize
//        updateContentSize()
//        
//        // 最终调整 contentOffset
//        adjustContentOffsetForZoomCenter(in: scrollView)
//        
//        // 清除记录的捏合中心点
//        pinchCenterInGrid = nil
//        pinchCenterInScroll = nil
//        
//        createVisableTextLayers()
//    }
//    
//    /// 根据记录的捏合中心点调整 contentOffset，使该点在缩放后保持在视图中的相对位置不变
//    private func adjustContentOffsetForZoomCenter(in scrollView: UIScrollView) {
//        guard let centerInGrid = pinchCenterInGrid,
//              let centerInScroll = pinchCenterInScroll else { return }
//        
//        let scale = scrollView.zoomScale
//        let contentSize = scrollView.contentSize
//        let boundsSize = scrollView.bounds.size
//        
//        // 计算缩放后该点在 gridView bounds 中的新位置
//        let scaledPointInGridX = centerInGrid.x * scale
//        let scaledPointInGridY = centerInGrid.y * scale
//        
//        // 计算该点在 scrollView 坐标系中的新位置（考虑 gridView 的 frame.origin）
//        let newPointInScrollX = scaledPointInGridX + gridView.frame.origin.x
//        let newPointInScrollY = scaledPointInGridY + gridView.frame.origin.y
//        
//        // 计算需要调整的 contentOffset，使得该点在 scrollView 中的位置保持不变
//        // 新位置 - 旧位置 = contentOffset 需要调整的量
//        let offsetDeltaX = newPointInScrollX - centerInScroll.x
//        let offsetDeltaY = newPointInScrollY - centerInScroll.y
//        
//        // 计算新的 contentOffset（基于缩放开始时的偏移量）
//        var newOffsetX = zoomBeginOffset.x + offsetDeltaX
//        var newOffsetY = zoomBeginOffset.y + offsetDeltaY
//        
//        // 约束在有效范围内
//        let maxOffsetX = max(0, contentSize.width - boundsSize.width)
//        let maxOffsetY = max(0, contentSize.height - boundsSize.height)
//        
//        newOffsetX = max(0, min(newOffsetX, maxOffsetX))
//        newOffsetY = max(0, min(newOffsetY, maxOffsetY))
//        
//        scrollView.contentOffset = CGPoint(x: newOffsetX, y: newOffsetY)
//    }
//    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        createVisableTextLayers()
//        print("gridView的偏移量为\(scrollView.contentOffset)")
//        print("gridView的frame为\(gridView.frame)")
//    }
//    
//    private func currentVisibleRect() -> CGRect {
//        //将scrollview的坐标系转换为GridView的坐标系
//        let rectInGrid = scrollView.convert(scrollView.bounds, to: gridView)
//        let visableRect = gridView.bounds.intersection(rectInGrid)
////        print("转换后的GridView范围为\(rectInGrid),可视范围为\(visableRect)")
//        
//        return visableRect
//    }
//}
//
//class OptimizedGridView: UIView {
//
//    /// 是否应该绘制坐标数字
//    var shouldDrawNum:Bool = false
//    
//    // 使用 CALayer 来提高性能
//    private var gridLayers: [CALayer] = []
//    
//    // scale较低时的CAShapeLayer网格实现
//    var minScaleAxisLayer:CAShapeLayer = CAShapeLayer()
//    
//    // scale较低时的CAShapeLayer边界分区线条实现
//    var minScaleBorderLayer:CAShapeLayer = CAShapeLayer()
//    
//    func configureGrid(totalSize: CGSize) {
//        // 设置视图的frame
//        self.frame = CGRect(origin: .zero, size: GridConfig.totalSize)
//        
//        // 创建网格图层
//        drawMinScaleAxisPath(rows: GridConfig.itemMaxRow,
//                     columns: GridConfig.itemMaxColumn,
//                     totalSize: GridConfig.totalSize)
//    }
//    
//    /// 绘制网格图层
//    /// - Parameters:
//    ///   - rows: 行
//    ///   - columns: 列
//    ///   - totalSize: 宽高
//    func drawMinScaleAxisPath(rows: Int, columns: Int, totalSize: CGSize) {
//        let path = UIBezierPath()
//        
//        // 计算每个方格的大小
//        let cellWidth = GridConfig.itemNormalWidth
//        let cellHeight = GridConfig.itemNormalHeight
//        for i in 0...rows {
//            path.move(to: CGPoint(x:0, y: cellHeight * CGFloat(i)))
//            path.addLine(to: CGPoint(x: totalSize.width, y: cellHeight * CGFloat(i)))
//        }
//        
//        for i in 0...columns {
//            path.move(to: CGPoint(x: cellWidth * CGFloat(i), y: 0))
//            path.addLine(to: CGPoint(x: cellWidth * CGFloat(i), y: totalSize.height))
//        }
//        
//        minScaleAxisLayer.path = path.cgPath
//        minScaleAxisLayer.lineWidth = 1.0
//        minScaleAxisLayer.strokeColor = RGB(r: 179, g: 179, b: 179).cgColor
//        self.layer.addSublayer(minScaleAxisLayer)
//        
//        let borderPath = UIBezierPath(roundedRect: CGRect(x: 0,
//                                                                  y: 0,
//                                                                  width: GridConfig.totalSize.width,
//                                                                  height: GridConfig.totalSize.height), cornerRadius: 6)
//        //分成4*4大块
//        for i in 1..<4 {
//            //画4*4分区的横线
//            borderPath.move(to: CGPoint(x: 0,
//                                                y: totalSize.height / CGFloat(4) * CGFloat(i)))
//            borderPath.addLine(to: CGPoint(x: totalSize.width,
//                                                   y: totalSize.height / CGFloat(4) * CGFloat(i)))
//            //画4*4分区的竖线
//            borderPath.move(to: CGPoint(x: totalSize.width / CGFloat(4) * CGFloat(i),
//                                                y: 0))
//            borderPath.addLine(to: CGPoint(x: totalSize.width / CGFloat(4) * CGFloat(i),
//                                                   y: totalSize.height))
//        }
//        
//        minScaleBorderLayer.path = borderPath.cgPath
//        minScaleBorderLayer.lineWidth = 4.0
//        minScaleBorderLayer.fillColor = UIColor.clear.cgColor
//        minScaleBorderLayer.strokeColor = RGB(r: 179, g: 179, b: 179).cgColor
//        self.layer.addSublayer(minScaleBorderLayer)
//    }
//    
//    /// 根据可视范围创建数字坐标图层
//    /// - Parameter visableRect: 可视范围
//    func createNumberLayers(visableRect:CGRect) {
//        // 清除旧图层
//        gridLayers.forEach { $0.removeFromSuperlayer() }
//        gridLayers.removeAll()
//    
//        if shouldDrawNum {
//            //通过可视范围计算
//            let minRowNum = min(Int(floor(visableRect.minY / GridConfig.itemNormalHeight)),
//                                GridConfig.itemMaxRow)
//            let maxRowNum = min(Int(ceil(visableRect.maxY / GridConfig.itemNormalHeight)),
//                                GridConfig.itemMaxRow)
//            let minColumnNum = min(Int(floor(visableRect.minX / GridConfig.itemNormalWidth)),
//                                   GridConfig.itemMaxColumn)
//            let maxColumnNum = min(Int(ceil(visableRect.maxX / GridConfig.itemNormalWidth)),
//                                   GridConfig.itemMaxColumn)
//            
//            for row in minRowNum..<maxRowNum {
//                for column in minColumnNum..<maxColumnNum {
//                    let textLayer = addNumberToLayer(row: row,
//                                                     column: column,
//                                                     number: row * GridConfig.itemMaxColumn + column + 1)
//                    self.layer.addSublayer(textLayer)
//                    gridLayers.append(textLayer)
//                }
//            }
//        }
//    }
//
//    /// 创建单个数字坐标图层
//    /// - Parameters:
//    ///   - row: 行
//    ///   - column: 列
//    ///   - number: 数字
//    /// - Returns: CATextLayer
//    private func addNumberToLayer(row: Int, column: Int, number: Int) -> CATextLayer {
//        
//        let x = CGFloat(column) * GridConfig.itemNormalWidth
//        let y = CGFloat(row) * GridConfig.itemNormalHeight
//        
//        let textLayer = CATextLayer()
//        textLayer.string = "\(number)"
//        textLayer.fontSize = 10
//        textLayer.foregroundColor = RGB(r: 179, g: 179, b: 179).cgColor
//        textLayer.alignmentMode = .natural
//        textLayer.contentsScale = UIScreen.main.scale
//        
//        let leading:CGFloat = 4
//        
//        textLayer.frame = CGRect(x: x + leading,
//                                 y: y,
//                                 width: GridConfig.itemNormalWidth,
//                                 height: GridConfig.itemNormalHeight)
//        
//        return textLayer
//    }
//}
//
//
//final class TwoFingerScrollView:UIScrollView,UIGestureRecognizerDelegate {
//    
//    lazy var twoFingerPan:UIPanGestureRecognizer = {
//        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleTwoFingerPan(_:)))
//        gesture.minimumNumberOfTouches = 2
//        gesture.maximumNumberOfTouches = 2
//        gesture.delegate = self
//        return gesture
//    }()
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupTwoFingerScroll()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupTwoFingerScroll()
//        
//    }
//    
//    private func setupTwoFingerScroll() {
//        isScrollEnabled = false
//        panGestureRecognizer.isEnabled = false
//        // 禁用所有子手势，避免一指拖动画面
//        for gesture in gestureRecognizers ?? [] {
//            if gesture is UIPanGestureRecognizer && gesture !== twoFingerPan {
//                gesture.isEnabled = false
//            }
//        }
//        addGestureRecognizer(twoFingerPan)
//        
//    }
//    
//    @objc func handleTwoFingerPan(_ pan: UIPanGestureRecognizer) {
//        switch pan.state {
//        case .began:
//            //停止当前的滚动
//            setContentOffset(contentOffset, animated: false)
//        case .changed:
//            let translation = pan.translation(in: self)
//            var newOffset = contentOffset
//            newOffset.x -= translation.x
//            newOffset.y -= translation.y
//            //确保不超出边界
//            newOffset.x = max(0,min(newOffset.x,contentSize.width - bounds.width))
//            newOffset.y = max(0,min(newOffset.y,contentSize.height - bounds.height))
//            contentOffset = newOffset
//            pan.setTranslation(.zero, in: self)
//        default:
//            break
//        }
//    }
//    
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return false
//    }
//}
