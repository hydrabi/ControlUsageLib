//   SWXMLHashUsage.swift
//   ControlUsageLib
//
//   Created by Ted on 2024/4/9
//   


import Foundation
import SWXMLHash
class SWXMLHashUsage {
    func parseXML() {
        let xmlFilePath = Bundle.main.path(forResource: "description", ofType: "xml")
        let xmlData = NSData(contentsOfFile: xmlFilePath!)
        let xmlStr = String(data: xmlData! as Data, encoding: .utf8)
        let xml = XMLHash.parse(xmlStr!)
        //所有
        let DMXModes = xml["FixtureType"]["DMXModes"].all
    }
}
