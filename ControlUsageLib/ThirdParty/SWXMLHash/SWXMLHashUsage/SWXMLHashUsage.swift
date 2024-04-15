//   SWXMLHashUsage.swift
//   ControlUsageLib
//
//   Created by Ted on 2024/4/9
//   


import Foundation
import SWXMLHash

/// LogicalChannel 中Snap的枚举属性
enum DMXSnapType:Int {
    case Yes,No,On,Off
}

/// 定义所有从属通道功能是否对控制系统定义的组控制做出反应。 值：“无”、“大”、“组”； 默认值：“无”。
enum DMXMasterType {
    case None,Grand,Group
}

/// FixtureType 节点是 XML 文件中灯具类型描述的起点。
struct FixtureType:XMLObjectDeserialization {
    
    /// 制造商
    let Manufacturer:String
    
    /// 用于显示为文件名和库名称的灯具类型名称
    let Name:String
    
    /// 灯具类型的长名称
    let LongName:String
    
    /// 灯具类型的简称。 短名称应尽可能短，但足以准确描述灯具类型
    let ShortName:String
    
    ///  灯具类型的唯一编号 (GUID)
    let FixtureTypeID:String
    
    let Protocols:[FTRDM]
    
    let DMXModes:[DMXMode]
    
    static func deserialize(_ element: XMLIndexer) throws -> FixtureType {
        //解析属性
        let Manufacturer = element.element?.attribute(by: "Manufacturer")?.text ?? ""
        let Name = element.element?.attribute(by: "Name")?.text ?? ""
        let LongName = element.element?.attribute(by: "LongName")?.text ?? ""
        let ShortName = element.element?.attribute(by: "ShortName")?.text ?? ""
        let FixtureTypeID = element.element?.attribute(by: "FixtureTypeID")?.text ?? ""
        
        //解析Protocols
        var tempProtocols = [FTRDM]()
        for FTRDMXMLIndexer in element["Protocols"]["FTRDM"].all {
            if let tempFTRDM = try? FTRDM.deserialize(FTRDMXMLIndexer) {
                tempProtocols.append(tempFTRDM)
            }
        }
        
        //解析所有DMXMode
        var tempDMXModes = [DMXMode]()
        for DMXModeXMLIndexer in element["DMXModes"]["DMXMode"].all {
            if let tempDMXMode = try? DMXMode.deserialize(DMXModeXMLIndexer) {
                tempDMXModes.append(tempDMXMode)
            }
        }
        
        return FixtureType(Manufacturer: Manufacturer,
                           Name: Name,
                           LongName: LongName,
                           ShortName: ShortName,
                           FixtureTypeID: FixtureTypeID,
                           Protocols: tempProtocols, DMXModes: tempDMXModes)
    }
}

/// 用于指定支持的协议。
struct FTRDM:XMLObjectDeserialization {
    
    /// 该灯具制造商的唯一 ID
    let ManufacturerID:String
    
    /// 设备的唯一ID
    let DeviceModelID:String
    
    static func deserialize(_ element: XMLIndexer) throws -> FTRDM {
        //解析属性
        let ManufacturerID = element.element?.attribute(by: "ManufacturerID")?.text ?? ""
        let DeviceModelID = element.element?.attribute(by: "DeviceModelID")?.text ?? ""
        
        return FTRDM(ManufacturerID: ManufacturerID, DeviceModelID: DeviceModelID)
    }
}

//每个模式 https://gdtf.eu/gdtf/file-spec/dmx-mode-collect/ 名词解析
struct DMXMode:XMLObjectDeserialization {
    /// DMX模式名称
    let Name:String
    
    /// DMX模式说明
    let Description:String
    
    /// DMX 通道和几何体之间的链接。 DMX 通道链接到与其逻辑和物理相关的几何体。 例如，将控制平移的 DMX 通道链接到代表轭的几何体。
    let Geometry:String
    
    let DMXChanels:[DMXChanel]
    
