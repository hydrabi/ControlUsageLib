//   GridView+Pan.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/11/25
//   


import Foundation

//MARK: - 拖动手势
extension GridView {
    
    /// 拖动手势响应事件
    /// - Parameter gesture: 拖动手势
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            handlePanBegan(at: location)
        case .changed:
            if panMode == .draggingLayer {
                handleDragChanged(at: location, translation: gesture.translation(in: self))
            }
            else if panMode == .selectionBox {
                handleSelectionBoxChange(at: location)
            }
        case .ended, .cancelled:
            if panMode == .draggingLayer {
                handleDragEnded(at: location, translation: gesture.translation(in: self))
            }
            else if panMode == .selectionBox {
                handleSelectionBoxEnd()
            }
        default:
            break
        }
    }
    
    /// 拖动开始
    func handlePanBegan(at location: CGPoint) {
        // 检查是否点击在选中的图层上
        let selectedLayers = lampLayers.filter { $0.lamp.isSelected && $0.superlayer != nil }
        //如果有选中设备图层且落点处于其中一个图层中
        if selectedLayers.count > 0,
           let hitLayer = selectedLayers.first(where: { $0.frame.contains(location) }) {
            //当前拖动模式为拖动选中设备图层
            handleDragBegan(selectedLayers: selectedLayers)
        }
        //如果落点不在选中的设备 当前拖动模式为框选
        else {
            handleSelectionBoxBegan(at: location)
        }
    }
    
    /// 恢复原始位置
    func restoreOriginalPositions() {
        for item in draggingLayers {
            item.layer.frame = item.originalFrame
        }
    }
    
    /// 应用新位置
    func applyNewPositions(gridOffsetX: Int, gridOffsetY: Int) {
        for item in draggingLayers {
            // 基于原始位置计算新位置
            let (originalRow,originalColumn) = item.layer.numToRowColumn()
            
            let newRow = originalRow + gridOffsetY
            let newColumn = originalColumn + gridOffsetX
            
            guard newRow >= 0 && newRow < GridConfig.itemMaxRow &&
                  newColumn >= 0 && newColumn < GridConfig.itemMaxColumn else {
                continue
            }
            
            // 更新 position
            let newPosition = newRow * GridConfig.itemMaxColumn + newColumn + 1
            item.layer.lamp.position = newPosition
            
            // 更新 frame
            let newX = CGFloat(newColumn) * GridConfig.itemMaxWidth
            let newY = CGFloat(newRow) * GridConfig.itemMaxHeight
            item.layer.frame = CGRect(x: newX,
                                     y: newY,
                                     width: GridConfig.itemMaxWidth,
                                     height: GridConfig.itemMaxHeight)
        }
    }
    
    /// 计算拖动后网格偏移量
    /// - Parameter translation: 拖动的平移位置
    /// - Returns: 拖动后网格偏移量
    func getGridPanOffset(translation: CGPoint) -> (gridOffsetX:Int,gridOffsetY:Int) {
        let minOriginX = draggingLayers.min(by: { $0.originalFrame.minX < $1.originalFrame.minX })?.originalFrame.minX ?? 0
        let maxOriginX = draggingLayers.max(by: { $0.originalFrame.minX < $1.originalFrame.minX })?.originalFrame.minX ?? 0
        let minOriginY = draggingLayers.min(by: { $0.originalFrame.minY < $1.originalFrame.minY })?.originalFrame.minY ?? 0
        let maxOriginY = draggingLayers.max(by: { $0.originalFrame.minY < $1.originalFrame.minY })?.originalFrame.minY ?? 0
        
        var newTranslationX = translation.x
        var newTranslationY = translation.y
        
        //滑动的设备以四个方向的边缘设备为限制 但即使超出边缘拖动也能调整位置
        //不能超过最左侧
        if minOriginX + translation.x < 0 {
            newTranslationX = 0 - minOriginX
        }
        
        //不能超过最右侧 需要减去一个item的宽度
        if maxOriginX + translation.x > GridConfig.gridMaxSize.width - GridConfig.itemMaxWidth {
            newTranslationX = GridConfig.gridMaxSize.width - GridConfig.itemMaxWidth - maxOriginX
        }
        
        //不能超过最上侧
        if minOriginY + translation.y < 0 {
            newTranslationY = 0 - minOriginY
        }
        
        //不能超过最下侧 需要减去一个item的高度
        if maxOriginY + translation.y > GridConfig.gridMaxSize.height - GridConfig.itemMaxHeight {
            newTranslationY = GridConfig.gridMaxSize.height - GridConfig.itemMaxHeight - maxOriginY
        }
        
        // 计算网格偏移量
        return (Int(round(newTranslationX / GridConfig.itemMaxWidth)),
                Int(round(newTranslationY / GridConfig.itemMaxHeight)))
    }
    
}

//MARK: - 拖动预测位置
extension GridView {
    
