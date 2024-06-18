//   WhereSample.swift
//   ControlUsageLib
//
//   Created by Ted on 2024/6/18
//   


import Foundation

enum Action {
    case createUser(age:Int)
    case createPost
    case logout
}
//Where是Swift中一个功能强大的关键字，可以很容易地过滤掉值。它可以用于许多不同的变体，其中大多数在本文中列出。

//Where 使用例子
class WhereSample {
    
    //过滤枚举关联值
    func sample1(action:Action) {
        switch action {
        case .createUser(let age) where age < 21:
            print("Young and wild!")
        case .createUser:
            print("Older and wise!")
        case .createPost:
            print("Creating a post")
        case .logout:
            print("Logout")
        }
    }
    
    //数组遍历过滤
    func sample2() {
        let numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

        for number in numbers where number % 2 == 0 {
            print(number) // 0, 2, 4, 6, 8, 10
        }
    }
    
    //数组“first”操作符过滤
    func sample3() {
        let names = ["Henk", "John", "Jack"]
        let firstName = names.first { name in
            return name.first == "J"
        }
    }
    
    /// 数组“contains”操作符过滤
    func sample4() {
        let fruits = ["Banana", "Apple", "Kiwi"]
        let containsBanana = fruits.contains { fruit in
            return fruit == "Banana"
        }
    }
    
}

//过滤协议泛型类型
extension Array where Element == Int {
    func printAverageAge() {
        let total = reduce(0, +)
        let average = total / count
        print("Average age is \(average)")
    }
}


