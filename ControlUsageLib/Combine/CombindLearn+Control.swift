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
    
    func scanSample5() {
        let numbers = [1,2,3,4,5]
        let cancellable = numbers.publisher
            .scan(0) { accumulated, current in
                return accumulated+current
            }
            .sink { value in
                print("当前累计值:\(value)")
            }
        // 输出:
        // 当前累积值: 1
        // 当前累积值: 3
        // 当前累积值: 6
        // 当前累积值: 10
        // 当前累积值: 15
    }
    
    func scanSample6() {
        // 模拟可能失败的操作
        var attemptCount = 0

        func failingOperation() -> AnyPublisher<String, Error> {
            return Deferred {
                Future<String, Error> { promise in
                    attemptCount += 1
                    print("尝试第 \(attemptCount) 次")
                    
                    if attemptCount < 3 {
                        promise(.failure(NSError(domain: "TestError", code: -1, userInfo: nil)))
                    } else {
                        promise(.success("操作成功！"))
                    }
                }
            }
            .eraseToAnyPublisher()
        }

        // 使用 retry 操作符
        let cancellable = failingOperation()
            .retry(2) // 重试2次（总共最多尝试3次）
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("操作成功完成")
                    case .failure(let error):
                        print("最终失败: \(error)")
                    }
                },
                receiveValue: { value in
                    print("接收到的值: \(value)")
                }
            )

        // 输出:
        // 尝试第 1 次
        // 尝试第 2 次
        // 尝试第 3 次
        // 接收到的值: 操作成功！
        // 操作成功完成
    }
    
    //MARK: - tryScan
    /**
     tryScan 是 Combine 框架中的一个错误处理操作符，它与 scan 类似，但允许累积函数抛出错误。当需要在进行累积计算时可能遇到错误情况时，tryScan 提供了错误处理的能力。
     核心特点
     累积计算：与 scan 相同，对上游值进行累积计算
     错误抛出：累积函数可以抛出错误
     错误传播：当抛出错误时，会终止发布流并传播错误
     即时发射：每次成功计算后立即发出当前结果
     
     错误处理
     错误传播机制
     当 tryScan 的闭包抛出错误时：

     发布流会立即终止

     发送 failure 完成事件

     不再接收或处理任何后续值
     */
    
    func tryScanSample1() {
        enum MyError:Error {
            case invalidValue
        }
        
        let numbers = [1,2,3,4,5].publisher
        numbers.tryScan(0) { accumulated, current in
            let newValue = accumulated + current
            if newValue > 7 {
                throw MyError.invalidValue
            }
            return newValue
        }
        .sink {
            switch $0 {
            case .failure(let error):print("Error:\(error)")
            case .finished: print("Finished successfully")
            }
        } receiveValue: {
            print($0)
        }
        .store(in: &cancelSet)
        // 输出:
        // 1
        // 3
        // 6
        // Error: invalidValue
    }
    
    func tryScanSample2() {
        let jsonParts = [
            "{\"name\":\"John\", \"age\":",
            "30, \"city\":\"New ",
            "York\"}"
        ].publisher
        
        jsonParts.tryScan("") { accumulated, part in
            let newString = accumulated + part
            if let data = newString.data(using: .utf8),
               let _ = try? JSONSerialization.jsonObject(with: data,options: []) {
                return newString
            }
            return newString
        }
        .tryMap { try JSONSerialization.jsonObject(with: $0.data(using: .utf8)!) }
        .sink(
                receiveCompletion: { print($0) },
                receiveValue: { print("Parsed JSON: \($0)") }
            )
        .store(in: &cancelSet)
    }
    
    //MARK: - setFailureType
    
    /**
     setFailureType(to:) 是 Combine 框架中的一个操作符，用于改变 Publisher 的 Failure 类型而不改变其实际发出的值。

     基本概念
     在 Combine 中，Publisher 有两个关联类型：

     Output: 发布的值类型

     Failure: 错误类型（必须符合 Error 协议）

     setFailureType(to:) 允许你将 Publisher 的 Failure 类型转换为另一种 Error 类型，而不需要实际发送任何错误。

     使用场景
     当你有一个不会失败的 Publisher（如 Just 或 Publishers.Sequence），但需要将其转换为具有特定 Failure 类型的 Publisher 时，这个操作符非常有用。
     
     重要注意事项
     setFailureType(to:) 只改变类型系统对 Publisher 的认知，不会实际改变 Publisher 的行为。

     它只能用于 Failure 类型为 Never 的 Publisher（即不会失败的 Publisher）。

     如果你尝试对可能失败的 Publisher 使用此操作符，编译器会报错。
     */
    
    func setFailureTypeSample1() {
        enum MyError:Error {
            case someError
        }
        
        let justPublisher = Just("Hello")
        // 将 Failure 类型从 Never 转换为 MyError
        // 现在类型是 Publisher<String, MyError>
        let publisherWithError = justPublisher.setFailureType(to: MyError.self)
    }
    
    func setFailureTypeSample2() {
        let sequencePublisher = [1,2,3].publisher
        sequencePublisher.setFailureType(to: URLError.self)
            .tryMap { value in
                // 这里可以抛出错误
//                try someThrowingFunction(value)
            }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("完成")
                    case .failure(let error):
                        print("错误: \(error)") // 错误类型是 URLError
                    }
                },
                receiveValue: { value in
                    print("收到值: \(value)")
                }
            )
            .store(in: &cancelSet)
    }
    
    //MARK: - tryMap
    
    /**
     tryMap 与常规的 map 操作符类似，都是对 Publisher 发出的值进行转换，但关键区别在于：

     map: 执行同步转换，不能抛出错误

     tryMap: 执行可能抛出错误的转换
     
     主要特点
     转换值：像普通 map 一样转换输入值

     错误处理：允许转换闭包中抛出错误

     Failure 类型变化：将 Publisher 的 Failure 类型改为 Error（如果原先不是）
     
     错误处理机制
     当 tryMap 的闭包抛出错误时：

     立即发送 .failure 完成事件

     取消上游订阅

     不再发送任何值

     错误类型会被包装为 Publisher 的 Failure 类型（通常变为通用的 Error 类型）
     
     注意事项
     使用 tryMap 后，Publisher 的 Failure 类型会变为 Error，可能需要后续使用 mapError 进行特定错误类型的转换

     抛出错误会立即终止事件流

     在闭包中执行耗时操作时，应考虑使用适当的调度器

     tryMap 在处理可能失败的转换时非常有用，特别是在数据验证、解析和转换场景中。
     */
    
    func tryMapSample1() {
        let numbers = [1,2,3,4].publisher
        numbers.tryMap { value in
            if value % 2 == 0 {
                return value * 2
            }
            else {
                throw NSError(domain: "不允许奇数",
                              code: 0)
            }
        }
        .sink { completion in
            switch completion {
            case .finished:
                print("完成")
            case .failure(let error):
                print("\(error.localizedDescription)")
            }
        } receiveValue: {
            print($0)
        }
        .store(in: &cancelSet)
        // 输出:
        // 错误: 奇数不被允许
    }
    
    func tryMapSample2() {
        let urlStrings = ["https://apple.com", "无效URL", "https://example.com"].publisher
        urlStrings.tryMap { string in
            guard let url = URL(string: string) else {
                throw URLError(.badURL)
            }
            return url
        }
        .sink {
            print($0)
        } receiveValue: {
            print("有效URL: \($0)")
        }
        .store(in: &cancelSet)
        // 输出:
        // 有效URL: https://apple.com
        // failure(Error Domain=NSURLErrorDomain Code=-1000 "bad URL" UserInfo={NSLocalizedDescription=bad URL})
    }
    
    func tryMapSample3() {
        struct User:Decodable {
            let name:String
        }
        
        let jsonData = """
            {"name": "John"},
            {"name": "Alice"},
            {"invalid": "data"}
        """.data(using: .utf8)!
        
        Just(jsonData)
            .tryMap { data in
                let decoder = JSONDecoder()
                return try decoder.decode([User].self, from: data)
            }
            .sink {
                print($0)
            } receiveValue: {
                print("有效URL: \($0)")
            }
            .store(in: &cancelSet)
    }
    
    //MARK: - flapMap
    /**
     flatMap 是 Combine 框架中一个强大且常用的操作符，用于处理异步序列的转换和嵌套 Publisher 的场景。
     
     基本概念
     flatMap 的主要功能是：
     将每个输入值转换为一个新的 Publisher
     将这些 Publisher "扁平化"（flatten）为单个事件流
     
     核心特点
     一对多转换：一个输入值可以产生多个输出值
     异步处理：适合处理异步操作（如网络请求）
     自动管理订阅：自动处理内部 Publisher 的生命周期
     
     注意事项
     内存管理：默认情况下 flatMap 会订阅所有生成的 Publisher，可能导致内存问题
     顺序不保证：内部 Publisher 发出的值可能不按原始顺序到达
     取消行为：当外部 Publisher 取消时，所有内部 Publisher 也会被取消
     背压处理：使用 maxPublishers 参数可以控制并发量
     
     替代方案
     如果只需要转换值而不需要嵌套 Publisher，使用 map
     如果需要严格按顺序处理，考虑使用 concatMap（Combine 中没有内置，但可以实现类似行为）
     flatMap 是处理复杂异步数据流的强大工具，特别适合网络请求链式调用、数据库操作等场景。
     */
    
    func flapMapSample1() {
        func fetchUser(id:Int)->AnyPublisher<String,Never> {
            Just("用户\(id)详情")
                .delay(for: .seconds(1),
                       scheduler: RunLoop.main,
                       options: .none)
                .eraseToAnyPublisher()
        }
        
        let userIDs = [1,2,3].publisher
        userIDs.flatMap { id in
            fetchUser(id: id)
        }
        .sink { userDetail in
            print(userDetail)
        }
        .store(in: &cancelSet)
        
        // 限制同时进行的请求数量
        // 最多同时2个请求
        userIDs.flatMap(maxPublishers: .max(2)) { id in
            fetchUser(id: id)
        }
        .sink {
            print($0)
        }
        .store(in: &cancelSet)
    }
    
    func flapMapSample2() {
        // 先获取用户ID，再获取用户详情
        func getUserID() -> AnyPublisher<Int,Error> {
            Just(123)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        func getUserDetail(id:Int) -> AnyPublisher<String,Error> {
            Future { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                    promise(.success("用户\(id)的详细信息"))
                }
            }.eraseToAnyPublisher()
        }
        
        getUserID()
            .flatMap { id in
                getUserDetail(id: id)
            }
            .sink {
                print($0)
            } receiveValue: {
                print($0)
            }
            .store(in: &cancelSet)
    }
    
    @available(iOS 14.0, *)
    func flapMapSample3() {
        struct APIError:Error {}
        
        func fetchData() -> AnyPublisher<Data,APIError> {
            Fail(error: APIError()).eraseToAnyPublisher()
        }
        
        Just("Request")
            .flatMap { _ in
                fetchData()
            }
            .sink {
                switch $0 {
                case .failure(let error):
                    print("错误:\(error)")
                case .finished:
                    print("完成")
                }
            } receiveValue: { _ in
                print("收到数据")
            }
            .store(in: &cancelSet)
    }
    
    //MARK: - compactMap
    
    /**
     compactMap 是 Combine 中一个实用的操作符，它结合了 map 和 filter 的功能，专门用于处理可选值转换的场景。
     
     基本概念
     compactMap 的主要功能是：
     对每个输入值执行转换（类似 map）
     自动过滤掉转换结果为 nil 的值（类似 filter）
     
     核心特点
     转换+过滤：一步完成值转换和 nil 过滤
     类型安全：输出类型是非可选类型
     简化代码：避免显式的 map + filter 组合
     
     与相关操作符对比
     操作符    功能描述
     map    单纯转换值，不处理 nil
     filter    基于条件过滤值，不改变值类型
     compactMap    先转换值，然后自动过滤掉结果为 nil 的项
     tryMap    可能抛出错误的转换，不自动处理 nil
     */
    
    func compactMapSample1() {
        let strings = ["1","2","three","4"].publisher
        strings.compactMap {
            Int($0)
        }
        .sink {
            print($0)
        }
        .store(in: &cancelSet)
    }
    
    func compactMapSample2() {
        struct User {
            var name:String?
        }
        
        let users = [User(name: "Alice"),User(name: nil),User(name: "Bob")].publisher
        users.compactMap { $0.name }
            .sink { print($0) }
            .store(in: &cancelSet)
    }
    
    //MARK: - replaceEmpty
    /**
     replaceEmpty 是 Combine 框架中一个实用的操作符，专门用于处理空序列的情况。
     
     基本概念
     replaceEmpty 的主要功能是：
     检测 Publisher 是否没有发出任何值就完成了
     如果是空序列，则替换为一个默认值
     如果发出了值，则原样传递这些值
     
     核心特点
     空序列处理：专门针对不发射任何值就完成的 Publisher
     保底值：确保订阅者至少能收到一个值
     类型安全：默认值必须与 Publisher 的 Output 类型匹配
     */
    
    func replaceEmptySample1() {
        let emptyArray = [Int]().publisher
        emptyArray.replaceEmpty(with: 0)
            .sink { print("收到值:\($0)") }
            .store(in: &cancelSet)
    }
    
    //MARK: - replaceError
    
    /**
     replaceError 是 Combine 框架中用于错误处理的重要操作符，它可以将失败的 Publisher 转换为不会失败的 Publisher。
     
     基本概念
     replaceError 的主要功能是：
     拦截 Publisher 发出的错误
     用指定的默认值替换错误
     将 Failure 类型从具体的 Error 类型改为 Never
     
     核心特点
     错误恢复：将失败事件转换为正常值
     类型转换：将可能失败的 Publisher 转换为不会失败的 Publisher
     简单处理：提供了一种快速处理错误的轻量级方案
     */
    
    func replaceErrorSample1() {
        enum MyError:Error {
            case someError
        }
        
        let failingPublisher = Fail<Int,MyError>(error: .someError)
        failingPublisher
            .replaceError(with: 0)
            .sink { print("完成：\($0)") }
        receiveValue: { print("收到值：\($0)") }
            .store(in: &cancelSet)
    }
    
    func replaceErrorSample2() {
        struct NetworkService {
            func fetchData() -> AnyPublisher<Data,Error> {
                Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
            }
        }
    }
    
    //MARK: - removeDuplicates
    /**
     removeDuplicates 是 Combine 框架中一个实用的操作符，用于过滤连续重复的值，确保 Publisher 不会连续发出相同的值。
     
     基本概念
     removeDuplicates 会：
     比较当前发出的值与上一个值
     如果相同，则过滤掉当前值
     如果不同，则允许值通过
     */
    func removeDuplicatesSample1() {
        let numbers = [1, 2, 2, 3, 3, 3, 4, 5, 5].publisher
        numbers.removeDuplicates().sink { print($0) }
            .store(in: &cancelSet)
        // 输出: 1, 2, 3, 4, 5
    }
    
    //当你的类型不符合 Equatable 或需要特殊比较逻辑时
    func removeDuplicatesSample2() {
        struct Person {
            let id: Int
            let name: String
        }

        let people = [
            Person(id: 1, name: "Alice"),
            Person(id: 1, name: "Alice"), // 重复
            Person(id: 2, name: "Bob"),
            Person(id: 2, name: "Bob"),   // 重复
            Person(id: 3, name: "Charlie")
        ].publisher
        
        people.removeDuplicates { prev, current in
            prev.id == current.id
        }
        .sink { print("\($0.id): \($0.name)") }
        .store(in: &cancelSet)
        // 输出:
        // 1: Alice
        // 2: Bob
        // 3: Charlie
    }
    
    //MARK: - collect
    /**
     collect 是 Combine 框架中一个非常有用的操作符，它可以将多个单独的值"收集"起来，然后以数组的形式一次性发布。下面将详细介绍它的各种用法和场景。

     基本用法
     最简单的 collect() 形式不带参数，它会收集上游发布者发出的所有值，直到上游发布者完成，然后以一个数组的形式发出所有收集到的值。
     */
    
    func collectSample1() {
        //最简单的 collect() 形式不带参数，它会收集上游发布者发出的所有值，直到上游发布者完成，然后以一个数组的形式发出所有收集到的值。
        let numbers = [1, 2, 3, 4, 5].publisher
        numbers.collect()
            .sink { print($0)}
            .store(in: &cancelSet)
        // 输出: [1, 2, 3, 4, 5]
    }
    
    //collect(_ count: Int) 可以指定每次收集多少个值后就发出数组：
    func collectSample2() {
        let numbers = [1, 2, 3, 4, 5, 6, 7, 8].publisher
        numbers.collect(3)
            .sink { print($0) }
            .store(in: &cancelSet)
        // 输出:
        // [1, 2, 3]
        // [4, 5, 6]
        // [7, 8]  // 最后一组不足3个也会发出
    }
    
    func collectSample3() {
        let timerPub = Timer.publish(every: 0.5, on: .main, in: .default)
            .autoconnect()
            .map { _ in
                let randomValue = Int.random(in: 1...100)
                print("\(randomValue)")
                return randomValue
            }
        timerPub
            .collect(.byTime(RunLoop.main, 2.0))
            .sink { print("\(Date()):\($0)")}
            .store(in: &cancelSet)
    }
    
    //MARK: - Reduce
    /**
     reduce 操作符是 Combine 框架中用于聚合数据的强大工具，它可以将序列中的所有值合并成一个单一的结果。类似于 Swift 标准库中的 reduce 函数，但在响应式编程中处理的是异步数据流。
     
     核心特性
     1. 聚合计算
     将数据流中的所有值聚合成单个结果

     只在发布者完成时发出最终结果

     2. 状态保持
     维护一个累积状态（accumulator）

     每个新值都会与当前状态结合产生新状态

     3. 完成触发
     只有当上游发布者完成时，才会发出最终结果
     */
    
    // 输出: 总和: 15
    func reduceSample1() {
        let numbers = [1, 2, 3, 4, 5]
        let cancelable = numbers.publisher
            .reduce(0) { accumulated, current in
                return accumulated + current
            }
            .sink { total in
                print("总和: \(total)") // 只在所有值发出后输出一次
            }
    }
    
    func reduceSample2() {
        let words = ["Hello", "World", "!", "Combine", "Swift"]
        let cancellable = words.publisher
            .reduce("") { accumulated, current in
                return accumulated + " " + current
            }
            .sink { sentence in
                print("完整句子：\(sentence)")
            }
    }
    
    //与 scan 操作符的区别
    func reduceSample3() {
        let numbers = [1, 2, 3, 4, 5]
        numbers.publisher
            .reduce(0, +)
            .sink { value in
                // 只输出一次: 15
                print("reduce 结果:\(value)")
            }
        
        numbers.publisher
            .scan(0, +)
            .sink { value in
                // 输出: 1, 3, 6, 10, 15
                print("scan 结果:\(value)")
            }
    }
    
    //MARK: - ignoreOutput
    /**
     ignoreOutput 操作符是 Combine 框架中一个实用的操作符，它会忽略所有输入的值，只关心发布者的完成事件（成功完成或失败）。当你不关心具体的值，只想知道操作是否完成时，这个操作符非常有用。
     
     核心特性
     1. 值忽略
     忽略所有从上游发布者接收到的值

     不向下游传递任何值

     2. 完成传递
     只传递完成事件（.finished 或 .failure）

     输出类型变为 Never

     3. 类型转换
     将 Publisher<Output, Failure> 转换为 Publisher<Never, Failure>
     */
    
    func ignoreOutputSample1() {
        // 输出: "数据流完成"
        let numbers = [1, 2, 3, 4, 5].publisher
        let _ = numbers
            .ignoreOutput()
            .sink { completion in
                switch completion {
                case .finished:
                    print("完成")
                case .failure(let error):
                    print("错误")
                }
            } receiveValue: { _ in
                print("不会接收到值")
            }
    }
    
    func ignoreOutputSample2() {
        let complexPipeline = [1,2,3,4,5].publisher
            .filter { $0 % 2 == 0 }
            .map { $0 * 2 }
//            .flatMap { value in
//                return Just(value).delay(for: .second(1), scheduler: DispatchQueue.main)
//            }
            .collect()
            .ignoreOutput()
            .eraseToAnyPublisher()
        
        
        complexPipeline.sink { completion in
            switch completion {
            case .finished:
                print("复杂处理完成")
            case .failure:
                print("处理失败")
            }
        } receiveValue: { _ in }

    }
    
    //MARK: - MAX
    /**
     概述
     max 操作符是 Combine 框架中用于查找序列中最大值的操作符。它会等待上游发布者完成，然后发出整个序列中的最大值。
     
     核心特性
     1. 完成时发出结果
     等待上游发布者完成

     在完成时发出序列中的最大值

     2. 比较方式
     默认使用 < 操作符比较

     支持自定义比较闭包

     3. 空序列处理
     如果序列为空，则完成时不发出任何值
     
     总结
     max 操作符的主要特点：

     等待完成：只有在源发布者完成时才会发出结果

     比较支持：支持默认比较和自定义比较逻辑

     类型安全：保持类型安全性，适用于各种可比类型

     组合性强：可以与其他 Combine 操作符很好地组合使用

     适用场景：

     数据分析中的极值查找

     实时监控系统中的峰值检测

     游戏和评分系统中的最高分计算

     任何需要找到序列中最大值的场景
     */
    
    func maxSample1() {
        let numbers = [5, 2, 8, 1, 9, 3].publisher
        numbers
            .max()
            .sink { maxValue in
                print("最大值: \(maxValue)") // 输出: 最大值: 9
            }
            .store(in: &cancelSet)
    }
    
    func maxSample2() {
        struct Person {
            let name: String
            let age: Int
        }

        let people = [
            Person(name: "Alice", age: 25),
            Person(name: "Bob", age: 30),
            Person(name: "Charlie", age: 28)
        ].publisher
        
        people
            .max { $0.age < $1.age }
            .sink { oldestPerson in
                print("最年长的人: \(oldestPerson.name), 年龄: \(oldestPerson.age)")
                        // 输出: 最年长的人: Bob, 年龄: 30
            }
            .store(in: &cancelSet)
    }
    
    //MARK: - count
    /**
     概述
     count 操作符是 Combine 框架中用于统计发布者发出元素数量的操作符。它会等待上游发布者完成，然后发出元素的总数。
     
     核心特性
     1. 完成时发出结果
     等待上游发布者完成

     在完成时发出元素的总数量

     2. 返回值
     返回 Int 类型，表示元素数量

     空序列返回 0

     3. 错误传播
     如果上游发布者失败，错误会传递给下游
     */
    
    func countSample1() {
        // 基础计数
        let numbers = [1, 2, 3, 4, 5].publisher
        numbers
            .count()
            .sink { count in
                print("元素数量: \(count)") // 输出: 元素数量: 5
            }
            .store(in: &cancelSet)
        
        let emptyPublisher = Empty<Int,Never>()
        emptyPublisher
            .count()
            .sink { count in
                print("空序列数量: \(count)") // 输出: 空序列数量: 0
            }
            .store(in: &cancelSet)
    }
    
    //MARK: - Min
    /**
     min 操作符是 Combine 框架中用于查找序列中最小值的操作符。它会等待上游发布者完成，然后发出整个序列中的最小值。
     
     核心特性
     1. 完成时发出结果
     等待上游发布者完成

     在完成时发出序列中的最小值

     2. 比较方式
     默认使用 < 操作符比较

     支持自定义比较闭包

     3. 空序列处理
     如果序列为空，则完成时不发出任何值
     */
    
    func minSample1() {
        let numbers = [5, 2, 8, 1, 9, 3].publisher
        numbers
            .min()
            .sink { minValue in
                print("最小值:\(minValue)") // 输出: 最小值: 1
            }
            .store(in: &cancelSet)
    }
    
    func minSample2() {
        struct Product {
            let name: String
            let price: Double
            let rating: Int
        }

        let products = [
            Product(name: "iPhone", price: 999.0, rating: 5),
            Product(name: "iPad", price: 799.0, rating: 4),
            Product(name: "MacBook", price: 1299.0, rating: 5),
            Product(name: "AirPods", price: 199.0, rating: 4)
        ].publisher
        
        products
            .min { $0.price < $1.price }
            .sink { cheapestProduct in
                print("最便宜的产品:\(cheapestProduct.name), 价格: $\(cheapestProduct.price)")
            }
            .store(in: &cancelSet)
    }
}

extension Publisher where Output:Numeric {
    func average() -> AnyPublisher<Double,Failure> {
        return self.reduce((count:0,sum:0.0)) { result, value in
            let doubleValue = Double("\(value)") ?? 0.0
            return (result.count + 1, result.sum + doubleValue)
        }
        .map { Double($0.sum) / Double($0.count) }
        .eraseToAnyPublisher()
    }
}

extension Publisher where Output:Comparable {
    func findMin() -> AnyPublisher<Output,Failure> {
        return self.min().eraseToAnyPublisher()
    }
    
    func findMin<T:Comparable>(by keyPath:KeyPath<Output,T>) -> AnyPublisher<Output,Failure> {
        return self.min { $0[keyPath: keyPath] < $1[keyPath: keyPath]}
            .eraseToAnyPublisher()
    }
}




