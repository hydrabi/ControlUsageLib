//   GridViewController+Delegate.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/11/24
//   


import Foundation

protocol GridViewDelegate:AnyObject {
    func gridViewBeginPanLamp()
    func gridViewEndPanLamp()
    
    /// 点击某个灯位图设备回调
    /// - Parameter lampLayout: 点击的灯位图设备对象
    /// - Parameter fource: 是否强制选中
    /// - Parameter isSelected:fource为true的前提下，是否被选中
    func gridViewDidTapLampLayout(lampLayout:AULampLayout,
                                  fource:Bool,
                                  isSelected:Bool)
}

// MARK: - UIScrollViewDelegate
extension GridViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return gridView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // 更新 contentSize
        updateContentSize()
        // 重置GridView的比例
        gridView.resetScale(scale: scrollView.zoomScale,
                            layouts: viewModel.lampLayouts)
        // 根据可视范围绘制虚线坐标轴或数字索引
        getVisableRectRefreshLayers()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 根据可视范围绘制虚线坐标轴或数字索引
        getVisableRectRefreshLayers()
        print("gridView的frame为\(gridView.frame)")
        print("scrollview的偏移量为\(scrollView.contentOffset)")
        print("scrollview的frame为\(scrollView.frame)")
        print("scrollview的contentSize为\(scrollView.contentSize)")
        print("scrollView的scale为\(scrollView.zoomScale)")
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
    
    // 点击某个灯位图设备回调
    func gridViewDidTapLampLayout(lampLayout: AULampLayout,
                                  fource:Bool,
                                  isSelected:Bool) {
        viewModel.tapLampLayout(lampLayout: lampLayout,
                                fource: fource,
                                isSelected: isSelected)
    }
}
