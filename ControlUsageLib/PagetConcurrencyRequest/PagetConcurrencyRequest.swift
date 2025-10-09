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
    let startIndex:Int
    let pageSize:Int
    let shardIndex:Int
}

// 进度信息
struct FetchProgress {
    let processed: Int
    let total: Int
    let percentage: Double
    let activeShards: Int
    let status: FetchStatus
}

// 获取状态
enum FetchStatus {
    case idle
    case fetching
    case completed
    case failed(Error)
    case cancelled
}

// 错误类型
enum DataFetchError: Error, LocalizedError {
    case fetchInProgress
    case networkError(Error)
    case invalidResponse
    case maxRetriesExceeded
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .fetchInProgress:
            return "已有正在进行的获取操作"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的响应数据"
        case .maxRetriesExceeded:
            return "已达到最大重试次数"
        case .cancelled:
            return "操作已取消"
        }
    }
}

class CombinePaginationFetcher<T: Codable> {
    typealias FetchHandler = (PageRequest) -> AnyPublisher<PageResponse<T>,Error>
    
    // MARK: - 属性
    private let fetchHandler: FetchHandler
    private let config: dataFetchConfig
    private let scheduler: DispatchQueue
    
    //当前请求状态
    private let statusSubject = CurrentValueSubject<FetchStatus,Never>(.idle)
    //进度
    private let progressSubject = PassthroughSubject<FetchProgress,Never>()
    //取消订阅
    private var cancellables = Set<AnyCancellable>()
    private var shardPublishers:[AnyPublisher<PageResponse<T>,Error>] = []
    
    // 进度跟踪
    private var totalRecords = 0
    private var processedRecords = 0
    private var completedShards = 0
    private var totalShards = 0
    
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
    
    func fetchAllData() -> AnyPublisher<[T],DataFetchError> {
        //请求中
        guard case .idle = statusSubject.value else {
            return Fail(error: DataFetchError.fetchInProgress).eraseToAnyPublisher()
        }
        
        statusSubject.send(.fetching)
//        resetProgress()
        
        return Deferred {
            [weak self] in guard let strongSelf = self else { return Empty<[T],DataFetchError>().eraseToAnyPublisher() }
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
                    print("分片 \(request.startIndex) 达到最大重试次数: \(error)")
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
                    print("分片 \(request.startIndex) 达到最大重试次数: \(error)")
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
    }
    
    func fetchFirstPage() -> AnyPublisher<PageResponse<T>,DataFetchError> {
        let firstRequest = PageRequest()
        firstRequest.startIndex = 0
        firstRequest.pageSize = 10
        
        return fetchWithRetry(request: firstRequest)
            .mapError { error in
                DataFetchError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
    
    //计算一共要下载多少页
    func calculateShards(total:Int) -> [dataShard] {
        var shards:[dataShard] = []
        var currentIndex = 0
        var shardIndex = 0
        
        while currentIndex < total {
            let actualSize = min(config.basePageSize, total - currentIndex)
            let shard = dataShard(startIndex: currentIndex, pageSize: actualSize, shardIndex: shardIndex)
            shards.append(shard)
            currentIndex += actualSize
            shardIndex += 1
        }
        return shards
    }
    
    func fetchAllShards() -> AnyPublisher<[T],DataFetchError> {
        let shards = calculateShards(total: totalRecords)
        totalShards = shards.count
        print("共\(totalShards)页需要请求")
        
        let shardPublishers = shards.map { shard in
            fetchShard(shard)
        }
        
        //使用flatMap控制并发数目
//        return Publishers.MergeMany(shardPublishers)
//            .collect()
//            .map { response in
//                let allData = response.flatMap { $0.data }
//                print("共\(allData.count)条数据")
//                return allData
//            }
//            .mapError { error in
//                DataFetchError.networkError(error)
//            }
//            .eraseToAnyPublisher()
        //限制最大并发数为5个
        return Publishers.Sequence(sequence: shardPublishers)
            .flatMap(maxPublishers: .max(5)) { publisher in
                publisher
            }
            .collect()
            .map { response in
                let allData = response.flatMap { $0.data }
                print("共\(allData.count)条数据")
                return allData
            }
            .mapError { error in
                DataFetchError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func fetchShard(_ shard:dataShard) -> AnyPublisher<PageResponse<T>,Error> {
        let request = PageRequest(type: .userQuery,
                                  updateTime: 0,
                                  startIndex: shard.shardIndex,
                                  pageSize: shard.pageSize)
        return fetchWithRetry(request: request)
            .handleEvents { <#PageResponse<Decodable & Encodable>#> in
                <#code#>
            } receiveCompletion: { <#Subscribers.Completion<any Error>#> in
                <#code#>
            }
            .eraseToAnyPublisher()

    }
    
    func cancel() {
        //取消所有订阅
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        shardPublishers.removeAll()
        
        if case .fetching = statusSubject.value {
            statusSubject.send(.cancelled)
        }
    }
    
    deinit {
        cancel()
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

