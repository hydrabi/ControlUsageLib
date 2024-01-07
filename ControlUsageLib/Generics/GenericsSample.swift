//
//  GenericsSample.swift
//  ControlUsageLib
//
//  Created by 毕志锋 on 2023/12/25.
//

import Foundation

/// 泛型例子
class GenericsSample {
    
    //泛型函数
    //占位类型名放在方法名后面 inout为参数可被修改
    func swapTwoValues<T>(_ a:inout T,_ b:inout T) {
        let tempA = a
        a = b
        b = tempA
    }
    
}
