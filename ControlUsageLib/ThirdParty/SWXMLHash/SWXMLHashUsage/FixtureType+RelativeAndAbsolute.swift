//   FixtureType+RelativeAndAbsolute.swift
//   ControlUsageLib
//
//   Created by Ted on 2024/4/18
//   


import Foundation

extension FixtureType {
    
    /// 解析通道的相对值，绝对值，按逗号分隔
    /// - Parameters:
    ///   - tempLogicalChannel: dmx解析后LogicalChannel节点对象
    ///   - isFine: 是否16位 "0":八位 “1”：16位
    ///   - channelName: 通道类型
    ///   - minValue: 通过之前解析得到的通道范围最小值
    ///   - maxValue: 通过之前解析得到的通道范围最大值
    /// - Returns: 相对值，绝对值构成的元组
    func mapChannelRelativeAndAbsolute(tempLogicalChannel:LogicalChannel,
                                       isFine:String,
                                       channelName:String,
                                       minValue:String,
                                       maxValue:String) -> (relative:String,absolute:String) {
        //判断是否16位
        let is16Bit = isChannel16Bit(tempLogicalChannel: tempLogicalChannel)
        //dmx最大范围
        let dmxMax = is16Bit ? 65535 : 255
        //相对值范围数组
        var relativeStrArr:[String] = []
        //绝对值范围数组
        var absoluteStrArr:[String] = []
        //根据文档解析,范围值为该DMXFrom的下一个channelFunction的DMXFrom - 1 或者最大值比如255
        var dmxFrom = 0
        var dmxEnd = 0
        
        //把DMXFrom和Name合成的数据提取成为数组
        let DMXAvailableArr = getAllChannelFunctionDMXAttibute(tempLogicalChannel: tempLogicalChannel)
        for (index,tempDMXAvailable) in DMXAvailableArr.enumerated() {
            dmxFrom = getDMXFromValue(DMXFrom: tempDMXAvailable.DMXFrom)
            //判断有没有下一个 有的话dmxEnd就是下一个的DMXFrom - 1
            if index < DMXAvailableArr.count - 1 {
                dmxEnd = getDMXFromValue(DMXFrom: DMXAvailableArr[index + 1].DMXFrom) - 1
            }
            //没有下一个 说明到了最后 取最大值
            else {
                dmxEnd = dmxMax
            }
            
            //保存相对值
            let relativeStr = mapChannelRelative(channelName: channelName,
                                                 index: index,
                                                 tempDMXAvailableArr: DMXAvailableArr,
                                                 dmxFrom: dmxFrom,
                                                 dmxEnd: dmxEnd,
                                                 dmxMax: dmxMax,
                                                 minValue: minValue,
                                                 maxValue: maxValue)
            if !relativeStr.isEmpty {
                relativeStrArr.append(relativeStr)
            }
            
            //保存绝对值
            let absoluteStr = mapChannelAbsolute(channelName:channelName,
                                                 index:index,
                                                 tempDMXAvailableArr: DMXAvailableArr,
                                                 isFine: isFine,
                                                 is16Bit: is16Bit,
                                                 dmxFrom: dmxFrom,
                                                 dmxEnd: dmxEnd,
                                                 dmxMax: dmxMax)
            if !absoluteStr.isEmpty {
                absoluteStrArr.append(absoluteStr)
            }
        }

        return (relativeStrArr.joined(separator: ","),
                absoluteStrArr.joined(separator: ","))
    }
    
