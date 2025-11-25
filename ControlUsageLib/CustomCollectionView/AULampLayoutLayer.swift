//   LampLayoutLayer.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/11/21
//   


import Foundation
import SnapKit

/// 灯位图设备对象
final class AULampLayout: NSObject {
    
    /// 唯一标识
    var UUID:String =  ""
    
    /// project唯一标识
    var projectUUID:String = ""
    
    /// 对应设备唯一标识
    var fixtureUUID:String = ""
    
    /// 更新时间戳
    var updateTime:String = ""
    
    /// 创建时间戳
    var createTime:String = ""
    
    /// 对应
    var position:Int = 1
    
    /// 是否切换到像素
    var isPixel:Int = 0
    
    /// 切换到像素时选择的分区
    var pixelsNum:String = ""
    
    /// 切换到像素时，像素的排列方向
    var pixelsDirection:Int = 0
    
    /// 全部分区
    var pixelRange:Int = 0
    
    /// 是否被选中
    var isSelected:Bool = false
    
    /// 选中数字
    var selectedNum:Int = 1
}

/// 灯位图设备图层
final class AULampLayoutLayer: CALayer {
    
    /// 单个设备layout最大宽度
    let itemWidth:CGFloat = 100
    
    /// 单个设备layout最大高度
    let itemHeight:CGFloat = 100
    
    /// 对应的灯位图设备对象
    var lamp:AULampLayout = AULampLayout()
    
    //图层
    lazy var iconLayer:CALayer = {
        let layer = CALayer()
//        layer.contents = UIImage(named: "fixture_icon_000c5")
        layer.backgroundColor = UIColor.white.cgColor
        layer.cornerRadius = 17
        layer.masksToBounds = true
        return layer
    }()
    
    //序号
    lazy var numLayer:CATextLayer = {
        let layer = CATextLayer()
        layer.foregroundColor = RGBA(r: 255, g: 255, b: 255, a: 0.8).cgColor
        layer.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        layer.fontSize = 14
        layer.alignmentMode = .right
        layer.contentsScale = UIScreen.main.scale
        return layer
    }()
    
    //状态图层
    lazy var statusLayer:CALayer = {
        let layer = CALayer()
        layer.borderColor = RGB(r: 155, g: 239, b: 176).cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 5
        layer.masksToBounds = true
        layer.backgroundColor = RGB(r: 70, g: 170, b: 95).cgColor
        return layer
    }()
    
    //图层
    lazy var nameLayer:CATextLayer = {
        let layer = CATextLayer()
        layer.contentsScale = UIScreen.main.scale
        layer.isWrapped = true
        layer.truncationMode = .end
        layer.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        layer.fontSize = 10
        return layer
    }()
    
    //地址
    lazy var addressLayer:CATextLayer = {
        let layer = CATextLayer()
        layer.contentsScale = UIScreen.main.scale
        layer.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        layer.fontSize = 10
        layer.foregroundColor = RGBA(r: 255, g: 255, b: 255,a: 0.6).cgColor
        return layer
    }()
    
    //universe
    lazy var universeLayer:CATextLayer = {
        let layer = CATextLayer()
        layer.contentsScale = UIScreen.main.scale
        layer.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        layer.fontSize = 10
        layer.foregroundColor = RGBA(r: 255, g: 255, b: 255,a: 0.6).cgColor
        return layer
    }()
    
    //选中数字
    lazy var selectedNumLayer:CATextLayer = {
        let layer = CATextLayer()
        layer.contentsScale = UIScreen.main.scale
        layer.alignmentMode = .right
        return layer
    }()
    
