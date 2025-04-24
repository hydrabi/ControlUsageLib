//   CombindLearn+Publisher.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/4/24
//   


import Foundation
import Combine

//发布者
extension CombindLearn {
    
    //MARK: - JUST
    //Just
    func sampleJustAndSink() {
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
    
    //MARK: - Future
    
    /*Future 是一个用于将异步操作转换为 Publisher 的实用工具。它特别适合将基于回调（callback）的异步代码桥接到 Combine 的响应式编程模型中。
    Future 的作用
    将回调式异步操作转换为 Publisher

    许多传统的异步 API（如网络请求、文件读写等）使用 completion handlers（回调闭包）。Future 可以封装这些操作，使其返回一个 Publisher，从而能直接接入 Combine 链式调用。

    单次事件发射

    Future 是一个 只能发射一个值（或错误） 的 Publisher。一旦异步操作完成，它会发射一个成功值（Output）或失败错误（Failure），然后终止。

    热发布者（Eager）

    默认情况下，Future 是 热 的：当你创建它时，它会立即执行异步操作（即使还没有订阅者）。如果需要延迟执行，可以将其包装在 Deferred 中
     */
    
    func sampleFuture() {
        let futurePublisher = Future<Int, Never> { promise in
            print("Future began processing")
            
            let number = Int.random(in: 1...10)
            print("Future emitted number: \(number)")
            promise(Result.success(number))
            
        }.print("Publisher event")
        
        
        cancelAble = futurePublisher.sink {
            print ("Future stream received: \($0)")
        }
    }
    
    /**
     promise 闭包

     Future 的初始化器接受一个 promise 闭包，你需要在这个闭包中调用 promise(.success(_)) 或 promise(.failure(_)) 来发射结果。

     单次性

     Future 只能发射一次，之后会终止。如果需要重复执行，需重新创建 Future 或使用其他 Publisher（如 PassthroughSubject）。

     取消支持

     如果订阅被取消，Future 内部的异步任务不会自动终止。你需要手动处理取消逻辑（例如检查 Combine.Cancellable 的状态）。

     与 Deferred 结合

     如果你希望 Future 在订阅时才启动（懒执行），可以用 Deferred 包装：
     let deferredFuture = Deferred { Future { promise in ... } }
     */
    
    /**
     适用场景
     将旧的回调代码（如 URLSession.dataTask）迁移到 Combine。

     单次异步操作（如用户登录、首次数据加载）。

     作为 Combine 链式调用的一部分（例如 flatMap 中的嵌套异步操作）。
     */
    
    /**
     替代方案
     如果需要多次发射值（如实时状态更新），用 PassthroughSubject 或 CurrentValueSubject。

     如果需要更复杂的异步控制，考虑使用 AnyPublisher 或自定义 Publisher。

     Future 是 Combine 中简化异步操作的重要工具，适合处理“单发”任务，同时保持 Combine 的声明式风格。
     */
    
    func sampleFuture1() {
        func fetchData() -> Future<String,Error> {
            return Future { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                    let success = Bool.random()
                    if success {
                        promise(.success("Data loaded!"))
                    }
                    else {
                        promise(.failure(URLError(.badServerResponse)))
                    }
                }
            }
        }
        
        let cancelable = fetchData().sink { completion in
            switch completion {
            case .finished:
                print("Done")
            case .failure(let error):
                print("Error: \(error)")
            }
        } receiveValue: { value in
            print("Received:\(value)")
        }
    }
    
    //MARK: - Deferred
    /**
     Deferred 是一个用于延迟 Publisher 创建的包装器，它确保在 订阅发生时才创建 Publisher，而不是在声明时就立即创建。这对于控制副作用（如网络请求、耗时计算）的触发时机非常有用。
     */
    
    /**
     Deferred 的作用
     1. 延迟 Publisher 的创建
     默认行为：许多 Publisher（如 Future、Just、URLSession.DataTaskPublisher）在初始化时会立即执行操作（如发起网络请求）。

     Deferred 的作用：将 Publisher 的创建推迟到 有订阅者订阅时，避免不必要的提前执行。

     2. 避免副作用提前发生
     例如，如果你在声明 Future 时就发起网络请求，但稍后才订阅，请求可能已经完成（甚至失败），而订阅者无法收到正确结果。

     Deferred 可以确保 订阅后才执行操作，保证数据的实时性。

     3. 适用于冷发布者（Cold Publisher）
     Deferred 通常用于 冷 Publisher（Cold Publisher），即每次订阅都会重新执行操作（如 Future、自定义 Publisher）。

     与之相对的是 热 Publisher（Hot Publisher，如 PassthroughSubject），它们无论是否有订阅者都会发射数据
     */
    
    //不会立刻触发 只有添加了订阅者才会触发 不添加的话不会触发
    func sampleFutureAndDeferred() {
        let deferredPublisher = Deferred {
            Future<Int, Error> { promise in
                print("Future began processing")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    let number = Int.random(in: 1...10)
                    print("Future emitted number: \(number)")
                    promise(Result.success(number))
                }
            }
        }.eraseToAnyPublisher()
        
        
        cancelAble = deferredPublisher.sink(receiveCompletion: { result in
            print ("reslt is: \(result)")
        }, receiveValue: {
            print ("Future stream received: \($0)")
        })
    }
    
}
