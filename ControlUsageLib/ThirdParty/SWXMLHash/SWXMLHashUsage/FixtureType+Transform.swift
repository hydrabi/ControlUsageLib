//   FixtureType+Transform.swift
//   ControlUsageLib
//
//   Created by Ted on 2024/4/18
//   


import Foundation

extension FixtureType {
    func transfromFixtureModel() -> AUFixtureModel {
        let model = AUFixtureModel()
        //制造商名称 如：Arri
        model.facturerName = Manufacturer
        //型号名称 如：L5C
        model.model = Name
        //默认设备名称
        model.defaultName = LongName
        //默认支持dmx
        model.supDMX = "1"
        
        //解析RDM相关字段
        if !FTRDMs.isEmpty {
            //Art-NET 制造商
            model.ESTAMANID = FTRDMs.first!.ManufacturerID
            //16进制字符串转换为整形
            if let hexInt = Int(FTRDMs.first!.DeviceModelID.dropFirst(2),radix: 16) {
                let hexString = String(format: "0x%04X", hexInt)
                //Art-NET 型号UID
                model.ESTADEVICEID = hexString
            }
            else{
                model.ESTADEVICEID = FTRDMs.first!.DeviceModelID
            }
            //有RDM 节点的设置支持RDM
            model.supRDM = "1"
        }
        
        //解析ArtNet相关字段
        if !GDTFArtNets.isEmpty {
            model.supArtNet = "1"
        }
        
        // 解析sACNs相关字段
        if !GDTFsACNs.isEmpty {
            model.supSACN = "1"
        }
        //模式数组
        model.modeAry = transfomrPatternModel()
        return model
    }
    
    /// 将dmx对象转换为模式对象数组
    /// - Returns: 模式对象数组
    func transfomrPatternModel() -> [Any] {
        var tempModeArray = [Any]()
        //解析DMXMode相关字段
        for (index,tempDMXMode) in DMXModes.enumerated() {
            //单个模式对象
            let patternModel = AUPatternModel()
            //赋值modeID 两位 不足补0
            patternModel.modeID = String(format: "%2d", index)
            //名称可以直接赋值
            patternModel.modeName = tempDMXMode.Name
            //mutiMode 判断是否包含xf通道，有的话使用CCT&RGB （色温&颜色）设值
            
            //functionType 根据获取模式后再计算
            //存放通道的数组
            patternModel.modeChannel = transfromChannelModel(tempDMXMode: tempDMXMode)
            //判断是否包含混合通道
            let crossfadeArr = patternModel.modeChannel.filter { mode in
                let channelModel = mode as! AUChannelModel
                return channelModel.channelName == K_CHANNEL_FADE
            }
            
            if crossfadeArr.isEmpty {
                //supportChange 根据channel中是否包含xf通道设值，1支持 0不支持
                patternModel.supportChange = "0"
                //supChannelNum 支持切换的通道地址
                patternModel.supChannelNum = "0"
            }
            else{
                //supportChange 根据channel中是否包含xf通道设值，1支持 0不支持
                patternModel.supportChange = "1"
                let index = (patternModel.modeChannel as NSArray).index(of: crossfadeArr[0])
                //supChannelNum 支持切换的通道地址（从1开始，所以设值时为index加1）
                patternModel.supChannelNum = (index == NSNotFound ? "0" : "\(index + 1)")
                //16位的时候，有可能是后一位
                let finalIndex = (patternModel.modeChannel as NSArray).index(of: crossfadeArr[crossfadeArr.count - 1])
                //判断mutiMode的结果
                if index != NSNotFound {
                    patternModel.mutiMode = AUMutiModeType.getPattMutiMode(modeChannel: patternModel.modeChannel, index: finalIndex)
                }
            }
            
            tempModeArray.append(patternModel)
        }
        return tempModeArray
    }
    
    /// 讲dmx对象转换为通道对象数组
    /// - Parameter tempDMXMode: dmx解析到的模式对象
    /// - Returns: 通道对象数组
    func transfromChannelModel(tempDMXMode:DMXMode) -> [Any] {
        //保存所有通道的数组
        var channelArr = [Any]()
        //遍历通道
        for (_,tempDMXChannel) in tempDMXMode.DMXChanels.enumerated() {
            //根据单个DMXChanel对象生成AUChannelModel对象数组
            let tempChannelArr = transformSingleChannelModel(tempDMXChannel: tempDMXChannel)
            if !tempChannelArr.isEmpty {
                channelArr.append(contentsOf: tempChannelArr)
            }
        }
        
        return channelArr
    }
    
    /// 根据单个DMXChanel对象生成AUChannelModel对象数组（数组数量根据通道位数变化，8位返回一个，16位返回两个）
    /// - Parameter tempDMXChannel: GDTF解析生成的DMXChanel对象
    /// - Returns: AUChannelModel对象数组
    func transformSingleChannelModel(tempDMXChannel:DMXChanel) -> [AUChannelModel] {
        //保存所有通道的数组
        var tempChannelArr = [AUChannelModel]()
        //通过offset属性判断每个通道的位数
        let offsetArr = tempDMXChannel.Offset.components(separatedBy: ",")
        //是否需要创建16位的通道
//        let shouldCreate16BitChannel = offsetArr.count == 2 ? true : false
        //超过16位的，比如24位，32位的不处理，视作不合法解析。虽然文档介绍最多可到32位，但实际上搜集到的gdtf数据并没有指令超过16位
        //填空的 即虚拟通道
        if offsetArr.count > 2 || offsetArr.isEmpty {
            return tempChannelArr
        }
        
        //解析logicalChannel
        if !tempDMXChannel.LogicalChannels.isEmpty {
            let tempLogicalChannel = tempDMXChannel.LogicalChannels[0]
            //解析ChannelFunction
            if !tempLogicalChannel.channelFunction.isEmpty {
                let tempChannelFunction = tempLogicalChannel.channelFunction[0]
                for (offsetIndex,offset) in offsetArr.enumerated() {
                    //单个通道对象
                    let channelModel = AUChannelModel()
                    //名称使用ChannelFunction的Attribute属性映射
                    channelModel.channelName = mapAvailableChannelFunctionName(tempChannelFunction.Attribute)
                    //通道号直接使用offset中用逗号间隔开的数字 如"1,2"
                    channelModel.channelNum = offset
                    //获取最小、最大、后缀
                    let (min,max,per) = mapChannelMinAndMax(channelName: channelModel.channelName, tempChannnelFunction: tempLogicalChannel.channelFunction)
                    channelModel.minValue = min
                    channelModel.maxValue = max
                    channelModel.channelPer = per
                    //offsetArr后一位的isFine设置为1
                    channelModel.isFine = (offsetArr.count > 1 && offsetIndex == offsetArr.count - 1) ? "1" : "0"
                    let (relative,absolute) = mapChannelRelativeAndAbsolute(tempLogicalChannel: tempLogicalChannel,
                                                                            isFine: channelModel.isFine,
                                                                            channelName: channelModel.channelName,
                                                                            minValue: channelModel.minValue,
                                                                            maxValue: channelModel.maxValue)
                    
                    channelModel.relative = relative
                    channelModel.absolute = absolute
                    tempChannelArr.append(channelModel)
                }
            }
        }
    
        return tempChannelArr
    }
}
