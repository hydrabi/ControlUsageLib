//   HandyJsonUsage.swift
//   ControlUsageLib
//
//   Created by Ted on 2024/4/11
//   


import Foundation
import HandyJSON

class HandyJsonUsage {
    
    class BasicTypes:HandyJSON {
        var int:Int = 2
        var doubleOptional:Double?
        var stringImplicitlyUnwrapped: String!
        
        required init() {}
    }
    
    
    struct BasicStruct:HandyJSON {
        var int:Int = 2
        var doubleOptional:Double?
        var stringImplicitlyUnwrapped: String!
    }
    
    func usage() {
        let jsonString = "{\"doubleOptional\":1.1,\"stringImplicitlyUnwrapped\":\"hello\",\"int\":1}"
        if let object = BasicStruct.deserialize(from: jsonString) {
            print("success")
        }
    }
}
