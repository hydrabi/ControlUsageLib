//   PagetConcurrencyRequest.swift
//   ControlUsageLib
//
//   Created by Ted on 2025/10/9
//   


import Foundation
import Combine

/// 请求类型
enum requestType {
    case userQuery //请求用户灯库
    case gdtfQuery //请求gdtf灯库
}

protocol requestProtocol {
    
    /// 请求类型 区分用户灯库或者gdtf灯库
    var type:requestType {get set}
    
    /// 时间戳
    var updateTime:Int {get set}
    
    /// 页码
    var startIndex:Int {get set}
    
    /// 每页条数
    var pageSize:Int {get set}
}

final class PageRequest:requestProtocol {
    
    var type: requestType = .userQuery
    
    var updateTime: Int = 0
    
    /// 其实页码从1开始
    var startIndex: Int = 0
    
    var pageSize: Int = 10
    
    init(type: requestType, updateTime: Int, startIndex: Int, pageSize: Int) {
        self.type = type
        self.updateTime = updateTime
        self.startIndex = startIndex
        self.pageSize = pageSize
    }
    
    init() {}
}

struct PageResponse<T:Codable>:Codable {
    
    /// 响应的数据
    let data:[T]
    
    /// 数据总数量
    let total:Int
    
    /// 当前页码
    let currentIndex:Int
    
    /// 剩余数量
    let remaining:Int
    
    /// 请求失败不抛出错误 而是返回错误页码 记录下次重新请求
    let success:Bool
}

struct dataFetchConfig {
    
    /// 每页最多请求数量
    let basePageSize: Int
    
    /// 最大并发数
    let concurrency: Int
    
    /// 请求失败重试次数
    let retryAttempts: Int
    
    /// 重试延迟时间
    let retryDelay: TimeInterval
    
    static let shared = dataFetchConfig(basePageSize: 10,
                                        concurrency: 3,
                                        retryAttempts: 3,
                                        retryDelay: 1)
}

/// 分片信息
struct dataShard {
    
    /// 累计到当前页的数量
    let startIndex:Int
    
    /// 每页的条数
    let pageSize:Int
    
    /// 请求的页码
    let shardIndex:Int
}

// 进度信息
struct FetchProgress {
    
    /// 总共请求的数量
    let processed: Int
    /// 总数量
    let total: Int
    /// 请求进度
    let percentage: Double
}

// 获取状态
enum FetchStatus {
    //闲置中
    case idle
    //请求中
    case fetching
    //请求完成
    case completed
    //请求失败
    case failed(Error)
    //请求取消
    case cancelled
}

class CombinePaginationFetcher<T: Codable> {
    typealias FetchHandler = (PageRequest) -> AnyPublisher<PageResponse<T>,Error>
    
    // MARK: - 属性
    
    /// 对请求的处理 处理完成后生成新的发布者
    private let fetchHandler: FetchHandler
    
    /// 请求属性的配置
    private let config: dataFetchConfig
    private let scheduler: DispatchQueue
    
    //当前请求状态
    private let statusSubject = CurrentValueSubject<FetchStatus,Never>(.idle)
    //进度
    private let progressSubject = PassthroughSubject<FetchProgress,Never>()
    //取消订阅
    private var cancellables = Set<AnyCancellable>()
    
    // 进度跟踪
    private var totalRecords = 0
    private var processedRecords = 0
    private var completedShards = 0
    private var totalShards = 0
    
    /// 已经请求成功的数据
    var fetcheSuccessData:[T] = []
    
    var statusPublisher:AnyPublisher<FetchStatus,Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    var progressPublisher:AnyPublisher<FetchProgress,Never> {
        progressSubject.eraseToAnyPublisher()
    }
    
    init(fetchHandler: @escaping FetchHandler,
         config: dataFetchConfig = .shared,
         scheduler: DispatchQueue = .global(qos: .userInitiated)) {
        self.fetchHandler = fetchHandler
        self.config = config
        self.scheduler = scheduler
    }
    
