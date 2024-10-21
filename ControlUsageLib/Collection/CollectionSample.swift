//
//  CollectionSample.swift
//  ControlUsageLib
//
//  Created by 毕志锋 on 2023/12/25.
//

import Foundation

/// 集合类型例子
class CollectionSample {
    //字典属性
    var dic:[String:Int] = [:]
    
    /// 字典例子
    func dicSample() {
        //创建
        dic = ["1":1,"2":2]
        //修改
        dic["2"] = 3
        //访问
        if let value = dic["1"] {
            print(value)
        }
        //遍历
        for (key,value) in dic {
            print("key:\(key),value:\(value)")
            
        }
    }
    
    

}
