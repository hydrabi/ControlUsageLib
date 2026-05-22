//   GridView+Axis.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/11/26
//   


import Foundation

extension GridView {
    
    /// 绘制scale较小是的网格图层
    /// - Parameters:
    ///   - rows: 行
    ///   - columns: 列
    ///   - totalSize: 宽高
    func drawMinScaleAxisPath(rows: Int, columns: Int, totalSize: CGSize,scale:CGFloat = 1) {
        minScaleAxisLayer.removeFromSuperlayer()
        minScaleBorderLayer.removeFromSuperlayer()
        
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
    
}
