//   GridView.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/11/24
//   


import Foundation



//GridView拖动手势触发操作
enum AUGridViewPanMode {
    //拖动选中设备图层
    case draggingLayer
    //框选设备图层
    case selectionBox
}

/// 自定义网格图
final class GridView:UIView {

    // 使用 CALayer 来提高性能
    var numsLayers: [CALayer] = []
    
    // scale较低时的CAShapeLayer网格实现
    var minScaleAxisLayer:CAShapeLayer = CAShapeLayer()
    
    // scale较低时的CAShapeLayer边界分区线条实现
    var minScaleBorderLayer:CAShapeLayer = CAShapeLayer()
    
    // 设备图层
    var lampLayers:[AULampLayoutLayer] = []
    
    /// 正常scale时虚线图层
    var maxScaleDeshLayers:[CAShapeLayer] = []
    
    //当前scale
    private(set) var scale:CGFloat = 0
    
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
    
    /// 灯位图设备大小状态
    var lampLayoutStatus:AULampLyoutStatus = .normal
    
    //当前选中的设备
    private var selectedLampLayer:AULampLayoutLayer?
    
    /// 点击手势
    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.numberOfTapsRequired = 1
        return tap
    }()
    
    /// 拖动手势
    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        return pan
    }()
    
    /// 拖动开始时选中的图层及其原始位置
    var draggingLayers: [(layer: AULampLayoutLayer,originalFrame: CGRect)] = []
    
    /// 拖动开始后预测落点的虚线图层
    var panPredictedLayers:[CAShapeLayer] = []
    
    /// 拖动手势对应的模式
    var panMode:AUGridViewPanMode = .draggingLayer
    
    /// 拖动起始点
    var panStartLocation:CGPoint = .zero
    
    /// 框选图层
//    var panSelectionBoxLayer:CAShapeLayer? = nil
    var panSelectionBoxLayer:AUGridViewSelectionBoxLayer? = nil
    
    /// 外部委托
    weak var delegate:GridViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addGestureRecognizer(tapGestureRecognizer)
        addGestureRecognizer(panGestureRecognizer)
        isUserInteractionEnabled = true
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addGestureRecognizer(tapGestureRecognizer)
        addGestureRecognizer(panGestureRecognizer)
        isUserInteractionEnabled = true
    }
    
    func configureGrid(totalSize: CGSize,
                       layouts:[AULampLayout],
                       scale:CGFloat = 1) {
        // 设置视图的frame
        self.frame = CGRect(x: 0,
                            y: 0,
                            width: totalSize.width,
                            height: totalSize.height)
        self.backgroundColor = .black
        //初始化当前scale
        self.scale = scale
        //创建设备图层
        recreateFixtureLayers(layouts: layouts,scale: scale)
    }
    
    /// 修改当前scale 部分重绘需根据scale变化执行
    /// - Parameter scale: 当前scale
    /// - Parameter layouts: 设备图层
    func resetScale(scale:CGFloat,
                    layouts:[AULampLayout]) {
        
        //当前scale变化且少于正常大小才绘制坐标轴
        if self.scale != scale && scale < GridConfig.normalScale {
            drawMinScaleAxisPath(rows: GridConfig.itemMaxRow,
                                 columns: GridConfig.itemMaxColumn,
                                 totalSize: GridConfig.gridMaxSize,
                                 scale:scale)
        }
        
        //新的灯位图设备大小状态
        let newlampLayoutStatus:AULampLyoutStatus = scale >= GridConfig.gridShouldDrawFixtureScale ? .normal : .small
        //如果灯位图大小状态与之前不同
        if self.lampLayoutStatus != newlampLayoutStatus {
            //重新根据当前scale创建设备图层
            recreateFixtureLayers(layouts: layouts,scale: scale)
        }
        
        self.scale = scale
        self.lampLayoutStatus = newlampLayoutStatus
    }
    
}

extension GridView:UIGestureRecognizerDelegate {

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.panGestureRecognizer {
            return gestureRecognizer.numberOfTouches == 1
        }
        return true
    }
}



extension GridView {
    
    /// 获取指定图层数组中层级最低的图层索引
    /// - Parameter layers: 指定图层数组
    /// - Returns: 图层数组中层级最低的图层索引
    func getLayersMinZIndex(layers:[CALayer]) -> Int{
        if let sublayers = self.layer.sublayers {
            let indexs = layers.compactMap { tempLayer in
                sublayers.firstIndex(of: tempLayer)
            }
            return indexs.min() ?? 0
        }
        return 0
    }
}

