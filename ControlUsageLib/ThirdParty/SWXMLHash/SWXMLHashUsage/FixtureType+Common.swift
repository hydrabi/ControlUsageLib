//   FixtureType+Common.swift
//   ControlUsageLib
//
//   Created by Ted on 2024/4/18
//   


import Foundation

enum AUMutiModeType: CaseIterable {
    case bit8CCTHSI,
         bit16CCTHSI,
         bit8CCTRGBW,
         bit16CCTRGBW,
         bit8CCTRGB,
         bit16CCTRGB
         
    
    func getCompareArr() -> [String] {
        switch self {
        case .bit8CCTHSI:
            return [K_CHANNEL_HUE,K_CHANNEL_SAT]
        case .bit16CCTHSI:
            return [K_CHANNEL_HUE,K_CHANNEL_HUE,K_CHANNEL_SAT,K_CHANNEL_SAT]
        case .bit8CCTRGB:
            return [K_CHANNEL_R,K_CHANNEL_G,K_CHANNEL_B]
        case .bit16CCTRGB:
            return [K_CHANNEL_R,K_CHANNEL_R,K_CHANNEL_G,K_CHANNEL_G,K_CHANNEL_B,K_CHANNEL_B]
        case .bit8CCTRGBW:
            return [K_CHANNEL_R,K_CHANNEL_G,K_CHANNEL_B,K_CHANNEL_W]
        case .bit16CCTRGBW:
            return [K_CHANNEL_R,K_CHANNEL_R,K_CHANNEL_G,K_CHANNEL_G,K_CHANNEL_B,K_CHANNEL_B,K_CHANNEL_W,K_CHANNEL_W]
        }
    }
    
    func getStrValue() -> String {
        switch self {
        case .bit8CCTHSI,.bit16CCTHSI:
            return "CCT&HSI"
        case .bit8CCTRGB,.bit16CCTRGB:
            return "CCT&RGB"
        case .bit8CCTRGBW,.bit16CCTRGBW:
            return "CCT&RGBW"
        }
    }
    
    /// 通过AUPatternModel的modeChannel计算crossfade的拼接名
    /// - Parameters:
    ///   - modeChannel: 通道信息对象数组
    ///   - index: crossfade通道的索引
    /// - Returns: crossfade的拼接名 如"CCT&HSI"
    static func getPattMutiMode(modeChannel:[Any],index:Int) -> String {
        for type in Self.allCases {
            let compareArr = type.getCompareArr()
            if modeChannel.count > index + compareArr.count &&
                (modeChannel[index+1...index+compareArr.count].map {
                    ($0 as! AUChannelModel).channelName
                }.joined(separator: "")) == compareArr.joined(separator: ""){
                return type.getStrValue()
            }
        }
        return ""
    }
}

extension FixtureType {
    
    /// 根据ChannelFunction对象返回对应通道的最小值最大值
    /// - Parameters:
    ///   - channelName: 通道名称，如亮度，色温等用于区分
    ///   - tempChnannelFunction: ChannelFunction对象
    /// - Returns: 最小值、最大值
    func mapChannelMinAndMax(channelName:String,tempChannnelFunction:[ChannelFunction]) -> (min:String,max:String,channelPer:String) {
        switch channelName {
            //亮度
        case K_CHANNEL_INT:
            return ("0","100","%")
            //色温
        case K_CHANNEL_CCT:
            if let (physicalFrom,physicalTo) = getChannelFunctionFromAndTo(tempChannnelFunction: tempChannnelFunction) {
                return (physicalFrom,physicalTo,"K")
            }
            return ("2800","5600","K")
            //绿红
        case K_CHANNEL_GM:
            return ("-1","1","")
        case K_CHANNEL_R,
            K_CHANNEL_G,
            K_CHANNEL_B,
            K_CHANNEL_W,
            K_CHANNEL_Amber,
            K_CHANNEL_Cyan,
        K_CHANNEL_Lime:
            return ("0","255","")
        case K_CHANNEL_HUE:
            return ("0","255","")
        case K_CHANNEL_SAT:
            return ("0","100","")
        case K_CHANNEL_X:
            return ("0","0.85","")
        case K_CHANNEL_Y:
            return ("0","0.85","")
        case K_CHANNEL_FADE:
            return ("0","100","%")
        case K_CHANNEL_PAN:
            if let (physicalFrom,physicalTo) = getChannelFunctionFromAndTo(tempChannnelFunction: tempChannnelFunction) {
                return (physicalFrom,physicalTo,"")
            }
            return ("-270","270","")
        case K_CHANNEL_TILT:
            if let (physicalFrom,physicalTo) = getChannelFunctionFromAndTo(tempChannnelFunction: tempChannnelFunction) {
                return (physicalFrom,physicalTo,"")
            }
            return ("-126","126","")
        case K_CHANNEL_FOCUS:
            if let (physicalFrom,physicalTo) = getChannelFunctionFromAndTo(tempChannnelFunction: tempChannnelFunction) {
                return (physicalFrom,physicalTo,"")
            }
            return ("0","1","")
        case K_CHANNEL_ZOOM:
            if let (physicalFrom,physicalTo) = getChannelFunctionFromAndTo(tempChannnelFunction: tempChannnelFunction) {
                return (physicalFrom,physicalTo,"")
            }
            return ("55","4","")
        default:
            return ("0","255","")
        }
    }
    