    func getCurrentProgress() -> FetchProgress {
        var percentage:Double = 0
        guard totalRecords != 0 else {
            return FetchProgress(
                processed: processedRecords,
                total: totalRecords,
                percentage: percentage
            )
        }
        
        percentage = totalRecords > 0 ? Double(processedRecords) / Double(totalRecords) * 100.0 : 0.0
        return FetchProgress(
            processed: processedRecords,
            total: totalRecords,
            percentage: percentage
        )
    }
    
    func resetProgress() {
        totalRecords = 0
        processedRecords = 0
        completedShards = 0
        totalShards = 0
        //清空上次请求的数据
        fetcheSuccessData.removeAll()
    }
    
    func updateProgress() {
        let progress = getCurrentProgress()
        progressSubject.send(progress)
    }
    
    func fetchAllData() -> AnyPublisher<[T],Never> {
        //请求中
        guard case .idle = statusSubject.value else {
            return Just([]).eraseToAnyPublisher()
        }
        
        statusSubject.send(.fetching)
        resetProgress()
        
        return Deferred {
            [weak self] in guard let strongSelf = self else { return Empty<[T],Never>().eraseToAnyPublisher() }
            //先请求第一页数据查看是否有新的剩余数据需要请求
            return strongSelf.fetchFirstPage()
                .flatMap { firstPage -> AnyPublisher<[T],Never> in
                    strongSelf.totalRecords = firstPage.total
                    print("总数据量:\(strongSelf.totalRecords)")
                    //没有数据或者请求失败都不抛出错误 主要是为了部分请求错误仍然不影响其它请求的执行
                    if strongSelf.totalRecords == 0  {
                        return Just([]).eraseToAnyPublisher()
//                        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
                    }
                    else if !firstPage.success {
                        print("获取第一页数据失败")
                        return Just([]).eraseToAnyPublisher()
                    }
                    else {
                        //请求成功则添加第一页的数据
                        strongSelf.fetcheSuccessData.append(contentsOf: firstPage.data)
                    }
                    return strongSelf.fetchAllShards()
                }
                .handleEvents(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        strongSelf.statusSubject.send(.completed)
                    case .failure(let error):
                        strongSelf.statusSubject.send(.failed(error))
                    }
                },
                              receiveCancel: {
                    strongSelf.statusSubject.send(.cancelled)
                })
                .eraseToAnyPublisher()
        }
        .subscribe(on: scheduler)
        .eraseToAnyPublisher()
    }
    
    func fetchWithRetry(request:PageRequest) -> AnyPublisher<PageResponse<T>,Error> {
        if #available(iOS 14.0, *) {
            return fetchHandler(request)
            //当上游发布者发出错误时 retry 会重新订阅并重新启动发布者
                .retryWithDelay(config.retryAttempts,
                                delay: config.retryDelay)
                .catch { error -> AnyPublisher<PageResponse<T>, Error> in
                    print("重试请求 \(request.startIndex) 达到最大重试次数: \(error)")
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        else {
        return fetchHandler(request)
        //当上游发布者发出错误时 retry 会重新订阅并重新启动发布者
            .retry(config.retryAttempts)
            .catch { error -> AnyPublisher<PageResponse<T>, Error> in
                print("重试请求 \(request.startIndex) 达到最大重试次数: \(error)")
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        }
    }
    
    func fetchFirstPage() -> AnyPublisher<PageResponse<T>,Never> {
        let firstRequest = PageRequest()
        firstRequest.startIndex = 1
        firstRequest.pageSize = 10
        print("开始首次请求")
        //请求失败不抛出错误
        return fetchWithRetry(request: firstRequest)
            .replaceError(with: PageResponse(data: [],
                                             total: 0,
                                             currentIndex: 0,
                                             remaining: 0,
                                             success: false))
            .eraseToAnyPublisher()
    }
    
    
    //计算一共要下载多少页（需要减去第一页）
    func calculateShards(total:Int) -> [dataShard] {
        var shards:[dataShard] = []
        //累计的数据请求数量（第一页已请求）
        var currentNums = fetcheSuccessData.count
        //累计的页码(页码从1开始,第一页已经请求，所以初始为2)
        var shardIndex = 2
        
        while currentNums < total {
            //剩余的数据可能少于每页的条数
            let actualSize = min(config.basePageSize, total - currentNums)
            let shard = dataShard(startIndex: currentNums, pageSize: actualSize, shardIndex: shardIndex)
            shards.append(shard)
            currentNums += actualSize
            shardIndex += 1
        }
        return shards
    }
    
    /// 请求所有剩余页数
    /// - Returns: 发布者
    func fetchAllShards() -> AnyPublisher<[T],Never> {
        let shards = calculateShards(total: totalRecords)
        totalShards = shards.count
        print("共\(totalShards)页需要请求")
        
        let shardPublishers = shards.map { shard in
            fetchShard(shard)
        }
        
        let scanTemp:(Int,Int,[PageResponse<T>]) = (0,0,[])
        
        //限制最大并发数为5个
        return Publishers.Sequence(sequence: shardPublishers)
            .flatMap(maxPublishers: .max(5)) { publisher in
                publisher
            }
            .scan(scanTemp, { accumulator, value in
                
                let newCompleted = accumulator.0 + 1
                let newProcessed = accumulator.1 + value.data.count
                let newResponses = accumulator.2 + [value]
                var percentage:Double = 0
                percentage = self.totalRecords > 0 ? Double(newProcessed) / Double(self.totalRecords) * 100.0 : 0.0
                
                if value.success {
                    print("分页\(value.currentIndex)完成，进度\(newProcessed)")
                }
                else {
                    print("分页\(value.currentIndex)失败，记录失败页码")
                }
                
                //进度更新
                let progress = FetchProgress(processed: newProcessed,
                                             total: self.totalShards,
                                             percentage: percentage)
                DispatchQueue.main.async {
                    self.progressSubject.send(progress)
                }
                return (newCompleted, newProcessed, newResponses)
            })
            //只取最后一个累计值
            .last()
            //只取响应数据
            .map{$0.2}
            .map { response in
                let allData = response.flatMap { $0.data }
                print("请求完成，除第一页剩余共\(allData.count)条数据")
                return allData
            }
            .eraseToAnyPublisher()
    }
    
    //请求单页
    func fetchShard(_ shard:dataShard) -> AnyPublisher<PageResponse<T>,Never> {
        let request = PageRequest(type: .userQuery,
                                  updateTime: 0,
                                  startIndex: shard.shardIndex,
                                  pageSize: shard.pageSize)
        //使用空的响应对象代替抛出错误 防止单个错误整体失败
        let data:[T] = []
        let errorReplaceResponse = PageResponse(data: data,
                                    total: self.totalRecords,
                                    currentIndex: request.startIndex,
                                    remaining: self.totalRecords - request.startIndex,
                                    success: false)

        return Deferred {
            self.fetchWithRetry(request: request)
                .replaceError(with: errorReplaceResponse)
                .handleEvents(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("分页\(shard.shardIndex)失败:\(error)")
                    }
                })
        }
        .eraseToAnyPublisher()

    }
    
    func cancel() {
        //取消所有订阅
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        if case .fetching = statusSubject.value {
            statusSubject.send(.cancelled)
        }
    }
    
    deinit {
        cancel()
    }
}