    /// 获取拖动时选中的灯位图设备预测的位置和停止手势后是否可以执行调整位置
    /// - Parameters:
    ///   - gridOffsetX: 平移的x轴位置
    ///   - gridOffsetY: 平移的y轴位置
    /// - Returns: （选中的灯位图设备预测的位置，停止手势后是否可以执行调整位置）
    func getGridPanPredictedFrame(gridOffsetX:Int,gridOffsetY:Int) -> ([(targetPosition:Int,frame:CGRect)],Bool) {
        // 预测拖动后的位置
        var predictedFrames: [(Int,CGRect)] = []
        // 如果拖动到有被占用的位置 最终放手后应该回到原有位置
        var canMove = true
        
        for item in draggingLayers {
            // 基于原始位置计算新位置
            let (originalRow,originalColumn) = item.layer.numToRowColumn()
            //平移后新的行、列
            let newRow = originalRow + gridOffsetY
            let newColumn = originalColumn + gridOffsetX
            //是否被占用
            var isOccupied = false
            
            // 边界检查
            guard newRow >= 0 && newRow < GridConfig.itemMaxRow &&
                  newColumn >= 0 && newColumn < GridConfig.itemMaxColumn else {
                canMove = false
                continue
            }
            
            // 计算目标位置
            let targetPosition = newRow * GridConfig.itemMaxColumn + newColumn + 1
            
            // 检查目标位置是否已有其他图层（排除正在拖动的图层）
            let draggingLayerSet = Set(draggingLayers.map { $0.layer })
            
            if let _ = lampLayers.first(where: {
                //目标位置是否已经被占用
                $0.lamp.position == targetPosition &&
                //拖动图层不在判断范围中
                !draggingLayerSet.contains($0)
            }) {
                //如果已经有占用的设备 放手后不能移动
                canMove = false
                isOccupied = true
            }
            
            //计算预测的frame
            let newX = CGFloat(newColumn) * GridConfig.itemMaxWidth
            let newY = CGFloat(newRow) * GridConfig.itemMaxHeight
            predictedFrames.append((targetPosition,
                                    CGRect(x: newX,
                                           y: newY,
                                           width: GridConfig.itemMaxWidth,
                                           height: GridConfig.itemMaxHeight)))
        }
        
        return (predictedFrames,canMove)
    }
    
    /// 创建预测位置图层
    func createPanPredictedLayers() {
        removeAllPanPredictedLayers()
        for _ in draggingLayers {
            let layer = CAShapeLayer()
            layer.lineWidth = 2
            layer.strokeColor = GridConfig.itemSelectedBorderColor.cgColor
            layer.fillColor = UIColor.clear.cgColor
            if self.scale >= GridConfig.normalScale {
                layer.lineDashPattern = [4]
            }
            panPredictedLayers.append(layer)
        }
    }
    
    /// 更新预测位置图层参数
    /// - Parameters:
    ///   - predictedFrames: 预测位置图层参数
    ///   - canMove: 最终是否能够移动
    func updatePanPredictedLayers(predictedFrames:[(targetPosition:Int,frame:CGRect)],canMove:Bool) {
        let minIndex = getLayersMinZIndex(layers: draggingLayers.map({ $0.layer }))
        for (index,layer) in panPredictedLayers.enumerated() {
            if predictedFrames.count > index {
                let path = UIBezierPath(rect: CGRect(x: 0,
                                                     y: 0,
                                                     width: GridConfig.itemMaxWidth,
                                                     height: GridConfig.itemMaxHeight))
                if canMove {
                    layer.strokeColor = GridConfig.itemSelectedBorderColor.cgColor
                }
                else {
                    layer.strokeColor = GridConfig.itemErrorBorderColor.cgColor
                }
                layer.path = path.cgPath
                layer.frame = predictedFrames[index].frame

                if layer.superlayer == nil && minIndex > 0 {
                    self.layer.insertSublayer(layer, at: UInt32(minIndex - 1))
                }
                else if minIndex > 0 {
                    layer.removeFromSuperlayer()
                    self.layer.insertSublayer(layer, at: UInt32(minIndex - 1))
                }
            }
        }
    }
    
    /// 移除所有预测位置图层
    func removeAllPanPredictedLayers() {
        panPredictedLayers.forEach { $0.removeFromSuperlayer() }
        panPredictedLayers.removeAll()
    }
}

//MARK: - 拖动选中图层

extension GridView {
    /// 拖动选中设备开始
    /// - Parameter selectedLayers: 选中的设备图层
    func handleDragBegan(selectedLayers:[AULampLayoutLayer]) {
        panMode = .draggingLayer
        draggingLayers = selectedLayers.map { layer in
            (layer:layer,originalFrame:layer.frame)
        }
        
        //创建拖动预测图层
        createPanPredictedLayers()
    }
    
