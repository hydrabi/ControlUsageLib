//
//  UILable+AttributeText.swift
//  ControlUsageLib
//
//  Created by 毕志锋 on 2023/12/25.
//

import Foundation
import UIKit

extension UILabel {
    //图文合并
    func textAndImg() {
        let text = NSMutableAttributedString(string: "12345690")
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: "attributeString_demo")
        attachment.bounds = CGRect(x: 0, y: 0, width: 16, height: 16)
        let picAtt = NSAttributedString(attachment: attachment)
        
        let padding = NSTextAttachment()
        //Use a height of 0 and width of the padding you want
        padding.bounds = CGRect(x:0,y:0,width: 20, height: 0)
        let paddingAtt = NSAttributedString(attachment: padding)
        text.insert(paddingAtt, at: 1)
        //插入到原字符中
        text.insert(picAtt, at: 2)
        text.insert(paddingAtt, at: 3)
    }
}
