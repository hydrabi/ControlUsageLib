//   CombindLearn+Control.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/7/24
//   


import Foundation
import Combine
//发布者
extension CombindLearn {
    
    //MARK: - scan
    /**
     scan 是 Combine 框架中的一个重要操作符，它用于在发布者发出值时累积并转换这些值，类似于 Swift 标准库中的 reduce，但有一个关键区别：scan 会在每次新值到达时立即发出当前累积结果，而不是等到流完成时才发出最终结果。
     定义
     scan 操作符的签名：

     swift
     func scan<T>(_ initialResult: T, _ nextPartialResult: @escaping (T, Self.Output) -> T) -> Publishers.Scan<Self, T>
     核心特点
     累积计算：对上游发布者发出的每个值应用累积函数

     即时发射：每次计算后立即发出当前结果

     保持流活性：不像 reduce 那样需要等待流完成
     */
    
    func scanSample1() {
        //每次都会发出
        // 输出: 1, 3, 6, 10, 15
        let numbers = [1,2,3,4,5].publisher
        numbers.scan(0) { accumulated, current in
            return accumulated + current
        }.sink {
            print($0)
        }.store(in: &cancelSet)
        
        
        //与reduce的对比
        // reduce - 只在完成时发出 输出: 6
        [1,2,3].publisher.reduce(0, +).sink {
            print($0)
        }.store(in: &cancelSet)
    }
    
    //状态基类
    func scanSample2() {
        enum Action {
            case increment(Int)
            case decrement(Int)
        }
        
        let actions = PassthroughSubject<Action,Never>()
        
        actions.scan(0) { count, action in
            switch action {
            case .increment(let value):return count + value
            case .decrement(let value):return count - value
            }
        }
        .sink { print("Current count:\($0)")}
        .store(in: &cancelSet)
        
        actions.send(.increment(5)) // 输出: 5
        actions.send(.decrement(2)) // 输出: 3
        actions.send(.increment(1)) // 输出: 4
    }
    
    func scanSample3() {
        struct Message {
            let text:String
            let timestamp:Date
        }
        
        let newMessage = PassthroughSubject<Message,Never>()
        newMessage.scan([Message(text: "", timestamp: Date())]) { history, newMessage in
            return history + [newMessage]
        }
        .sink {
            print($0)
        }
        .store(in: &cancelSet)
        newMessage.send(Message(text: "hello", timestamp: Date()))
        newMessage.send(Message(text: "hi", timestamp: Date()))
    }
    
    func scanSample4() {
        struct MyError:Error {}
        let subject = PassthroughSubject<Int,MyError>()
        let _ = subject
            .scan(0) { $0 + $1 }
            .catch { _ in
                Just(-1) //发生错误时发出-1
            }
            .sink {
                print($0)
            }
            .store(in: &cancelSet)
        subject.send(1)
        subject.send(2)
        subject.send(completion: .failure(MyError()))
    }
    
    //MARK: - tryScan
    /**
     tryScan 是 Combine 框架中的一个错误处理操作符，它与 scan 类似，但允许累积函数抛出错误。当需要在进行累积计算时可能遇到错误情况时，tryScan 提供了错误处理的能力。
     核心特点
     累积计算：与 scan 相同，对上游值进行累积计算
     错误抛出：累积函数可以抛出错误
     错误传播：当抛出错误时，会终止发布流并传播错误
     即时发射：每次成功计算后立即发出当前结果
     */
    
    func tryScanSample1() {
        enum MyError:Error {
            case invalidValue
        }
    }
}
