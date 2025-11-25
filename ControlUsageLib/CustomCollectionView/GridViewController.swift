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
    
    /// 方格图左边距(计算获得)
    static var gridViewLeading:CGFloat = 0
    
    /// 方格图上边距（计算获得）
    static var gridViewTop:CGFloat = 0
    
    /// 最小比例
    static let minScale:CGFloat = 0.04
    
    /// 首次显示比例
    static let firstShowScale:CGFloat = 0.05
    
    /// 普通比例
    static let normalScale:CGFloat = 1
    
    /// scale超过多少可以画序号
    static let gridShouldDrawNumScale:CGFloat = 0.5
    
    /// scale超过多少可以画设备
    static let gridShouldDrawFixtureScale:CGFloat = 0.5
    
    /// 背景颜色
    static let gridBgColor = RGB(r: 120, g: 120, b: 120)
    
    /// 单个设备背景颜色
    static let itemBgColor = RGB(r: 51, g: 51, b: 51)
    
    /// 单个设备边框颜色
    static let itemBorderColor = RGB(r: 120, g: 120, b: 120)
    
    /// item选中边框颜色
    static let itemSelectedBorderColor = RGB(r: 70, g: 170, b: 95)
    
    /// item边框错误颜色
    static let itemErrorBorderColor = RGB(r: 252, g: 80, b: 70)
}

class GridViewController: UIViewController {
    
    var scrollView: TwoFingerScrollView!
    
    /// 网格视图
    lazy var gridView = {
        let view = GridView()
        view.delegate = self
        return view
    }()
    
    /// 灯位图设备对象集合
    private var lamps:[AULampLayout] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationController?.navigationBar.isHidden = true
        createFixtureLayoutOjects()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        GridConfig.gridViewLeading = (view.bounds.width - GridConfig.gridMinSize.width) / 2
        GridConfig.gridViewTop = (view.bounds.height - GridConfig.gridMinSize.height) / 2
        
        // 创建 UIScrollView
        scrollView = TwoFingerScrollView(frame: CGRect(x: 0,
                                                       y: 20,
                                                       width: view.bounds.width,
                                                       height: view.bounds.height))
        scrollView.delegate = self
        scrollView.minimumZoomScale = GridConfig.minScale
        scrollView.maximumZoomScale = GridConfig.normalScale
        scrollView.zoomScale = 1
        //缩放时无弹跳
        scrollView.bouncesZoom = false
        //滑动时无弹跳
        scrollView.bounces = false
        //默认边距范围
        scrollView.contentInset = UIEdgeInsets(top: GridConfig.gridViewTop,
                                               left: GridConfig.gridViewLeading,
                                               bottom: GridConfig.gridViewTop,
                                               right: GridConfig.gridViewLeading)
        
        view.addSubview(scrollView)
        
        // 创建网格视图
        gridView.configureGrid(totalSize: GridConfig.gridMaxSize,
                               layouts: lamps)
        gridView.drawScaleAxisPath(rows: GridConfig.itemMaxRow,
                                   columns: GridConfig.itemMaxColumn,
                                   totalSize: GridConfig.gridMaxSize,
                                   scale: scrollView.zoomScale)
        
        
        // 添加到 scrollView
        scrollView.addSubview(gridView)
        updateContentSize()
//        //初始scale为0.05
//        scrollView.setZoomScale(GridConfig.firstShowScale,
//                                animated: false)
//        //居中GridView
//        centeredGridView()
        createVisableLayers()
    }

    
    // 更新 contentSize，确保包含边距
    func updateContentSize() {
        let currentSize = gridView.frame.size
        scrollView.contentSize = CGSize(
            width: currentSize.width,
            height: currentSize.height
        )
    }
    
    /// 格局可视范围绘制坐标数字
    func createVisableLayers() {
        //获取可视范围
        let visableRect = currentVisibleRect()
        //根据可视范围绘制坐标
        gridView.refreshVisableLayers(visableRect: visableRect)
        gridView.addFixtureLayers(visableRect: visableRect)
    }
    
    /// 获取当前可视范围
    /// - Returns: 当前可视范围
    func currentVisibleRect() -> CGRect {
        //将scrollview的坐标系转换为GridView的坐标系
        let rectInGrid = scrollView.convert(scrollView.bounds, to: gridView)
        let visableRect = gridView.bounds.intersection(rectInGrid)
        print("转换后的GridView范围为\(rectInGrid),可视范围为\(visableRect)")
        return visableRect
    }
    
    /// 居中GridView
    func centeredGridView() {
        let contentSize = gridView.frame.size
        let visibleWidth = scrollView.bounds.width - scrollView.contentInset.left - scrollView.contentInset.right
        let visibleHeight = scrollView.bounds.height - scrollView.contentInset.top - scrollView.contentInset.bottom
        // 计算居中所需的 offset（考虑 contentInset）
        let offsetX = -(visibleWidth - contentSize.width) / 2 - scrollView.contentInset.left
        let offsetY = -(visibleHeight - contentSize.height) / 2 - scrollView.contentInset.top
        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
    }
    
    /// 创建临时设备对象
    func createFixtureLayoutOjects() {
        lamps.removeAll()
        for i in 0..<20 {
            let lamp = AULampLayout()
            lamp.UUID = UUID().uuidString
            lamp.position = i + 1
            lamps.append(lamp)
        }
    }
}

extension GridViewController:GridViewDelegate {
    
    func gridViewBeginPanLamp() {
//        //拖动设备时 scrollview禁止拖动
//        scrollView.isScrollEnabled = false
//        scrollView.panGestureRecognizer.isEnabled = false
//        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    func gridViewEndPanLamp() {
//        //结束拖动设备 scrollview恢复拖动
//        scrollView.isScrollEnabled = true
//        scrollView.panGestureRecognizer.isEnabled = true
//        scrollView.pinchGestureRecognizer?.isEnabled = true
    }
}
