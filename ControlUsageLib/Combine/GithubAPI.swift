//   GithubAPI.swift
//   ControlUsageLib
//
//   Created by Ted on 2024/6/22
//   

import Combine
import Foundation

enum APIFailureCondition:Error {
    case invalidServerResponse
}

struct GithubAPIUser:Decodable {
    let login: String
    let public_repos: Int
    let avatar_url: String
}

enum GithubAPI {
    static let networkActivityPublisher = PassthroughSubject<Bool,Never>()
    
    static func retrieveGithubUser(username:String) -> AnyPublisher<[GithubAPIUser],Never> {
        if username.count < 3 {
            return Just([]).eraseToAnyPublisher()
        }
        let assembledURL = String("https://api.github.com/users/\(username)")
        let publisher = URLSession.shared.dataTaskPublisher(for: URL(string: assembledURL)!)
            //发生发布者事件时执行指定的闭包。
            .handleEvents(receiveSubscription: { _ in //接收到订阅
                //发送需要加载的信号
                networkActivityPublisher.send(true)
            },receiveCompletion: { _ in  //一个可选闭包，当上游发布者正常完成或以错误终止时执行。该值默认为nil。
                //发送需要加载的信号
                networkActivityPublisher.send(false)
            },receiveCancel: { //当下游接收方取消发布时执行的可选闭包。该值默认为nil
                networkActivityPublisher.send(false)
            })
            .tryMap { data,response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,httpResponse.statusCode == 200
                else {
                    throw APIFailureCondition.invalidServerResponse
                }
                return data
            }
            .print("结果返回： ")
            .decode(type: GithubAPIUser.self, decoder: JSONDecoder())
            .print("结果解析： ")
            .map { [$0] }
            .replaceError(with: []) //把所有抛出的错误替换成提供的元素
            .eraseToAnyPublisher() //类型擦除 暴露AnyPublisher而不是真实的类型
        return publisher
    }
}
