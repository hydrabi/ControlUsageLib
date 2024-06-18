//   CombindLearn.swift
//   ControlUsageLib
//
//   Created by Ted on 2024/6/18
//   


import Foundation
import Combine

//Using Combine 中文
//https://heckj.github.io/swiftui-notes/index_zh-CN

class CombindLearn {
    
//    var cancleAble:[AnyCancellable] = []
    
    var cancelAble:AnyCancellable? = nil
    
    var publisher:(any Publisher)? = nil
    
    func sample1() {
        //管道从发布者 Just 开始，它用它定义的值（在本例中为整数 5）进行响应。输出类型为 <Integer>，失败类型为 <Never>
        //然后管道有一个 map 操作符，它在转换值及其类型
        //sink作为订阅者结束
        let _ = Just(5).map { value -> String in
            // do something with the incoming value here
            // and return a string
            return "a string"
        }.sink { receivedValue in
            // sink is the subscriber and terminates the pipeline
            print("The end result was \(receivedValue)")
        }
    }
    
    func sample2() {
        //map 经典操作符
        let _ = Just(5).map { value in
            switch value {
            case _ where value < 1:
                return "none"
            case _ where value == 1:
                return "one"
            case _ where value == 2:
                return "couple"
            case _ where value == 3:
                return "few"
            case _ where value > 8:
                return "many"
            default:
                return "some"
            }
        }.sink { receivedValue in
            print("The end result was \(receivedValue)")
        }
    }
    
    //MARK: - Deferred
    enum TestFailureCondition: Error {
        case anErrorExample
    }
    
    func deferredAsyncApiCall(sabotage:Bool,completion completionBlock:@escaping ((Bool,Error?) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            let delay = Int.random(in: 1...3)
            sleep(UInt32(delay))
            if sabotage {
                completionBlock(false,TestFailureCondition.anErrorExample)
            }
            else{
                completionBlock(true,nil)
            }
        }
    }
    
    func defereedTest() {
        var outputValue = false
        let deferredPublisher = Deferred {
            Future<Bool,Error> { promise in
                self.deferredAsyncApiCall(sabotage: false) { grantedAccess, err in
                    if let err = err {
                        return promise(.failure(err))
                    }
                    return promise(.success(grantedAccess))
                }
            }
        }.eraseToAnyPublisher()
        
        publisher = deferredPublisher
        
        cancelAble = deferredPublisher.sink { err in
            print(".sink() received the completion: ", String(describing: err))
        } receiveValue: { value in
            print(".sink() received value: ", value)
            outputValue = value
        }
        
    }
    
    // 当生成Future后立马就触发了过程
    func sample3() {
        let futurePublisher = Future<Int, Never> { promise in
            print("🔮 Future began processing")
            
            let number = Int.random(in: 1...10)
            print("🔮 Future emitted number: \(number)")
            promise(Result.success(number))
            
        }.print("🔍 Publisher event")
        
        publisher = futurePublisher
        
        cancelAble = futurePublisher.sink {
            print ("🎧 Future stream received: \($0)")
        }
    }
    
    //不会立刻触发 只有添加了订阅者才会触发 不添加的话不会触发
    func sample4() {
        let deferredPublisher = Deferred {
            Future<Int, Error> { promise in
                print("🔮 Future began processing")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    let number = Int.random(in: 1...10)
                    print("🔮 Future emitted number: \(number)")
                    promise(Result.success(number))
                }
            }
        }.eraseToAnyPublisher()
        
        publisher = deferredPublisher
        
        cancelAble = deferredPublisher.sink(receiveCompletion: { result in
            print ("🎧 reslt is: \(result)")
        }, receiveValue: {
            print ("🎧 Future stream received: \($0)")
        })
    }
}