struct SampleData:Codable,Identifiable {
    let id:Int
    let content:String
}

class APIService {
    static let shared = APIService()
    private var totalRecords = 100
    
    func fetchPage(_ request:PageRequest) -> AnyPublisher<PageResponse<SampleData>,Error> {
        print("触发页码为\(request.startIndex)的任务")
        let delay = Double.random(in: 0.5...2.0)
//        let delay = Double.random(in: 5...10)
        return Deferred {
            Future<PageResponse<SampleData>,Error> { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    let randomValue = Double.random(in: 0...1)
                    if randomValue < 0.2 {
                        print("页码:\(request.startIndex)模拟请求失败触发，随机数为\(randomValue)")
                        promise(.failure(NSError(domain: "TestError", code: -1, userInfo: nil)))
                        return
                    }
                    print("页码:\(request.startIndex)成功，随机数为\(randomValue)")
                    let start = request.startIndex
                    let end = min(start + request.pageSize, self.totalRecords)
                    let data = (start..<end).map { index in
                        SampleData(id: index, content: "Item \(index)")
                    }
                    let response = PageResponse(data: data,
                                                total:self.totalRecords,
                                                currentIndex: start,
                                                remaining:self.totalRecords - end,
                                                success: true)
                    promise(.success(response))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

//模拟请求
class FetchDemo {
    
    var fetcher:CombinePaginationFetcher<SampleData>
    var cancelable = Set<AnyCancellable>()
    
    init() {
        fetcher = CombinePaginationFetcher(fetchHandler: { request in
            APIService.shared.fetchPage(request)
        },config: dataFetchConfig(basePageSize: 10,
                                  concurrency: 3,
                                  retryAttempts: 3,
                                  retryDelay: 2))
        setBinding()
    }
    
    //监听状态变化
    func setBinding() {
        fetcher.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { status in
                print("当前请求状态为\(status)")
            }
            .store(in: &cancelable)
        
        fetcher.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { progress in
//                print("当前请求进度为\(progress.percentage)")
            }
            .store(in: &cancelable)
    }
    
    func startFetchAllData() {
        let startTime = Date()
        fetcher.fetchAllData()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                let duration = Date().timeIntervalSince(startTime)
                switch completion {
                case .finished:
                    print("请求完成，耗时\(duration)秒")
                case .failure(let error):
                    print("请求失败，原因:\(error.localizedDescription)")
                }
            } receiveValue: { data in
                print("请求成功，共\(data.count)条数据")
            }
            .store(in: &cancelable)
    }
    
    func startFetchFirstPage() {
        let startTime = Date()
        let publish = Deferred {
            Future<PageResponse<SampleData>,Error> { promise in
                
                let randomValue = Double.random(in: 0...1)
                print("随机数为\(randomValue)")
                if randomValue < 1 {
                    promise(.failure(NSError(domain: "TestError", code: -1, userInfo: nil)))
                    return
                }
                let temp:[SampleData] = []
                let response = PageResponse(data: temp,
                                            total:0,
                                            currentIndex: 0,
                                            remaining:0,
                                            success: true)
                promise(.success(response))
            }
        }.eraseToAnyPublisher()
        
        publish.receive(on: DispatchQueue.main)
            .retry(3)
            .sink { completion in
                let duration = Date().timeIntervalSince(startTime)
                switch completion {
                case .finished:
                    print("请求完成，耗时\(duration)秒")
                case .failure(let error):
                    print("请求失败，原因:\(error.localizedDescription)")
                }
            } receiveValue: { data in
                print("请求成功，\(data)")
            }
            .store(in: &cancelable)
    }
}


@available(iOS 14.0, *)
extension Publisher {
    func retryWithDelay<T, E>(_ retries: Int, delay: TimeInterval) -> AnyPublisher<T, E> where T == Self.Output, E == Self.Failure {
        return self
            .catch { error -> AnyPublisher<T, E> in
                // 递归实现带延迟的重试
                if retries > 0 {
                    return Just(0)
                        .delay(for: .seconds(delay), scheduler: RunLoop.main)
                        .flatMap { _ in
                            self.retryWithDelay(retries - 1, delay: delay)
                        }
                        .eraseToAnyPublisher()
                } else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}

