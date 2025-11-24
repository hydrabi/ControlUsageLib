//   GridView.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/11/24
//   


import Foundation

/// 二指滑动scrollview
final class TwoFingerScrollView:UIScrollView,UIGestureRecognizerDelegate {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTwoFingerScroll()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTwoFingerScroll()
    }

    private func setupTwoFingerScroll() {
        for gesture in gestureRecognizers ?? [] {
            //滑动手势最小手指数改成2
            if let pan = gesture as? UIPanGestureRecognizer {
                pan.minimumNumberOfTouches = 2
            }
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

/// 自定义网格图
final class GridView:UIView {
    
    /// 是否应该绘制坐标数字
    var shouldDrawNum:Bool {
        get {
            return scale >= GridConfig.gridShouldDrawNumScale
        }
    }
    
    /// 是否应该绘制设备
    var shouldDrawFixture:Bool {
        get {
            return scale >= GridConfig.gridShouldDrawFixtureScale
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
    
    // 设备图层
    var lampLayers:[AULampLayoutLayer] = []
    
    //当前scale
    var scale:CGFloat = 0
    
    //当前选中的设备
    private var selectedLampLayer:AULampLayoutLayer?
    
    /// 点击手势
    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.numberOfTapsRequired = 1
        return tap
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addGestureRecognizer(tapGestureRecognizer)
        isUserInteractionEnabled = true
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addGestureRecognizer(tapGestureRecognizer)
        isUserInteractionEnabled = true
    }
    
    func configureGrid(totalSize: CGSize,
                       layouts:[AULampLayout]) {
        // 设置视图的frame
        self.frame = CGRect(x: 0,
                            y: 0,
                            width: totalSize.width,
                            height: totalSize.height)
        self.backgroundColor = .black
        //创建设备图层
        createFixtureLayers(layouts: layouts)
    }
    /// 绘制网格图层
    /// - Parameters:
    ///   - rows: 行
    ///   - columns: 列
    ///   - totalSize: 总宽高
    ///   - scale: 当前scrollview比例
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
    
    /// 绘制scale较小是的网格图层
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
        minScaleAxisLayer.fillColor = UIColor.clear.cgColor
        self.layer.insertSublayer(minScaleAxisLayer,at: 0)
        
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
        self.layer.insertSublayer(minScaleBorderLayer, above: minScaleAxisLayer)
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
        //画行
        for i in 0...rows {
            path.move(to: CGPoint(x:0, y: cellHeight * CGFloat(i)))
            path.addLine(to: CGPoint(x: totalSize.width, y: cellHeight * CGFloat(i)))
        }
        
        //画列
        for i in 0...columns {
            path.move(to: CGPoint(x: cellWidth * CGFloat(i), y: 0))
            path.addLine(to: CGPoint(x: cellWidth * CGFloat(i), y: totalSize.height))
        }
        
        maxScaleAxisLayer.path = path.cgPath
        maxScaleAxisLayer.lineJoin = .round
        maxScaleAxisLayer.lineDashPattern = [4]
        maxScaleAxisLayer.lineWidth = 1.0
        maxScaleAxisLayer.strokeColor = RGB(r: 179, g: 179, b: 179).cgColor
        // 性能优化设置
        maxScaleAxisLayer.shouldRasterize = true
        maxScaleAxisLayer.rasterizationScale = UIScreen.main.scale
        maxScaleAxisLayer.drawsAsynchronously = true
        self.layer.insertSublayer(maxScaleAxisLayer, at: 0)
    }
    
    /// 根据可视范围创建数字坐标图层
    /// - Parameter visableRect: 可视范围
    func createNumberLayers(visableRect:CGRect) {
        
        guard !visableRect.origin.x.isInfinite && !visableRect.origin.y.isInfinite else {
            return
        }
        
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
                    let number = row * GridConfig.itemMaxColumn + column + 1
                    let textLayer = addNumberToLayer(row: row,
                                                     column: column,
                                                     number: number,
                                                     gridSize: GridConfig.gridMaxSize)
                    
                    //不能覆盖在设备图层上
                    if let lampLayer = lampLayers.first(where: { $0.lamp.position == number && $0.superlayer != nil }) {
                        self.layer.insertSublayer(textLayer, below: lampLayer)
                    }
                    else {
                        self.layer.addSublayer(textLayer)
                    }
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
        textLayer.alignmentMode = .right
        textLayer.contentsScale = UIScreen.main.scale
        
        let trail:CGFloat = 4
        
        textLayer.frame = CGRect(x: x,
                                 y: y,
                                 width: itemWidth - trail,
                                 height: itemHeight)
        
        return textLayer
    }
    
    //创建设备图层
    func createFixtureLayers(layouts:[AULampLayout]) {
        lampLayers.forEach { $0.removeFromSuperlayer() }
        lampLayers.removeAll()
        
        for lamp in layouts {
            let lampLayer = AULampLayoutLayer(lamp: lamp)
            lampLayers.append(lampLayer)
        }
    }
    
    //设备图层添加
    func addFixtureLayers(visableRect:CGRect) {
        guard !visableRect.origin.x.isInfinite && !visableRect.origin.y.isInfinite else {
            return
        }
        
        if shouldDrawFixture {
            //通过可视范围计算行、列范围
            let minRowNum = min(Int(floor(visableRect.minY / GridConfig.itemMaxHeight)),
                                GridConfig.itemMaxRow)
            let maxRowNum = min(Int(ceil(visableRect.maxY / GridConfig.itemMaxHeight)),
                                GridConfig.itemMaxRow)
            let minColumnNum = min(Int(floor(visableRect.minX / GridConfig.itemMaxWidth)),
                                   GridConfig.itemMaxColumn)
            let maxColumnNum = min(Int(ceil(visableRect.maxX / GridConfig.itemMaxWidth)),
                                   GridConfig.itemMaxColumn)
            
            //已经添加了的设备图层
            let addedLayers = lampLayers.filter { $0.superlayer != nil }
            //仍未添加的设备图层
            let unAddedLayers = lampLayers.filter { $0.superlayer == nil }
            
            //已经添加的图层已经不在可视范围内 移除
            for layer in addedLayers {
                let (row,column) = layer.numToRowColumn()
                if row < minRowNum || row > maxRowNum || column < minColumnNum || column > maxColumnNum {
                    layer.removeFromSuperlayer()
                }
            }
            
            //未添加的图层在可视范围内 添加
            for layer in unAddedLayers {
                let (row,column) = layer.numToRowColumn()
                if (row >= minRowNum && row <= maxRowNum) && (column >= minColumnNum && column <= maxColumnNum) {
                    self.layer.addSublayer(layer)
                    let x = CGFloat(column) * GridConfig.itemMaxWidth
                    let y = CGFloat(row) * GridConfig.itemMaxHeight
                    layer.frame = CGRect(x: x,
                                         y: y,
                                         width: GridConfig.itemMaxWidth,
                                         height: GridConfig.itemMaxHeight)
                }
            }
        }
        else {
            // 清除旧图层
            lampLayers.forEach { $0.removeFromSuperlayer() }
        }
    }
}

//MARK: - 点击手势
extension GridView {
    
    /// 点击手势响应事件
    /// - Parameter gesture: 点击手势
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let tapPoint = gesture.location(in: self)
        guard let lampLayer = lampLayers.first(where: { $0.superlayer != nil && $0.frame.contains(tapPoint) }) else { return }
        // 点击空白区域时还原选中
        lampLayer.tapAction()
        
        //选中的图层摆在最上面
        if lampLayer.lamp.isSelected {
            lampLayer.removeFromSuperlayer()
            self.layer.addSublayer(lampLayer)
        }
        //反选的图层居于其它设备图层之下
        else {
            //两边的设备如果是选中状态
            let aboveLayers = lampLayers.filter { temp in
                temp.lamp.isSelected &&
                (temp.lamp.position == lampLayer.lamp.position - 1 || temp.lamp.position == lampLayer.lamp.position + 1)
            }
            //将其图层至于反选的设备图层之上
            aboveLayers.forEach { temp in
                temp.removeFromSuperlayer()
                self.layer.insertSublayer(temp, above: lampLayer)
            }
        }
    }
}
