//   PromiseLearn.swift
//   ControlUsageLib
//
//   Created by Ted on 2024/4/22
//   


import Foundation
//http://chuquan.me/2022/10/16/promise-core-implement/

//状态
enum State {
    case pending
    case fulfilled
    case rejected
}

class Promise<T> {
    //状态更新方法 成功后的回调
    typealias Resolve<W> = (W) -> Void
    //状态更新方法 失败后的回调
    typealias Reject = (Error) -> Void
    typealias Executor = ( _ resolve:@escaping Resolve<T>, _ reject:@escaping Reject) -> Void
    /// 当前状态
    private(set) var state:State = .pending
    
    /// 当前的值
    private(set) var value:T?
    private(set) var error:Error?
    
    /// fulfilled 状态的回调任务
    private(set) var onFulfilledCallbacks = [Resolve<T>]()
    private(set) var onRejectedCallbacks = [Reject]()
    
    init(_ executor:Executor) {
        let resolve:Resolve<T> = { value in
            self.value = value
            self.onFulfilledCallbacks.forEach { onFullfilled in
                onFullfilled(value)
            }
            self.state = .fulfilled
        }
        let reject:Reject = { error in
            self.error = error
            self.onRejectedCallbacks.forEach { onRejected in
                onRejected(error)
            }
            self.state = .rejected
        }
        executor { value in
            resolve(value)
        } _ : { error in
            reject(error)
        }
    }
}

extension Promise {
    @discardableResult
    func then<R>(onFulfilled:@escaping (T) -> R,onRejected:@escaping (Error) -> Void) -> Promise<R> {
        switch state {
        case .pending:
            //将普通函数应用到包装类型，并返回包装类型
            return Promise<R> { [weak self] resolve,reject in
                //初始化时即执行
                //在curr promise 加入 onFulfilled/onRejected 任务，任务可修改 curr promise 的状态
                self?.onFulfilledCallbacks.append({ value in
                    let r = onFulfilled(value)
                    resolve(r)
                })
                self?.onRejectedCallbacks.append({ error in
                    onRejected(error)
                    reject(error)
                })
            }
        default:
            break
        }
    }
}
