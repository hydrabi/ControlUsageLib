//
//  ViewController.swift
//  ControlUsageLib
//
//  Created by 毕志锋 on 2023/12/17.
//

import UIKit
import SnapKit

extension Array{
    
    /// 去除重复元素
    func uniq<E: Equatable>(_ filter: (Element) -> E) -> [Element] {
        var result = [Element]()
        for value in self {
            let key = filter(value)
            if !result.map({filter($0)}).contains(key) {
                result.append(value)
            }
        }
        return result
    }
    
    /// 获取元素位置 返回小余0没找到
    func au_objectIndex<E: Equatable>(_ member: E) -> Int {
        for (i,value) in self.enumerated() {
            if member == value as! E {
                return i
            }
        }
        return -1
    }
}

extension UIView{
    
    var x:CGFloat {
        return self.frame.origin.x
    }
    
    var y:CGFloat{
        return self.frame.origin.y
    }
    
    var w:CGFloat{
        return self.frame.size.width
    }
    
    var h:CGFloat{
        return self.frame.size.height
    }
}

func RGB(r: UInt, g: UInt, b: UInt) -> UIColor {
    let color = UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1)
    return color
}

func RGBA(r: UInt, g: UInt, b: UInt, a: CGFloat) -> UIColor {
    let color = UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: a)
    return color
}

class temp {
    var ary = [1,2]
}

class ViewController: UIViewController {

    var combind:CombindLearn? = nil
    
    var fetch:FetchDemo? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Do any additional setup after loading the view.

//        combind = CombindLearn()
//        combind?.retrySample()
        
        fetch = FetchDemo()
        fetch?.startFetchAllData()
        
    }


}

