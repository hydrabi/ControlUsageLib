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
        let path = try? FileManager.default.url(for: .documentDirectory,
                                                in: .userDomainMask,
                                                appropriateFor: nil,
                                                create: true).appendingPathComponent("/DataBase/sample.db")
        let database = Database(at: path!)
        //等效于创建数据库语句
        try? database.create(table: "sampleTable", of: Sample.self)
        return database
    }()
    
    
    func test () {
        
        //插入
        let object = Sample()
        object.identifier = 1
        object.description = "sample_insert"
        do {
            //成功
            try database.insert(object, intoTable: "sampleTable")
        }
        catch (let error) {
            print(error.localizedDescription)
        }
        
        do {
            //失败 因为主键 identifier = 1 已经存在
            try database.insert(object, intoTable: "sampleTable")
        }
        catch (let error) {
            print(error)
        }

        let objects:[Sample] = try! database.getObjects(fromTable: "sampleTable")
        
    }
    
   
}
