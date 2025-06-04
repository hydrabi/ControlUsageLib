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

//标记此类为final
final class Parent: TableCodable {
    var uuid:String = ""
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = Parent
        static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(uuid,isPrimary: true)
        }
        case uuid
    }
}

//标记此类为final
final class Child: TableCodable {
    var uuid:String = ""
    var fuuid:String = ""
    
//    let forKey =
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = Child
        static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(uuid,isPrimary: true)
            BindForeginKey(Child.Properties.fuuid,
                           foreignKey: ForeignKey().references(with: "parentTable").columns(Column(named: "uuid")))
        }
        case uuid
        case fuuid
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
        try? database.create(table: "parentTable", of: Parent.self)
        try? database.create(table: "childTable", of: Child.self)
        return database
    }()
    
    
    func test () {
        
//        //插入
//        let object = Sample()
//        object.identifier = 1
//        object.description = "sample_insert"
//        do {
//            //成功
//            try database.insert(object, intoTable: "sampleTable")
//        }
//        catch (let error) {
//            print(error.localizedDescription)
//        }
//        
//        do {
//            //失败 因为主键 identifier = 1 已经存在
//            try database.insert(object, intoTable: "sampleTable")
//        }
//        catch (let error) {
//            print(error)
//        }
//
//        let objects:[Sample] = try! database.getObjects(fromTable: "sampleTable")
        
        try? database.exec(StatementPragma().pragma(Pragma.foreignKeys))
        
        let parent = Parent()
        parent.uuid = "1"
        try? database.insertOrReplace(parent, intoTable: "parentTable")
        
        let child1 = Child()
        child1.uuid = "1"
        child1.fuuid = "1"
        try? database.insertOrReplace(child1, intoTable: "childTable")
        
        let child2 = Child()
        child2.uuid = "2"
        child2.fuuid = "1"
        try? database.insertOrReplace(child2, intoTable: "childTable")
        
        let childAry:[Child] = try! database.getObjects(on: Child.Properties.all, fromTable: "childTable")
        let parentAry:[Parent] = try! database.getObjects(on: Parent.Properties.all, fromTable: "parentTable")
        
        try! database.delete(fromTable: "parentTable",where: Parent.Properties.uuid == "1")
        let parent1Ary:[Parent] = try! database.getObjects(on: Parent.Properties.all, fromTable: "parentTable")
        let child1Ary:[Child] = try! database.getObjects(on: Child.Properties.all, fromTable: "childTable")
        print("")
    }
    
   
}
