//   GridView+Fixture.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/11/26
//   


import Foundation

extension GridView {
        
    //创建设备图层
    func recreateFixtureLayers(layouts:[AULampLayout],scale:CGFloat) {
        lampLayers.forEach { $0.removeFromSuperlayer() }
        lampLayers.removeAll()
        
        for lamp in layouts {
            //根据当前scale创建指定的图层
            var status = AULampLyoutStatus.normal
            if scale < GridConfig.gridShouldDrawFixtureScale {
                status = .small
            }
            let lampLayer = AULampLayoutLayer(lamp: lamp,status: status)
            lampLayers.append(lampLayer)
        }
    }
    
    //设备图层添加
    func addFixtureLayers(visableRect:CGRect) {
        guard !visableRect.origin.x.isInfinite && !visableRect.origin.y.isInfinite else {
            return
        }
        
//        if shouldDrawFixture {
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
            //选中的图层
            let selectedLayers = lampLayers.filter { $0.lamp.isSelected }
            
            //已经添加的图层已经不在可视范围内 移除
            for layer in addedLayers {
                let (row,column) = layer.numToRowColumn()
                if row < minRowNum || row > maxRowNum || column < minColumnNum || column > maxColumnNum {
                    layer.removeFromSuperlayer()
                }
                else {
                    //否则将图层移到最顶点
                    layer.removeFromSuperlayer()
                    self.layer.addSublayer(layer)
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
            
            //拖动图层在最顶层
            for layer in selectedLayers {
                if layer.superlayer != nil {
                    //将图层移到最顶点
                    layer.removeFromSuperlayer()
                    self.layer.addSublayer(layer)
                }
            }
//        }
//        else {
//            // 清除旧图层
//            lampLayers.forEach { $0.removeFromSuperlayer() }
//        }
    }
}

//MARK: - 点击手势
extension GridView {
    
    /// 点击灯位图设备手势响应事件
    /// - Parameter gesture: 点击手势
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let tapPoint = gesture.location(in: self)
        guard let lampLayer = lampLayers.first(where: { $0.superlayer != nil && $0.frame.contains(tapPoint) }) else { return }
        //通知点击灯位图设备
        delegate?.gridViewDidTapLampLayout(lampLayout: lampLayer.lamp)
        // 点击空白区域时还原选中
        lampLayer.refreshUI()
        
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
            
            //反选后因为选中数字改变，其它选中的设备图层需要刷新
            let selectedLayers = lampLayers.filter { $0.lamp.isSelected }
            selectedLayers.forEach { $0.refreshUI() }
        }
    }
}
