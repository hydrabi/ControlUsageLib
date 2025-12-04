//   GridViewModel.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/11/26
//   


import Foundation

final class GridViewModel {
    
    /// 灯位图设备对象集合
    var lampLayouts:[AULampLayout] = []
    
    /// 选中的灯位图设备对象集合
    var selectedLampLayouts:[AULampLayout] = []
    
    /// 创建临时设备对象
    func createFixtureLayoutOjects() {
        lampLayouts.removeAll()
        for i in 0..<20 {
            let lamp = AULampLayout()
            lamp.UUID = UUID().uuidString
            lamp.position = i + 1
            lamp.color = RGB(r: (0...100).randomElement() ?? 0,
                             g: (0...100).randomElement() ?? 0,
                             b: (0...100).randomElement() ?? 0)
            lampLayouts.append(lamp)
        }
    }
    
    /// 点击灯位图设备
    /// - Parameter lampLayout: 灯位图设备对象
    /// - Parameter fource: 是否外部强制设置选中状态
    /// - Parameter isSelected: fouce为true时，设置是否被选中
    func tapLampLayout(lampLayout:AULampLayout,
                       fource:Bool = false,
                       isSelected:Bool = false) {
        //如果外部强制选择
        if fource {
            lampLayout.isSelected = isSelected
        }
        //切换
        else {
            lampLayout.isSelected.toggle()
        }
        
        //被选中
        if lampLayout.isSelected {
            if !selectedLampLayouts.contains(where: { $0.UUID == lampLayout.UUID }) {
                selectedLampLayouts.append(lampLayout)
                lampLayout.selectedNum = selectedLampLayouts.count
            }
        }
        //反选
        else {
            if let index = selectedLampLayouts.firstIndex(where: { $0.UUID == lampLayout.UUID }) {
                selectedLampLayouts.remove(at: index)
                distributeLampLyoutsSelectedNum()
            }
        }
    }
    
    /// 重新分配灯位图选中数字
    func distributeLampLyoutsSelectedNum() {
        for (index,lamp) in selectedLampLayouts.enumerated() {
            lamp.selectedNum = index + 1
        }
    }
}