    static func deserialize(_ element: XMLIndexer) throws -> DMXMode {
        //解析属性
        let Name = element.element?.attribute(by: "Name")?.text ?? ""
        let Description = element.element?.attribute(by: "Description")?.text ?? ""
        let Geometry = element.element?.attribute(by: "Geometry")?.text ?? ""
        //解析包含的所有DMXChannels元素
        var tempDMXChanels:[DMXChanel] = []
        for DMXChanelXMLIndexer in element["DMXChannels"]["DMXChannel"].all {
            if let tempDMXChanel = try? DMXChanel.deserialize(DMXChanelXMLIndexer) {
                tempDMXChanels.append(tempDMXChanel)
            }
        }
        
        return DMXMode(Name: Name, Description: Description, Geometry: Geometry, DMXChanels: tempDMXChanels)
    }
}

//DMX通道
struct DMXChanel:XMLObjectDeserialization {
    
    /// 如果一个装置需要多个起始地址，则使用中断。
    let DMXBreak:String
    
    /// 当前DMX通道的相对地址从最高位到最低位； 值的分隔符是“,”； 特殊值：“None”——没有任何地址； 默认值：“无”； 每个 int 的大小：4 字节
    let Offset:String
    
    /// 链接到该 DMXChannel 默认激活的通道功能
    let InitialFunction:String
    
    /// 定义该 DMX 通道是否对高亮功能做出反应。 高亮值是高亮DMX通道中将输出的值。
    let Highlight:String
    
    /// DMX 通道和几何体之间的链接。 DMX 通道链接到与其逻辑和物理相关的几何体。
    let Geometry:String
    
    let LogicalChannels:[LogicalChannel]
    
    static func deserialize(_ element: XMLIndexer) throws -> DMXChanel {
        //解析属性
        let DMXBreak = element.element?.attribute(by: "DMXBreak")?.text ?? ""
        let Offset = element.element?.attribute(by: "Offset")?.text ?? ""
        let InitialFunction = element.element?.attribute(by: "InitialFunction")?.text ?? ""
        let Highlight = element.element?.attribute(by: "Highlight")?.text ?? ""
        let Geometry = element.element?.attribute(by: "Geometry")?.text ?? ""
        
        //解析包含的LogicalChannels元素
        let LogicalChannelsXMLIndexer = element.children
        var tempLogicalChannels:[LogicalChannel] = []
        for LogicalChannelXMLIndexer in LogicalChannelsXMLIndexer {
            if LogicalChannelXMLIndexer.element?.name == "LogicalChannel" {
                if let tempLogicalChannel = try? LogicalChannel.deserialize(LogicalChannelXMLIndexer) {
                    tempLogicalChannels.append(tempLogicalChannel)
                }
            }
        }
        
        return DMXChanel(DMXBreak: DMXBreak,
                         Offset: Offset,
                         InitialFunction: InitialFunction,
                         Highlight: Highlight,
                         Geometry: Geometry,
                         LogicalChannels: tempLogicalChannels)
    }
    
}

//逻辑通道 (灯具类型属性被分配给逻辑通道并定义逻辑通道的功能。 作为同一 DMX 通道子级的所有逻辑通道都是互斥的。 在DMX模式下，同一时间只有一个具有相同属性的逻辑通道可以引用相同的几何体)
struct LogicalChannel:XMLObjectDeserialization {
    
    /// 属性 Dimmer CTC 等
    let Attribute:String
    
    /// 如果启用捕捉，逻辑通道将不会在值之间淡出。 相反，它将直接跳转到新值。 值：“是”、“否”、“开”、“关”。 默认值：“否”
    let Snap:String
    
    /// 定义所有从属通道功能是否对控制系统定义的组控制做出反应。 值：“无”、“大”、“组”； 默认值：“无”。
    let Master:String
    
    /// black action 最小渐进时间。 MibFade 是为完整的 DMX 系列定义的。 默认值：0； 单位：秒
    let MibFade:String
    