    /// 计算AUChannel对应某个通道位的绝对值 Sidus Link Pro 通道按每一位来插值而不是按通道 而且设备模式只填充了高位 所以这边要在高位那一位转为8位的数据（低位还是用解析的数据，避免以后需要）
    /// - Parameters:
    ///   - channelName: AUChannel对应的通道名称
    ///   - isFine: AUChannel判断是否16位的标志
    ///   - is16Bit: 接卸ChannnelFunction得到的是否16位的标志
    ///   - dmxFrom: dmxFrom值
    ///   - dmxEnd: ChannnelFunction或ChannelSet到下一个相关值的结束范围
    ///   - dmxMax: 位数的最大范围 8位：255 16位：65535
    /// - Returns: 通道位的绝对值其中一个范围
    func mapChannelAbsolute(channelName:String,
                            index:Int,
                            tempDMXAvailableArr:[DMXChannelAvailable],
                            isFine:String,
                            is16Bit:Bool,
                            dmxFrom:Int,
                            dmxEnd:Int,
                            dmxMax:Int) -> String {
        switch channelName {
        case K_CHANNEL_INT:
            //亮度不处理
            return ""
        case K_CHANNEL_GM,
            K_CHANNEL_CCT:
            //Sidus Link Pro 通道按每一位来差值而不是通道 而且设备模式没有只填充了高位 所以这边要在非isFine那一位转为8位的数据
            if isFine == "0" && is16Bit {
                //从16位按比例转为8位 narrowDMXFrom使用ceilf 是为了必须比上一个DMXFrom多1 否则会冲突
                let narrowDMXFrom = ceilf(Float(dmxFrom) / Float(dmxMax) * 255)
                // narrowDMXEnd使用floorf 是为了必须比下一个的DMXFrom少一 否则会冲突
                var narrowDMXEnd = floorf(Float(dmxEnd) / Float(dmxMax) * 255)
                //From和End原本就相同直接设置相同的转换值 避免两边计算后不相等
                if dmxFrom == dmxEnd {
                    narrowDMXEnd = narrowDMXFrom
                }
                //保存绝对值
                return "\(String(format: "%.0f", narrowDMXFrom))~\(String(format: "%.0f", narrowDMXEnd))"
            }
            else{
                //保存绝对值
                return "\(dmxFrom)~\(dmxEnd)"
            }
        default:
            return ""
        }
    }
    
    /// 计算AUChannel对应某个通道位的相对值 这个相对值由于无法通过直接解析字段解析（因为没有固定规范，可以写任意的字符串作为相对值），所以特殊处理
    /// - Parameters:
    ///   - channelName: AUChannel对应的通道名称
    ///   - index: 获取的ChannelFunction及其子节点ChannelSet里面所包含的Attribute和Name的集合的索引
    ///   - tempDMXAvailableArr: ChannelFunction及其子节点ChannelSet里面所包含的Attribute和Name所构成的结构体数组
    ///   - dmxFrom: 解析DMXFrom的值
    ///   - dmxEnd: 相对范围的结束值
    ///   - dmxMax: 8位：255 16位：65535
    /// - Returns: 通道位的相对值其中一个范围
    func mapChannelRelative(channelName:String,
                            index:Int,
                            tempDMXAvailableArr:[DMXChannelAvailable],
                            dmxFrom:Int,
                            dmxEnd:Int,
                            dmxMax:Int,
                            minValue:String,
                            maxValue:String) -> String {
        switch channelName {
        case K_CHANNEL_INT:
            //亮度不处理
            return ""
        case K_CHANNEL_GM:
            let (relateFrom,relateEnd) = getGMRelativeValue(index: index, tempAvailable: tempDMXAvailableArr[index])
            return "\(relateFrom)~\(relateEnd)"
        case K_CHANNEL_CCT:
            let (relateFrom,relateEnd) = getCCTRelativeValue(index: index,
                                                             tempDMXAvailableArr: tempDMXAvailableArr,
                                                             minValue:minValue,
                                                             maxValue: maxValue)
            if !relateFrom.isEmpty && !relateEnd.isEmpty {
                return "\(relateFrom)~\(relateEnd)"
            }
            else{
                return ""
            }
        default:
            return ""
        }
    }
    
    //亮度范围时0-100 计算相对值比例（其它厂家在该通道多半是开关的属性，所以其实不用特殊处理）
    func getIntRelativeValue(index:Int,tempAvailable:DMXChannelAvailable,
                             dmxFrom:Int,
                             dmxEnd:Int,
                             dmxMax:Int) -> (relativeFrom:Int,relativeEnd:Int) {
        let relateFrom = Int(ceilf(Float(dmxFrom) / Float(dmxMax) * Float(100)))
        var relateEnd = Int(floorf(Float(dmxEnd) / Float(dmxMax) * Float(100)))
        //From和End原本就相同直接设置相同的转换值 避免两边计算后不相等
        if dmxFrom == dmxEnd {
            relateEnd = relateFrom
        }
        return (relateFrom,relateEnd)
    }

}

