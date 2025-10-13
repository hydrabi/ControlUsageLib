//
//  CodableSampble.swift
//  ControlUsageLib
//
//  Created by 毕志锋 on 2025/9/21.
//  codable教程 https://juejin.cn/post/7100194774656745480#heading-14

import Foundation

struct CodablePerson:Codable {
    let name:String
    let age:Int
    
    enum CodingKeys:String,CodingKey {
        //防止字段映射名称和字段本身名臣不一致
        case name = "name",
             age = "age"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.age = try container.decode(Int.self, forKey: .age)
    }
    
    func encode(to encoder:Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey:.name)
        try container.encode(age, forKey: .age)
    }
    
    init(name:String,age:Int) {
        self.name = name
        self.age = age
    }
}

struct Family:Codable {
    let familyName:String
    let persons:[CodablePerson]
}

struct EmptyFamily:Codable {
    let familyName:String
    var familyType:FamilyType = .type1
    var person1:CodablePerson?
    var person2:CodablePerson?
    
    //当遇到返回值为空时，需要给对应的属性设置一个默认值
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.familyName = try container.decode(String.self, forKey: .familyName)
        self.familyType = try container.decode(FamilyType.self, forKey: .familyType)
        self.person1 = try container.decodeIfPresent(CodablePerson.self, forKey: .person1)
        self.person2 = try container.decodeIfPresent(CodablePerson.self, forKey: .person2) ?? CodablePerson(name: "empty", age: 0)
    }
    
    init(familyName:String,
         familyType:FamilyType = .type1,
         person1:CodablePerson? = nil,
         person2:CodablePerson? = nil) {
        self.familyName = familyName
        self.familyType = familyType
        self.person1 = person1
        self.person2 = person2
    }
}

enum FamilyType:String,Codable {
    case type1
    case type2
}

//手动编码

//json结构
//{
//    "latitude" : xxx
//    "longitude": xxx
//    "additionalInfo": {
//        "elevation" : xxx
//        "elevation2": xxx
//        "elevation3": xxx
//        ......
//    }
//}

struct CodableCoordinate:Codable {
    var latitude: Double
    var longitude: Double
    var elevation: Double
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case additionalInfo
    }
    
//    CodingKeys 本质上是用来描述 JSON 中的 key 的。那么对于 additionalInfo 来说，我们可能只需要其中的 elevation，所以就有了 AdditionalInfoKeys：
//    所以，可以认为，AdditionalInfoKeys 就是用来 additionalInfo 内部的 key 的。此时在 Coordinate 中，我们就可以直接用 additionalInfo 中的 elevation 作为 Coordinate 的属性。
    enum AdditionalInfoKeys: String, CodingKey {
        case elevation
    }
    
    init(from decoder: any Decoder) throws {
        //返回此解码器中存储的数据，这些数据以由给定键类型键入的容器形式表示。(获取 CodingKey 的对应关系。)
        let values = try decoder.container(keyedBy: CodingKeys.self)
        //解析单个属性。
        latitude = try values.decode(Double.self,
                                     forKey: .latitude)
        longitude = try values.decode(Double.self,
                                      forKey: .longitude)
        //返回给定键所存储的数据，该数据以由给定键类型键入的容器形式表示。(获取内嵌的层级。)
        let additionInfo = try values.nestedContainer(keyedBy: AdditionalInfoKeys.self,
                                                      forKey: .additionalInfo)
        elevation = try additionInfo.decode(Double.self,
                                        forKey: .elevation)
    }
    
    func encode(to encoder:Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        
        var additionInfo = container.nestedContainer(keyedBy: AdditionalInfoKeys.self,
                                                     forKey: .additionalInfo)
        try additionInfo.encode(elevation, forKey: .elevation)
    }
}

//假设，服务器返回一个字段，可能是 Int 类型，可能是 String 类型，虽然这种情况比较少，但还是有些后台会这么给数据 😓。
struct StringInt: Codable {
    var stringValue: String
    
    var intValue: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            stringValue = value
            intValue = Int(value) ?? 0
        } else if let value = try? container.decode(Int.self) {
            stringValue = "\(value)"
            intValue = value
        } else {
            stringValue = ""
            intValue = 0
            
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if !stringValue.isEmpty {
            try? container.encode(stringValue)
        } else {
            try? container.encode(intValue)
        }
    }
}



class CodableSampble {
    
    //将类转换为json例子
    func encodeSample1() {
        let person = CodablePerson(name: "ted", age: 10)
        let encoder = JSONEncoder()
        //将类转换为data
        let data = try? encoder.encode(person)
        //将data转换为json字符串
        let jsonStr = String(data: data!, encoding: .utf8)
        //将data转换为json字典
        let jsonObject = try? JSONSerialization.jsonObject(with: data!,options: [])
        print("jsonStr is \(jsonStr!),jsonObject is \(jsonObject!)")
    }
    
    //将jsonData转换为类例子
    func decodeSample() {
        let person = CodablePerson(name: "ted", age: 10)
        let encoder = JSONEncoder()
        //将类转换为data
        let data = try? encoder.encode(person)
        
        let decoder = JSONDecoder()
        //解码json数据
        let decodePerson = try? decoder.decode(CodablePerson.self,from: data!)
        print("decode Person is \(decodePerson!)")
    }
    
    //嵌套类型转换例子
    func decodeNestSample() {
        let person1 = CodablePerson(name: "ted", age: 10)
        let person2 = CodablePerson(name: "bar", age: 20)
        let family = Family(familyName: "family", persons: [person1,person2])
        let encoder = JSONEncoder()
        let data = try? encoder.encode(family)
        let jsonStr = String(data: data!, encoding: .utf8)
        let decoder = JSONDecoder()
        //解码json数据
        let decodeFamily = try? decoder.decode(Family.self,
                                               from: data!)
        print("decode Family is \(decodeFamily!)")
    }
    
    //属性有可能为空的转换例子
    func decodeNilSample() {
        let person1 = CodablePerson(name: "ted", age: 10)
        let family = EmptyFamily(familyName: "family",familyType: .type2,person1: person1)
        let encoder = JSONEncoder()
        let data = try? encoder.encode(family)
        let jsonStr = String(data: data!, encoding: .utf8)
        let decoder = JSONDecoder()
        //解码json数据
        let decodeFamily = try? decoder.decode(EmptyFamily.self,
                                               from: data!)
        print("decode Family is \(decodeFamily!)")
    }
}