    /// 边框
    lazy var borderLayer:CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = GridConfig.itemBorderColor.cgColor
        layer.lineWidth = 2
        layer.fillColor = UIColor.clear.cgColor
        return layer
    }()
    
    init(lamp:AULampLayout) {
        self.lamp = lamp
        super.init()
        configUI()
        refresh()
    }
    
    override init() {
        super.init()
        configUI()
        refresh()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configUI()
        refresh()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        configUI()
        refresh()
    }
    
    func configUI() {
        backgroundColor = GridConfig.itemBgColor.cgColor
        
        addSublayer(iconLayer)
        addSublayer(numLayer)
        addSublayer(statusLayer)
        addSublayer(nameLayer)
        addSublayer(addressLayer)
        addSublayer(universeLayer)
        addSublayer(selectedNumLayer)
        addSublayer(borderLayer)
        
        let leading:CGFloat = 10
        let iconWH:CGFloat = 34
        let statusWH:CGFloat = 10
        let selectedNumWH:CGFloat = 15
        
        //图标
        iconLayer.frame = CGRect(x: leading,
                                 y: 5,
                                 width: iconWH,
                                 height: iconWH)
        
        //数字
        numLayer.frame = CGRect(x: leading + iconWH + 10,
                                y: 10,
                                width: itemWidth - leading - iconWH - leading - leading,
                                height: 15)
        
        //状态
        statusLayer.frame = CGRect(x: leading,
                                   y: iconLayer.frame.maxY + leading,
                                   width: statusWH,
                                   height: statusWH)
        
        //地址
        addressLayer.frame = CGRect(x: leading,
                                    y: statusLayer.frame.maxY + 2,
                                    width: itemWidth - leading - leading,
                                    height: 13)
        
        //universe
        universeLayer.frame = CGRect(x: leading,
                                     y: addressLayer.frame.maxY + 1,
                                     width: itemWidth - leading * 2 - selectedNumWH,
                                     height: 13)
        
        //设置边框
        let borderPath = UIBezierPath(rect: CGRect(x: 0,
                                                   y: 0,
                                                   width: itemWidth,
                                                   height: itemHeight))
        borderLayer.path = borderPath.cgPath
    }
    
    func refresh() {
        let leading:CGFloat = 10
        let selectedNumWH:CGFloat = 15

        //数字
        numLayer.string = "\(lamp.position)"
        
        //名称
        let nameWidth = itemWidth - statusLayer.frame.maxX - 2 - leading
        var nameHeight = "LS 1200X testtest test test test #1".heightFor(font: UIFont.systemFont(ofSize: 10, weight: .bold),
                                                 width: nameWidth)
        nameHeight = min(nameHeight, 30)
        let nameX = statusLayer.frame.maxX + 2
        let nameY = iconLayer.frame.maxY + (30 - nameHeight) / 2
        nameLayer.frame = CGRect(x: nameX,
                                 y: nameY,
                                 width: nameWidth,
                                 height: nameHeight)
        nameLayer.string = "LS 1200X testtest test test test #1"
        
        //地址
        addressLayer.string = "Adress: 30"
        
        //universe
        universeLayer.string = "Universe:A/1"
        
        //选中数字
        selectedNumLayer.frame = CGRect(x: itemWidth - selectedNumWH - leading,
                                        y: itemWidth - selectedNumWH - leading,
                                        width: selectedNumWH,
                                        height: selectedNumWH)
        let selectedNumAttributeString = NSMutableAttributedString(string: "1")
        selectedNumAttributeString.addAttribute(.foregroundColor, value: RGB(r: 70, g: 170, b: 95),
                                             range: NSMakeRange(0, selectedNumAttributeString.length))
        selectedNumAttributeString.addAttribute(.font,
                                                value: UIFont.systemFont(ofSize: 12, weight: .medium),
                                             range: NSMakeRange(0, selectedNumAttributeString.length))
        selectedNumLayer.string = selectedNumAttributeString
    }
    
    /// 刷新边框
    func refreshBorder() {
        if lamp.isSelected {
            borderLayer.strokeColor = GridConfig.itemSelectedBorderColor.cgColor
        }
        else {
            borderLayer.strokeColor = GridConfig.itemBorderColor.cgColor
        }
    }
    
    /// 点击操作
    func tapAction() {
        lamp.isSelected = !lamp.isSelected
        refreshBorder()
    }
    
    /// 通过序号计算行、列
    /// - Returns: 行、列组成的元组
    func numToRowColumn() -> (row:Int,column:Int) {
        //序号从1开始 行列从0开始
        let row = (lamp.position - 1) / GridConfig.itemMaxColumn
        let column = (lamp.position - 1)  % GridConfig.itemMaxColumn
        return (row,column)
    }
    
    
}