    /// 计算某个通道的物理最小值最大值
    /// - Parameter tempChannnelFunction: 从DMX中解析出来的ChannelFunction对象数组
    /// - Returns: 通道的物理最小值最大值
    func getChannelFunctionFromAndTo(tempChannnelFunction:[ChannelFunction]) -> (String,String)? {
        //不能直接用第一个ChannelFunction的值，因为有可能第一个ChannelFunction的值是0
        for channelFunction in tempChannnelFunction {
            let physicalFromFloatValue = NSDecimalNumber(string: channelFunction.PhysicalFrom).floatValue
            if physicalFromFloatValue.isZero {
                continue
            }
            //如果channelSet数目大于2 取第一个和最后一个值作为最小最大值
            let physicalFrom = String(format: "%.0f", NSDecimalNumber(string: channelFunction.PhysicalFrom).floatValue)
            let physicalTo = String(format: "%.0f", NSDecimalNumber(string: channelFunction.PhysicalTo).floatValue)
            return (physicalFrom,physicalTo)
        }
        return nil
    }
    
    /// 将dmx中的ChannelFunction节点的name转换为可用的通道名称
    /// - Parameter name: ChannelFunction节点的name
    /// - Returns: 可用的通道名称
    func mapAvailableChannelFunctionName(_ name:String) -> String {
        
        //判断是否Focus(n) 正则Focus\d+
        if let tempRange = name.range(of: "Focus\\d+",options: .regularExpression,range: nil,locale: nil) {
            let range = NSRange(tempRange,in: name)
            if range.location == 0 && range.length == name.count {
                return K_CHANNEL_FOCUS
            }
        }
        
        switch name {
        case "Dimmer":
            return K_CHANNEL_INT
        case "CTC",                 //Arri,ASTURA,Creamsource,
            "CCT":                  //Fiilex
            return K_CHANNEL_CCT
        case "Tint",                //Arri,Creamsource
            "Green / Magenta",      //ASTURA
            "Green Adjust":         //Fiilex
            return K_CHANNEL_GM
        case "ColorAdd_R":
            return K_CHANNEL_R
        case "ColorAdd_G":
            return K_CHANNEL_G
        case "ColorAdd_B":
            return K_CHANNEL_B
        case "ColorAdd_W":
            return K_CHANNEL_W
        case "ColorAdd_A":
            return K_CHANNEL_Amber
        case "ColorAdd_C":
            return K_CHANNEL_Cyan
        case "ColorAdd_L":
            return K_CHANNEL_Lime
        case "HSB_Hue":
            return K_CHANNEL_HUE
        case "HSB_Saturation":
            return K_CHANNEL_SAT
        case "CIE_X":
            return K_CHANNEL_X
        case "CIE_Y":
            return K_CHANNEL_Y
        case "ColorMixMode",    //ASTURA 的 crossfade
            "Color XF",         //Arri 的 crossfade
            "White/Color XF":
            return K_CHANNEL_FADE
        case "Zoom":
            return K_CHANNEL_ZOOM
        case "Tilt":
            return K_CHANNEL_TILT
        case "Pan":
            return K_CHANNEL_PAN
        default:
            return name
        }
    }

    /// 判断该LogicalChannel对象包含的Channel是否是16位（通过判断属性DMXFrom中"/"后的数字判断，比如“0/1”,"0/2"，“/”后的数字“1”表示通道8位，“2”表示通道占16位）
    /// - Parameter tempLogicalChannel: LogicalChannel对象
    /// - Returns: true：16位 false 8位（超出的位数不考虑）
    func isChannel16Bit(tempLogicalChannel:LogicalChannel) -> Bool {
        if !tempLogicalChannel.channelFunction.isEmpty,let firstChannel = tempLogicalChannel.channelFunction.first {
            let DMXFromArr = firstChannel.DMXFrom.components(separatedBy: "/")
            if DMXFromArr.count > 1,let bitsNumStr = DMXFromArr.last {
                if let bitNum = Int(bitsNumStr),bitNum > 1 {
                    return true
                }
            }
        }
        return false
    }
    
    /// 把DMXFrom属性的值取"/"前一位的数值 比如“0/1”中的0
    /// - Parameter DMXFrom: DMXFrom属性的值
    /// - Returns: 值取"/"前一位的数值
    func getDMXFromValue(DMXFrom:String) -> Int {
        if let strValue = DMXFrom.components(separatedBy: "/").first,let intValue = Int(strValue) {
            return intValue
        }
        //因为文档上写默认是0（Default value: “0/1”.）
        return 0
    }
    
    /// 把LogicalChannel节点对象下的所有DMX关联值数据
    /// - Parameter tempLogicalChannel: LogicalChannel节点对象
    /// - Returns: DMX关联值数据 DMXChannelAvailable对象数组
    func getAllChannelFunctionDMXAttibute(tempLogicalChannel:LogicalChannel) -> [DMXChannelAvailable]{
        var DMXAvailableArr:[DMXChannelAvailable] = []
        //先遍历ChannelFunction，再遍历ChannelSet 有某些指令的通道会通过设置多个ChannelFunction来设置一些关联值 有些则是只有一个 这里做通用的做法
        for (_,channelFunction) in tempLogicalChannel.channelFunction.enumerated() {
            //先判断当前是否包含ChannelSets 有的话dmxEnd从ChannelSets里面获取
            if !channelFunction.ChannelSets.isEmpty {
                for tempChannelSet in channelFunction.ChannelSets {
                    DMXAvailableArr.append(DMXChannelAvailable(DMXFrom: tempChannelSet.DMXFrom,
                                                               Name: tempChannelSet.Name,
                                                               PhysicalFrom: "",
                                                               PhysicalTo: ""))
                }
            }
            //没有直接取ChannelFunction里面的属性
            else{
                DMXAvailableArr.append(DMXChannelAvailable(DMXFrom: channelFunction.DMXFrom,
                                                           Name: channelFunction.Name,
                                                           PhysicalFrom: channelFunction.PhysicalFrom,
                                                           PhysicalTo: channelFunction.PhysicalTo))
            }
        }
        return DMXAvailableArr
    }
    
}
