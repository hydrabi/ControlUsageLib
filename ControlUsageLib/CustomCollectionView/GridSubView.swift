//   GridSubView.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/11/26
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
                pan.maximumNumberOfTouches = 2
            }
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
}

/// 拖选框
final class AUGridViewSelectionBoxLayer:CAShapeLayer {
    
    var scale:CGFloat = 1
    
    lazy var rectLayer:CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = GridConfig.itemSelectedBorderColor.cgColor
        let dash = NSNumber(value: 4 / self.scale)
        layer.lineDashPattern = [dash]
        layer.lineWidth = 2 / self.scale
        return layer
    }()
    
    lazy var circleLayer:CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = GridConfig.itemSelectedBorderColor.cgColor
        return layer
    }()
    
    init(scale: CGFloat) {
        self.scale = scale
        super.init()
        configUI()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configUI() {
        self.backgroundColor = UIColor.clear.cgColor
        addSublayer(rectLayer)
        addSublayer(circleLayer)
    }
    
    func updateRect(_ rect:CGRect) {
        
        let width = rect.width
        let height = rect.height
        
        //矩形陆行
        let rectPath = UIBezierPath(rect: CGRect(x: 0,
                                                 y: 0,
                                                 width: width,
                                                 height: height))
        
        // 创建四个角的路径
        let circlePath = UIBezierPath()
        
        //半径
        let cornerRadius = 4 / self.scale
        
        // 左上角
        let topLeftCirclePath = UIBezierPath(ovalIn: CGRect(x: -cornerRadius,
                                                            y: -cornerRadius ,
                                                            width: cornerRadius * 2,
                                                            height: cornerRadius * 2))
        
        let topRightCriclePath = UIBezierPath(ovalIn: CGRect(x: width - cornerRadius,
                                                             y: -cornerRadius,
                                                             width: cornerRadius * 2,
                                                             height: cornerRadius * 2))
        
        let bottomLeftCriclePath = UIBezierPath(ovalIn: CGRect(x: -cornerRadius,
                                                             y: height - cornerRadius,
                                                             width: cornerRadius * 2,
                                                             height: cornerRadius * 2))
        
        let bottomRightCriclePath = UIBezierPath(ovalIn: CGRect(x: width - cornerRadius,
                                                             y: height - cornerRadius,
                                                             width: cornerRadius * 2,
                                                             height: cornerRadius * 2))
        
        circlePath.append(topLeftCirclePath)
        circlePath.append(topRightCriclePath)
        circlePath.append(bottomLeftCriclePath)
        circlePath.append(bottomRightCriclePath)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.frame = rect
        rectLayer.path = rectPath.cgPath
        circleLayer.path = circlePath.cgPath
        CATransaction.commit()
    }
}
