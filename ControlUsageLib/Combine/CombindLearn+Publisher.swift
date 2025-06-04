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
    
    //MARK: Empty
    
    /*
     在 Swift 的 Combine 框架中，Empty 是一个特殊的 Publisher，它 不发送任何值，可以选择是否立即 正常完成（Finished） 或 不发送任何事件（适用于无限等待的场景）。它通常用于占位、错误处理或条件性数据流控制
     */
    
    /*
     Empty 的核心作用
     表示一个“空”数据流

     不发射任何 Output 值，直接完成（或保持沉默）。

     类似于 Just 但不发送值，或 Future 但不执行异步操作。

     控制数据流的完成行为

     可以立即完成（completeImmediately: true），或永不完成（completeImmediately: false）。

     占位或条件性分支

     在需要返回 Publisher 但无实际数据时作为占位符（例如 flatMap 中条件不满足时返回 Empty）。
     */
    
    func sampleEmpty() {
        //立即完成
        let emptyPublish = Empty<String,Never>(completeImmediately: true)
        _ = emptyPublish.sink {
            print("完成: \($0)")
        } receiveValue: {
            // 不会执行
            print("收到值: \($0)")
        }
    }
    
    func sampleEmpty1() {
        let emptyPublish = Empty<String,Never>(completeImmediately: false)
        _ = emptyPublish.sink(receiveCompletion: { _ in
            print("不会执行")
        }, receiveValue: { _ in
            print("不会执行")
        })
    }
    
    
    /// 1. 占位 Publisher 当某个函数必须返回 Publisher，但当前无数据可发送时：
    func sampleEmpty2(shouldFetch:Bool) -> AnyPublisher<String,Error> {
        if shouldFetch {
            return Just("test")
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        else {
            return Empty(completeImmediately: true)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    //MARK: - Sequence
    /*
     Combine 提供了 sequence 方法，可以将一个 Swift 序列（Sequence） 转换为一个 Publisher，按顺序逐个发射元素，最后发送 .finished 完成事件。
     
     按顺序发射：元素按照序列的顺序逐个发出。
     自动完成：发射完所有元素后，自动发送 .finished。
     适用于 for-in 兼容的类型：如 Array、Range、Set、String（字符序列）等。
     */
    func sampleSequence() {
        let arrayPublisher = [1,2,3,4].publisher
        let cancelable = arrayPublisher.sink {
            print("完成：\($0)")
        } receiveValue: {
            print("收到：\($0)")
        }
//        收到: 1
//        收到: 2
//        收到: 3
//        收到: 4
//        完成: finished
    }
    
    func sampleSequence1() {
        [1,2,3,4,5].publisher
            .filter { $0 % 2 == 0 } // 只保留偶数
            .map { $0 * 2 }         // 每个元素乘以 2
            .sink { print($0) }     // 输出: 4, 8
    }
    
    func sampleSequence2() {
        let numbers = [1, 2, 3].publisher
        let letters = ["A", "B", "C"].publisher
        
        Publishers.Zip(numbers, letters)
            .sink {
                print("\($0)-\($1)") // 输出: 1-A, 2-B, 3-C
            }
    }
    
    //MARK: - Share
    /**
     在 Swift 的 Combine 框架中，.share() 是一个操作符，用于 共享 Publisher 的订阅，避免重复执行昂贵的操作（如网络请求、数据库查询等）。它的核心作用是让多个订阅者 共享同一个 Publisher 的执行结果，而不是每个订阅者都触发一次独立的执行
     
     1. 避免重复执行副作用

     默认情况下，冷 Publisher（Cold Publisher）（如 Future、URLSession.dataTaskPublisher）会在每次订阅时重新执行。
     例如，如果有多个订阅者订阅同一个网络请求 Publisher，默认会发起多次请求。
     .share() 可以让多个订阅者共享同一个 Publisher 的结果，只执行一次网络请求。
     
     2. 转换为热 Publisher（Hot Publisher）

     .share() 会返回一个 引用计数的 Publisher，它在第一个订阅者订阅时开始执行，并在所有订阅者取消后重置。
     后续的订阅者会直接接收已经缓存的值（如果 Publisher 尚未完成）。
     
     3. 适用于多个订阅者共享数据的场景

     例如：
     多个 UI 组件订阅同一个 API 请求结果。
     多个观察者监听同一个数据库查询结果。
     */
    
    func sampleShare1() {
        func fetchData() -> AnyPublisher<String,Error> {
            Deferred {
                Future { promise in
                    print("发起网络请求")
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                        promise(.success("数据"))
                    }
                }
            }.eraseToAnyPublisher()
        }
        // 创建共享 Publisher
        sharedPublisher = fetchData().share()
        //第一个订阅者
        sharedPublisher?.sink { _ in
            print("订阅者1完成")
        } receiveValue: {
            print("订阅者1收到: \($0)")
        }.store(in: &cancelSet)

        // 第二个订阅者（稍后订阅）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sharedPublisher?.sink { _ in
                print("订阅者2完成")
            } receiveValue: {
                print("订阅者2收到: \($0)")
            }.store(in: &self.cancelSet)

        }
    }
    
    //和上面的区别是没有share
    func sampleShare2() {
        func fetchData() -> AnyPublisher<String,Error> {
            Deferred {
                Future { promise in
                    print("发起网络请求")
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                        promise(.success("数据"))
                    }
                }
            }.eraseToAnyPublisher()
        }
        // 创建共享 Publisher
        commonPublisher = fetchData()
        //第一个订阅者
        commonPublisher?.sink { _ in
            print("订阅者1完成")
        } receiveValue: {
            print("订阅者1收到: \($0)")
        }.store(in: &cancelSet)

        // 第二个订阅者（稍后订阅）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.commonPublisher?.sink { _ in
                print("订阅者2完成")
            } receiveValue: {
                print("订阅者2收到: \($0)")
            }.store(in: &self.cancelSet)

        }
    }
}
