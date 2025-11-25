//   GridView+Visable.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/11/25
//   


import Foundation

extension GridView {
    
    /// 创建可视范围的图层
    /// - Parameter visableRect: 可视范围图层
    func refreshVisableLayers(visableRect:CGRect) {
        guard !visableRect.origin.x.isInfinite && !visableRect.origin.y.isInfinite else {
            return
        }

        createNumberLayers(visableRect: visableRect)
        createDeshLayers(visableRect: visableRect)
    }
    
    /// 根据可视范围创建数字坐标图层
    /// - Parameter visableRect: 可视范围
    func createNumberLayers(visableRect:CGRect) {

        // 清除旧图层
        numsLayers.forEach { $0.removeFromSuperlayer() }
        numsLayers.removeAll()

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
                    numsLayers.append(textLayer)
                }
            }
        }
    }
    
    /// 创建虚线图层
    /// - Parameter visableRect: 可视范围
    func createDeshLayers(visableRect:CGRect) {
        maxScaleDeshLayers.forEach { $0.removeFromSuperlayer() }
        maxScaleDeshLayers.removeAll()
        
        if scale >= GridConfig.normalScale {

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

                    let x = CGFloat(column) * GridConfig.itemMaxWidth
                    let y = CGFloat(row) * GridConfig.itemMaxHeight
                    
                    let path = UIBezierPath(rect: CGRect(x: 0,
                                                         y: 0,
                                                         width: GridConfig.itemMaxWidth,
                                                         height: GridConfig.itemMaxHeight))
                    
                    let deshLayer = CAShapeLayer()
                    deshLayer.path = path.cgPath
                    deshLayer.lineJoin = .round
                    deshLayer.lineDashPattern = [4]
                    deshLayer.lineWidth = 1.0
                    deshLayer.fillColor = UIColor.clear.cgColor
                    deshLayer.strokeColor = RGB(r: 179, g: 179, b: 179).cgColor
                    // 性能优化设置
                    deshLayer.shouldRasterize = true
                    deshLayer.rasterizationScale = UIScreen.main.scale
                    deshLayer.drawsAsynchronously = true
                    deshLayer.frame = CGRect(x: x,
                                             y: y,
                                             width: GridConfig.itemMaxWidth,
                                             height: GridConfig.itemMaxHeight)
                    
                    self.layer.addSublayer(deshLayer)
                    maxScaleDeshLayers.append(deshLayer)
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
}
