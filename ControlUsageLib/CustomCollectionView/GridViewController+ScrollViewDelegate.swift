//   GridViewController+ScrollViewDelegate.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/11/24
//   


import Foundation

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
        gridView.drawScaleAxisPath(rows: GridConfig.itemMaxRow,
                                      columns: GridConfig.itemMaxColumn,
                                      totalSize: GridConfig.gridMaxSize,
                                      scale: scrollView.zoomScale)
        createVisableLayers()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        // 更新 contentSize
        updateContentSize()
        createVisableLayers()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        createVisableLayers()
        print("gridView的frame为\(gridView.frame)")
        print("scrollview的偏移量为\(scrollView.contentOffset)")
        print("scrollview的frame为\(scrollView.frame)")
        print("scrollview的contentSize为\(scrollView.contentSize)")
        print("scrollView的scale为\(scrollView.zoomScale)")
    }
    
    
    
}
