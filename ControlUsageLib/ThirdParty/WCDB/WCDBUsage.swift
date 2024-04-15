//   WCDBUsage.swift
//   ControlUsageLib
//
//   Created by Ted on 2024/4/11
//   


import Foundation
import WCDBSwift

//标记此类为final
final class Sample: TableCodable {
    var identifier: Int? = nil
    var description: String? = nil
    
    
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = Sample
        static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(identifier,isPrimary: true)
            BindColumnConstraint(description,isNotNull: true,defaultTo: "defaultDescription")
        }
        case identifier
        case description
    }
}

class WCDBTestObject {
    
    lazy var database:Database = {
        let database = Database(at: "~/Test/sample.db")
        //等效于创建数据库语句
        try? database.create(table: "sampleTable", of: Sample.self)
        return database
    }()
    
    
    func test () {
        
        //插入
        let object = Sample()
        object.identifier = 1
        object.description = "sample_insert"
        try? database.insert(object, intoTable: "sampleTable")
        
        let objects:[Sample] = try! database.getObjects(fromTable: "sampleTable")
    }
}