    /// 下级通道功能的最小渐变时间可通过控制系统更改 DMX 值。 DMXChangeTimeLimit 是为完整的 DMX 范围定义的。 默认值：0； 单位：秒
    let DMXChangeTimeLimit:String
    
    let channelFunction:[ChannelFunction]
    
    static func deserialize(_ element: XMLIndexer) throws -> LogicalChannel {
        let Attribute = element.element?.attribute(by: "Attribute")?.text ?? ""
        let Snap = element.element?.attribute(by: "Snap")?.text ?? ""
        let Master = element.element?.attribute(by: "Master")?.text ?? ""
        let MibFade = element.element?.attribute(by: "MibFade")?.text ?? ""
        let DMXChangeTimeLimit = element.element?.attribute(by: "DMXChangeTimeLimit")?.text ?? ""
        
        //解析ChannelFunction children
        let ChannelFunctionXMLIndexer = element.children
        var ChannelFunctions:[ChannelFunction] = []
        //获取所有ChannelFunction下的ChannelSet
        for functionXMLIndexer in ChannelFunctionXMLIndexer {
            if functionXMLIndexer.element?.name == "ChannelFunction" {
                if let function = try? ChannelFunction.deserialize(functionXMLIndexer) {
                    ChannelFunctions.append(function)
                }
            }
        }
        
        return LogicalChannel(Attribute: Attribute,
                              Snap: Snap,
                              Master: Master,
                              MibFade: MibFade,
                              DMXChangeTimeLimit: DMXChangeTimeLimit,
                              channelFunction: ChannelFunctions)
    }
}

/// 灯具类型属性被分配给通道功能并定义其 DMX 范围的功能。 （XML 节点 <ChannelFunction>）。
struct ChannelFunction:XMLObjectDeserialization {
    
    /// 独特的名称； 默认值：属性名称和通道功能号。
    let Name:String
    
    /// 属性 Dimmer CTC 等
    let Attribute:String
    
    /// 制造商的原始属性名称； 默认值：空
    let OriginalAttribute:String
    
    /// 启动的DMX值； 最终 DMX 值计算为下一个通道功能的 DMXFrom - 1 或 DMX 通道的最大值。 默认值：“0/1”。
    let DMXFrom:String
    
    /// 控制系统激活时通道功能的默认 DMX 值。
    let Default:String
    
    /// 物理起始值； 默认值：0
    let PhysicalFrom:String
    
    /// 物理终值； 默认值：1
    let PhysicalTo:String
    
    /// 通道功能从最小值移动到最大值的时间（以秒为单位）； 默认值：0
    let RealFade:String
    
    /// 从停止加速到最大速度的时间（以秒为单位）； 默认值：0
    let RealAcceleration:String
    
//    /// 可选
//    let Wheel:String
//    let Emitter:String
//    let Filter:String
//    let ColorSpace:String
//    let Gamut:String
//    let ModeMaster:String
//    let ModeFrom:String
//    let ModeTo:String
//    let DMXProfile:String
//    let Min:String
//    let Max:String
//    let CustomName:String
    
    let ChannelSets:[ChannelSet]
    
