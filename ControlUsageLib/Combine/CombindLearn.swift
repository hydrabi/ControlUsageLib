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
    
    //当你存储和自己订阅者的引用以便稍后清理时，你通常希望引用销毁时能自己取消订阅
    //存储对订阅者的引用非常重要，因为当引用被释放销毁时，它将隐含地取消其操作
    var cancelSet:Set<AnyCancellable> = []
    
    var publisher:(any Publisher)? = nil
    
    //发布带有Published属性的属性将创建这种类型的发布者。使用$访问发布者
    @Published var username:String = ""
    
    var mBackgroundQueue:DispatchQueue = .init(label: "mBackgroundQueue")
    
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
    
    func sampleMap() {
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
                self.deferredAsyncApiCall(sabotage: true) { grantedAccess, err in
                    if let err = err {
                        return promise(.failure(err))
                    }
                    return promise(.success(grantedAccess))
                }
            }
        }.eraseToAnyPublisher()
        
        
        cancelAble = deferredPublisher.sink { err in
            switch err {
            case let .failure(type):
                if let type = type as? TestFailureCondition {
                    if type == .anErrorExample {
                        print("")
                    }
                }
            default:
                break
            }
            print(".sink() received the completion: ", String(describing: err))
        } receiveValue: { value in
            print(".sink() received value: ", value)
            outputValue = value
        }
        
        
    }
    
    // 当生成Future后立马就触发了过程
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
    
    /// Subjects 可以通过调用 .send(_:) 方法来将值“注入”到流中 一个 subject 还可以向多个订阅者广播消息
    /// CurrentValueSubject 需要一个初始值并记住它当前的值
    func sampleCurrentValueSubject() {
        let simpleControlledPublisher = CurrentValueSubject<String, Error>("initial value")
        cancelAble = simpleControlledPublisher
            .print("(1)>")
            .retry(2)
            .print("(2)>")
            .sink { fini in
                print(" ** .sink() received the completion:", String(describing: fini))
            } receiveValue: { stringValue in
                print(" ** .sink() received \(stringValue)")
            }
        
        let oneFish = "onefish"
        simpleControlledPublisher.send(oneFish)
        simpleControlledPublisher.send(completion: Subscribers.Completion.failure(TestFailureCondition.anErrorExample))
    }
    
    //PassthroughSubject 不需要初始值
    //flatMap在RXSwift中是讲多个数组的元素压平为一个数组
    //在Combine中 是与错误恢复或可能失败的异步操作(例如Future)一起使用时，flatMap将用另一个发布者替换任何传入值
    func samplePassthroughSubject() {
        let x = PassthroughSubject<String,Never>()
            .flatMap { name in
                return Future<String,Error> { promise in
                    promise(.success(""))
                }.catch { _ in
                    Just("No user found")
                }.map { result in
                    return "\(result) foo"
                }
            }.eraseToAnyPublisher() //类型擦除
    }
    
    fileprivate struct PostmanEchoTimeStampCheckResponse: Decodable, Hashable {
        let valid: Bool
    }
    
    //Just 以传入一个 URL 作为示例启动此发布者。
    //flatMap 以 URL 作为输入，闭包继续创建一次性发布者管道。
    //dataTaskPublisher 使用输入的 url 发出请求
    //输出的结果（一个 (Data, URLResponse) 元组）流入 tryMap 以解析其他错误。
    //decode 尝试将返回的数据转换为本地定义的类型。
    //如果其中任何一个失败，catch 将把错误转换为一个默认的值。 在这个例子中，是具有预设好 valid = false 属性的对象。
    func sampleTryMap() {
        let url = URL(string: "https://www.baidu.com")!
        let remoteDataPublisher = Just(url)
            .flatMap { url in
                URLSession.shared.dataTaskPublisher(for: url)
                    .tryMap { (data: Data, response: URLResponse) in
                        guard let httpResponse = response as? HTTPURLResponse,
                              httpResponse.statusCode == 200 else {
                            throw TestFailureCondition.anErrorExample
                        }
                        return data
                    }
                    .decode(type: PostmanEchoTimeStampCheckResponse.self, decoder: JSONDecoder())
                    .catch { _ in
                        return Just(PostmanEchoTimeStampCheckResponse(valid: false))
                    }
            }.eraseToAnyPublisher()
    }
    
    //throttle 发布上游发布者在指定时间间隔内发布的最新元素或第一个元素。 调度器myBackGroundQueue将结果元素发布到该队列中，从而使此处理移出主运行循环。
    //removeDuplicates 仅发布与前一个元素不匹配的元素。(仅适用于符合Equatable的输出类型)
    func sampleSwitchToLatest() {
        
        $username.throttle(for: 0.5, scheduler: mBackgroundQueue, latest: true)
            .removeDuplicates()
            .print("username pipeline: ")
            .map { username -> AnyPublisher<[GithubAPIUser],Never> in
                GithubAPI.retrieveGithubUser(username: username)
            }
            .switchToLatest() //将管道里面的值转化为最终的值而不是一个发布者
            .receive(on: RunLoop.main)
            .sink { value in
                print("最终结果:\(value)")
            }.store(in: &cancelSet)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.username = "b"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.username = "c"
        }
    }
    
    /// Scan就像一个累加器，根据您提供的闭包收集和修改值，并发布来自上游的每次更改的中间结果
    /// Prints "0 1 3 6 10 15 ".
    func scanSample() {
        _ = (0...5).publisher.scan(0, {
            return $0 + $1
        }).sink {
            print("\($0)")
        }
    }
    
    /// tryScan:通过将当前元素提供给抛出错误的闭包以及闭包返回的最后一个值，转换来自上游发布者的元素。
    /// Prints: "11 6 3 1 1 failure(ControlUsageLib.CombindLearn.TestFailureCondition.anErrorExample)".
    func tryScanSample() {
        let numbers = [1,2,3,4,5,0,6,7,8,9]
        _ = numbers.publisher
            .tryScan(10) {
                guard $1 != 0 else { throw TestFailureCondition.anErrorExample }
                return ($0 + $1) / $1
            }
            .sink(
                receiveCompletion: { print ("\($0)") },
                receiveValue: { print ("\($0)", terminator: " ") }
            )
    }
        
}