//CCT相关
extension FixtureType {
    //色温相对值只能靠判断name是否包含数值或者特定字段
    func getCCTRelativeValue(index:Int,
                             tempDMXAvailableArr:[DMXChannelAvailable],
                             minValue:String,
                             maxValue:String) -> (relativeFrom:String,relativeEnd:String) {
        switch Manufacturer {
        case K_MANUFACTURER_Arri,
            K_MANUFACTURER_Creamsource, //Creamsource的解析其实跟Arri几乎一样 只不过ChannelSet特别多
            K_MANUFACTURER_Fiilex:      //Fiilex的解析其实跟Arri几乎一样 GEL模式有些区别
            return getArriCCTRelativeValue(index:index,
                                           tempDMXAvailableArr: tempDMXAvailableArr,
                                           minValue:minValue,
                                           maxValue:maxValue)
        case K_MANUFACTURER_Astera_LED_Technology:
            return getASTERACCTRelativeValue(index: index,
                                             tempDMXAvailableArr: tempDMXAvailableArr,
                                             minValue: minValue,
                                             maxValue: maxValue)
        default:
            return ("","")
        }
    }
    
    func getArriCCTRelativeValue(index:Int,
                                 tempDMXAvailableArr:[DMXChannelAvailable],
                                 minValue:String,
                                 maxValue:String) -> (relativeFrom:String,relativeEnd:String) {
        let DMXAvailable = tempDMXAvailableArr[index]
        //取name属性的值
        let CCTNameStr = DMXAvailable.Name.replacingOccurrences(of: "k", with: "")
        //范围的最大值
        var nextCCTNameStr = maxValue
        if tempDMXAvailableArr.count > index + 1 {
            nextCCTNameStr = tempDMXAvailableArr[index + 1].Name.replacingOccurrences(of: "k", with: "")
        }
        var lastCCTNameStr = minValue
        if index != 0 {
            lastCCTNameStr = tempDMXAvailableArr[index - 1].Name.replacingOccurrences(of: "k", with: "")
        }
        
        //如果ChannelFunction或者ChannelSet的范围起始值为空 比如Name为空 则以上一个值+10k为起始，取下一个的值减10k位结束
        //一般不存在前后两个值都为空值，如果是，此字段返回空，不处理
        if CCTNameStr.isEmpty,let lastCCTInt = Int(lastCCTNameStr),let nextCCTInt = Int(nextCCTNameStr) {
            return ("\(lastCCTInt + 10)","\(nextCCTInt - 10)")
        }
        
        //如果下一个值为空值，则说明ChannelFunction或者ChannelSet是一个单一的值，并不是范围
        if nextCCTNameStr.isEmpty, let _ = Int(CCTNameStr){
            return (CCTNameStr,CCTNameStr)
        }
        
        //如果ChannelFunction或者ChannelSet的范围起始值带有色温值 没有下一个值（或者下一个值是范围最大值）则说明ChannelFunction或者ChannelSet是一个单一的值（最大值），并不是范围
        if nextCCTNameStr == CCTNameStr {
            return (CCTNameStr,CCTNameStr)
        }
        
        //Arri暂时没发现有连续两个ChannelSet都包含Name的 不过Fiilex有，GEL模式中 0-99:3200K 100-255:6500K
        if let CCTInt = Int(CCTNameStr),let _ = Int(nextCCTNameStr) {
            return ("\(CCTInt)","\(CCTInt)")
        }
        
        return ("","")
    }
    
    func getASTERACCTRelativeValue(index:Int,
                                 tempDMXAvailableArr:[DMXChannelAvailable],
                                 minValue:String,
                                 maxValue:String) -> (relativeFrom:String,relativeEnd:String) {
        let DMXAvailable = tempDMXAvailableArr[index]
        
        //ASTERA 的色温只有两种情况 一种是只有一个ChannelFunction，这种可以直接范围色温最小到最大值
        if tempDMXAvailableArr.count == 1 && DMXAvailable.Name == "CTC 1" {
            return (minValue,maxValue)
        }
        
        //另一种是有两个ChannelFunction 0-4是无效 5-255是有效
        if DMXAvailable.Name == "No effect" {
            return ("0","0")
        }
        
        if DMXAvailable.Name == "CTC 2" {
            return (minValue,maxValue)
        }

        return ("","")
    }
}