    static func deserialize(_ element: XMLIndexer) throws -> ChannelFunction {
        let Name = element.element?.attribute(by: "Name")?.text ?? ""
        let Attribute = element.element?.attribute(by: "Attribute")?.text ?? ""
        let OriginalAttribute = element.element?.attribute(by: "OriginalAttribute")?.text ?? ""
        let DMXFrom = element.element?.attribute(by: "DMXFrom")?.text ?? ""
        let Default = element.element?.attribute(by: "Default")?.text ?? ""
        let PhysicalFrom = element.element?.attribute(by: "PhysicalFrom")?.text ?? ""
        let PhysicalTo = element.element?.attribute(by: "PhysicalTo")?.text ?? ""
        let RealFade = element.element?.attribute(by: "RealFade")?.text ?? ""
        let RealAcceleration = element.element?.attribute(by: "RealAcceleration")?.text ?? ""
        
        
        //解析ChannelSet children
        let ChannelSetsXMLIndexer = element["ChannelSet"].all
        // ChannelSet数组
        var ChannelSetsArr:[ChannelSet] = []
        //获取所有ChannelFunction下的ChannelSet
        for ChannelSetXMLIndexer in ChannelSetsXMLIndexer {
            if let set = try? ChannelSet.deserialize(ChannelSetXMLIndexer) {
                ChannelSetsArr.append(set)
            }
        }
        
        return ChannelFunction(Name: Name,
                               Attribute: Attribute,
                               OriginalAttribute: OriginalAttribute,
                               DMXFrom: DMXFrom,
                               Default: Default,
                               PhysicalFrom: PhysicalFrom,
                               PhysicalTo: PhysicalTo,
                               RealFade: RealFade,
                               RealAcceleration: RealAcceleration,
                               ChannelSets: ChannelSetsArr)
    }
}

//本节定义通道功能的通道集（XML节点）
struct ChannelSet:XMLObjectDeserialization {
    
    /// 通道集的名称。 默认值：空
    let Name:String
    
    /// 启动的DMX值； 最终 DMX 值计算为下一个通道功能的 DMXFrom - 1 或 DMX 通道的最大值。 默认值：“0/1”。
    let DMXFrom:String
    
    /// 物理起始值； 默认值：0
    let PhysicalFrom:String
    
    /// 物理终值； 默认值：1
    let PhysicalTo:String
    
    /// If the channel function has a link to a wheel, a corresponding slot index shall be specified. The wheel slot index results from the order of slots of the wheel which is linked in the channel function. The wheel slot index is normalized to 1. Size: 4 bytes
    let WheelSlotIndex:String
    
    static func deserialize(_ element: XMLIndexer) throws -> ChannelSet {
        let Name = element.element?.attribute(by: "Name")?.text ?? ""
        let DMXFrom = element.element?.attribute(by: "DMXFrom")?.text ?? ""
        let PhysicalFrom = element.element?.attribute(by: "PhysicalFrom")?.text ?? ""
        let PhysicalTo = element.element?.attribute(by: "PhysicalTo")?.text ?? ""
        let WheelSlotIndex = element.element?.attribute(by: "WheelSlotIndex")?.text ?? ""
        
        return ChannelSet(Name: Name,
                              DMXFrom: DMXFrom,
                              PhysicalFrom: PhysicalFrom,
                              PhysicalTo: PhysicalTo,
                              WheelSlotIndex: WheelSlotIndex)
    }
}

class SWXMLHashUsage {
    
    /// 利用第三方解析XML文件
    func parseXML() {
        let xmlFilePath = Bundle.main.path(forResource: "description", ofType: "xml")
        let xmlData = NSData(contentsOfFile: xmlFilePath!)
        let xmlStr = String(data: xmlData! as Data, encoding: .utf8)
        let xml = XMLHash.parse(xmlStr!)
        let FixtureTypeXMLIndexer = xml["GDTF"]["FixtureType"]
        if let fixtureType = try? FixtureType.deserialize(FixtureTypeXMLIndexer) {
            print("success")
        }
        else{
            print("fail")
        }
    }
    

    
    /// 解析GDTF xml文件
    /// - Parameter xmlStr: xml字符串
    /// - Returns: 解析后的对象
    func analizeGDTF(xmlStr:String)-> FixtureType? {
        let xml = XMLHash.parse(xmlStr)
        let FixtureTypeXMLIndexer = xml["GDTF"]["FixtureType"]
        if let fixtureType = try? FixtureType.deserialize(FixtureTypeXMLIndexer) {
            print("success")
            return fixtureType
        }
        else{
            print("fail")
            return nil
        }
    }
}