    /// 拖动中
    func handleDragChanged(at location: CGPoint, translation: CGPoint) {
        guard !draggingLayers.isEmpty else { return }
        print("拖动：location为\(location),translation为\(translation)")

        // 更新所有拖动图层的视觉位置
        for item in draggingLayers {
            // 基于原始位置计算新位置
            item.layer.frame = CGRect(x: item.originalFrame.minX + translation.x,
                                 y: item.originalFrame.minY + translation.y,
                                      width: item.layer.frame.width,
                                      height: item.layer.frame.height)
        }
        
        // 计算网格偏移量
        let offset = getGridPanOffset(translation: translation)
        //获取拖动后的预测位置
        let (predictedFrame,canMove) = getGridPanPredictedFrame(gridOffsetX: offset.gridOffsetX,
                                                                gridOffsetY: offset.gridOffsetY)
        //更新拖动预测图层
        updatePanPredictedLayers(predictedFrames: predictedFrame, canMove: canMove)
    }
    
    /// 拖动结束
    func handleDragEnded(at location: CGPoint, translation: CGPoint) {
        guard !draggingLayers.isEmpty else { return }
        
        // 计算网格偏移量
        let offset = getGridPanOffset(translation: translation)
        let gridOffsetX = offset.gridOffsetX
        let gridOffsetY = offset.gridOffsetY
        
        // 如果偏移量为0，恢复原始位置
        guard gridOffsetX != 0 || gridOffsetY != 0 else {
            restoreOriginalPositions()
            // 清空拖动状态
            draggingLayers.removeAll()
            return
        }
        
        //获取拖动后的预测位置
        let (_,canMove) = getGridPanPredictedFrame(gridOffsetX: gridOffsetX,
                                                         gridOffsetY: gridOffsetY)
        
        if canMove {
            // 应用新位置
            applyNewPositions(gridOffsetX: gridOffsetX, gridOffsetY: gridOffsetY)
        } else {
            // 恢复原始位置
            restoreOriginalPositions()
        }
        
        // 清空拖动状态
        draggingLayers.removeAll()
        //清空拖动预测图层
        removeAllPanPredictedLayers()
    }
}

//MARK: - 框选设备

extension GridView {
    
    /// 拖动框选设备开始
    /// - Parameter location: 手势起始位置
    func handleSelectionBoxBegan(at location:CGPoint) {
        panMode = .selectionBox
        panStartLocation = location
        
//        let layer = CAShapeLayer()
//        layer.fillColor = UIColor.clear.cgColor
//        layer.strokeColor = GridConfig.itemSelectedBorderColor.cgColor
//        let dash = NSNumber(value: 4 / self.scale)
//        layer.lineDashPattern = [dash]
//        layer.lineWidth = 2 / self.scale
//        self.layer.addSublayer(layer)
//        panSelectionBoxLayer = layer
        
        let layer = AUGridViewSelectionBoxLayer(scale: self.scale)
        panSelectionBoxLayer = layer
        self.layer.addSublayer(layer)
    }
    
    /// 框选位置大小改变
    /// - Parameters:
    ///   - location: 拖动位置
    func handleSelectionBoxChange(at location: CGPoint) {
        guard let layer = panSelectionBoxLayer else {return}
        let x = min(panStartLocation.x, location.x)
        let y = min(panStartLocation.y, location.y)
        let width = abs(location.x - panStartLocation.x)
        let height = abs(location.y - panStartLocation.y)
        
//        let rectPath = UIBezierPath(rect: CGRect(x: 0,
//                                             y: 0,
//                                             width: width,
//                                             height: height))
//        let rect = CGRect(x: x,
//                          y: y,
//                          width: width,
//                          height: height)
//        CATransaction.begin()
//        CATransaction.setDisableActions(true)
//        layer.path = rectPath.cgPath
//        layer.frame = rect
//        CATransaction.commit()
        
        layer.updateRect(CGRect(x: x, y: y, width: width, height: height))
    }
    
    /// 修改框选位置的设备选中状态为true
    /// - Parameter rect: 框选位置
    func updateSelectionBoxLampsSelected(rect:CGRect) {
        //按灯位图位置排序
        let sortedLampLayers = self.lampLayers.sorted { $0.lamp.position < $1.lamp.position }
        
        for lampLayer in sortedLampLayers where lampLayer.superlayer != nil {
            let lampRect = lampLayer.frame
            if rect.intersects(lampRect) {
                //强制设置该图层选中
                delegate?.gridViewDidTapLampLayout(lampLayout: lampLayer.lamp,
                                                   fource: true,
                                                   isSelected: true)
            }
        }
    }
    
    /// 框选结束
    func handleSelectionBoxEnd() {
        if let layer = panSelectionBoxLayer {
            //修改框选位置的设备选中状态为true
            updateSelectionBoxLampsSelected(rect: layer.frame)
            //刷新选中的设备图层
            refreshSelectedLampLayers()
        }
        
        panSelectionBoxLayer?.removeFromSuperlayer()
        panSelectionBoxLayer = nil
    }
}
