//   NSArray+Operation.swift
//   ControlUsageLib
//
//   Created by Ted on 2024/1/9
//   


import Foundation

extension NSArray {
    
    /// 计算最大最小值平均值求和等的快捷操作
    func maxMinSumAvgValueDemo() {
        let arr = NSArray(objects: "5","1","4","3","4","10","6","15","16")
        //求和
        let sum = arr.value(forKeyPath: "sum.intValue")
        //平均值
        let avg = arr.value(forKeyPath: "avg.floatValue")
        //最大值
        let max = arr.value(forKeyPath: "max.intValue")
        //最小值
        let min = arr.value(forKeyPath: "min.intValue")
    }
}