//GM相关
extension FixtureType {
    
    func getGMRelativeValue(index:Int,tempAvailable:DMXChannelAvailable) -> (relativeFrom:String,relativeEnd:String) {
        switch Manufacturer {
        case K_MANUFACTURER_Arri:
            return getArriGMRelativeValue(index: index, tempAvailable:tempAvailable)
        case K_MANUFACTURER_Astera_LED_Technology:
            return getAsteraGMRelativeValue(index: index, tempAvailable: tempAvailable)
        case K_MANUFACTURER_Creamsource:
            return getCreamsourceGMRelativeValue(index: index, tempAvailable: tempAvailable)
        case K_MANUFACTURER_Fiilex:
            return getFiilexGMRelativeValue(index: index, tempAvailable: tempAvailable)
        default:
            return ("0","0")
        }
    }
    
    func getArriGMRelativeValue(index:Int,tempAvailable:DMXChannelAvailable) -> (relativeFrom:String,relativeEnd:String) {
        if (tempAvailable.Name == "No Effect" || index == 0) {
            return ("0","0")
        }
        else if (tempAvailable.Name == "Full Minus G" || index == 1) {
            return ("-1","-1")
        }
        else if (tempAvailable.Name == "99% >> 1% Minus G" || index == 2) {
            return ("-0.99","-0.01")
        }
        else if (tempAvailable.Name == "Neutral" || index == 3) {
            return ("0","0")
        }
        else if (tempAvailable.Name == "1% >> 99% Plus G" || index == 4) {
            return ("0.01","0.99")
        }
        else if (tempAvailable.Name == "Full Plus G" || index == 5) {
            return ("1","1")
        }
        else {
            return ("1","1")
        }
    }
    
    func getAsteraGMRelativeValue(index:Int,tempAvailable:DMXChannelAvailable) -> (relativeFrom:String,relativeEnd:String) {
        if (tempAvailable.Name == "No Effect" || index == 0) {
            return ("0","0")
        }
        else if (tempAvailable.Name == "Magenta" || index == 1) {
            return ("-1","-1")
        }
        else if (tempAvailable.Name == "" || index == 2) {
            return ("-0.99","-0.01")
        }
        else if (tempAvailable.Name == "No shift" || index == 3) {
            return ("0","0")
        }
        else if (tempAvailable.Name == "" || index == 4) {
            return ("0.01","0.99")
        }
        else if (tempAvailable.Name == "Green" || index == 5) {
            return ("1","1")
        }
        else {
            return ("1","1")
        }
    }
    
    func getCreamsourceGMRelativeValue(index:Int,tempAvailable:DMXChannelAvailable) -> (relativeFrom:String,relativeEnd:String) {
        if (tempAvailable.Name == "No Value" || index == 0) {
            return ("0","0")
        }
        else if (tempAvailable.Name == "-100 Green" || index == 1) {
            return ("-1","-1")
        }
        else if (tempAvailable.Name == "-100 to 1 Green" || index == 2) {
            return ("-1","-0.01")
        }
        else if (tempAvailable.Name == "-1 Green" || index == 3) {
            return ("-0.01","-0.01")
        }
        else if (tempAvailable.Name == "Neutral" || index == 4) {
            return ("0","0")
        }
        else if (tempAvailable.Name == "+1 Green" || index == 5) {
            return ("0.01","0.01")
        }
        else if (tempAvailable.Name == "+1 to +100 Green" || index == 6) {
            return ("0.01","1")
        }
        else if (tempAvailable.Name == "+ 100 Green" || index == 7) {
            return ("1","1")
        }
        else {
            return ("1","1")
        }
    }
    
    func getFiilexGMRelativeValue(index:Int,tempAvailable:DMXChannelAvailable) -> (relativeFrom:String,relativeEnd:String) {
        if (tempAvailable.Name == "Green Adjust" || index == 0) {
            return ("-1","-0.01")
        }
        else if (tempAvailable.Name == "Neutral" || index == 1) {
            return ("0","0")
        }
        else if (tempAvailable.Name == "Magenta to Green Adjust" || index == 2) {
            return ("0.01","1")
        }
        else {
            return ("1","1")
        }
    }
}
