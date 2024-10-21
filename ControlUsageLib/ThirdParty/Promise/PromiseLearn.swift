//   PromiseLearn.swift
//   ControlUsageLib
//
//   Created by Ted on 2024/4/22
//   


import Foundation
import Combine
import Contacts


class PromiseLearn {
    //模拟请求过程
    func loadUser() -> Future<Int,Error> {
        return Future() { promise in
            DispatchQueue.global().asyncAfter(wallDeadline: .now() + 1) {
                promise(.success(1))
            }
        }
    }
    
    func sample() {
        let future = loadUser()
       
    }
}



