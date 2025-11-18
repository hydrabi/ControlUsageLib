//   backup.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/11/17
//   


import Foundation
class GridView: UIView {
    var numberOfRows: Int = 0
    var numberOfColumns: Int = 0
    var gridSize: CGSize = .zero
    
    // 使用 CALayer 存储所有网格图层
    private var gridLayers: [CALayer] = []
    
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
        self.frame = CGRect(x: GridConfig.gridViewPadding,
                            y: GridConfig.gridViewPadding,
                            width: totalSize.width,
                            height: totalSize.height)
        
        // 创建网格图层
        createGridLayers()
    }
    
    // 创建所有网格图层
    private func createGridLayers() {
        // 清除旧图层
        gridLayers.forEach { $0.removeFromSuperlayer() }
        gridLayers.removeAll()
        
        // 生成随机颜色数据
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemTeal]
        
        // 批量创建图层以提高性能
        for row in 0..<numberOfRows {
            for column in 0..<numberOfColumns {
                let number = row * numberOfColumns + column + 1
                let color = colors[number % colors.count] // 使用序号来决定颜色，保证一致性
                
                let layer = createGridLayer(
                    row: row,
                    column: column,
                    color: color,
                    number: number
                )
                
                self.layer.addSublayer(layer)
                gridLayers.append(layer)
            }
        }
    }
    
    // 创建单个网格图层
    private func createGridLayer(row: Int, column: Int, color: UIColor, number: Int) -> CALayer {
        let x = CGFloat(column) * gridSize.width
        let y = CGFloat(row) * gridSize.height
        
        // 创建主图层
        let layer = CALayer()
        layer.frame = CGRect(x: x, y: y, width: gridSize.width, height: gridSize.height)
        layer.backgroundColor = color.cgColor
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        layer.contentsScale = UIScreen.main.scale // 确保高分辨率显示
        
        // 添加序号文本图层
        addNumberToLayer(layer, number: number)
        
        return layer
    }
    
    // 在图层上添加序号文本
    private func addNumberToLayer(_ layer: CALayer, number: Int) {
        let textLayer = CATextLayer()
        textLayer.string = "\(number)"
        textLayer.fontSize = 12
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale // 确保文本清晰
        
        // 计算文本位置（居中）
        let textHeight: CGFloat = 14
        textLayer.frame = CGRect(
            x: 0,
            y: layer.bounds.midY - textHeight / 2,
            width: layer.bounds.width,
            height: textHeight
        )
        
        layer.addSublayer(textLayer)
    }
}
