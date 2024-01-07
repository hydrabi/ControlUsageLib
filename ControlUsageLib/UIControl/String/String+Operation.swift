//
//  String+Operation.swift
//  ControlUsageLib
//
//  Created by 毕志锋 on 2024/1/7.
//

import Foundation

extension String {
    
    /// 拼接字符串 直接使用“+”即可
    /// - Parameters:
    ///   - s1: 需要拼接的字符串1
    ///   - s2: 需要拼接的字符串2
    /// - Returns: 拼接后的字符串
    static func appendSting(s1:String,s2:String) -> String {
        return s1 + s2
    }
    
    /// 字符串格式
    static func demoStringFormat() {
        let str = String(format: "整数格式化%d", 1)
        let str1 = String(format: "浮点数限制小数位格式化%.2f", 1.56)
    }
    
    /// 遍历字符串
    static func demoStringForEach() {
        var str = "12345678"
        for char in str {
            print(char)
        }
    }
    
    /// 分割 拼接字符串
    static func demoStringSplitJoined() {
        let str = "Hello world"
        let arr = str.split(separator: " ")
        //输出HelloWorld
        let joined = arr.joined()
        //输出Hello-World
        let sepJoined = arr.joined(separator: "-")
    }
    
    /// 截取字符串
    static func demoStringCutOut() {
        let str = "123456789"
        //头部截取2位 "12"
        let str1 = str.prefix(2)
        //尾部截取2位 "89"
        let str2 = str.suffix(2)
        
        let index3 = str.index(str.startIndex,offsetBy: 3)
        let index4 = str.index(str.startIndex,offsetBy: 5)
        //范围第四位到第六位 “456”
        let str3 = str[index3...index4]
        
        if let range = str.range(of: "78") {
            //结果：123456
            let str4 = str[str.startIndex..<range.lowerBound]
            //结果：12345678
            let str5 = str[str.startIndex..<range.upperBound]
        }
    }
    
    /// 字符串插入
    static func demoStringInsert() {
        var str = "ABCDEFGH"
        //插入方法 结果: ABCDEFXGH
        str.insert("X", at: str.index(str.startIndex, offsetBy: 6))
        print(str)
        
        //多个字符插入 结果: ABCDEFXG888H
        str.insert(contentsOf: "888", at: str.index(before: str.endIndex))
    }
    
    /// 字符串移除
    static func demoStringRemove() {
        var str = "ABCDEFGH"
        let start = str.index(str.startIndex, offsetBy: 2)
        let end = str.index(str.endIndex, offsetBy: -2)
        str.removeSubrange(start...end)
        print(str)
        // 结果: ABH
    }
}
