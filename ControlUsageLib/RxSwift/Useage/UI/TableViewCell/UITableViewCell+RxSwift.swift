//
//  UITableViewCell+RxSwift.swift
//  ControlUsageLib
//
//  Created by 毕志锋 on 2024/3/3.
//

import Foundation
import RxSwift
import RxCocoa

//添加cell按钮点击等方法的重用
extension Reactive where Base:UITableViewCell {
    public var reuseBag:DisposeBag {
        //主线程中运行
        MainScheduler.ensureExecutingOnScheduler()
        
        var prepareFroReuseBag:Int8 = 0
        
        //动态获取属性bag
        if let bag = objc_getAssociatedObject(base, &prepareFroReuseBag) as? DisposeBag {
            return bag
        }
        
        let bag = DisposeBag()
        //动态添加属性bag
        objc_setAssociatedObject(base,
                                 &prepareFroReuseBag,
                                 bag,
                                 objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        
        //当cell重用
        _ = sentMessage(#selector(Base.prepareForReuse))
            .subscribe(onNext:{ [weak base] _ in
                let newBag = DisposeBag()
                guard let base = base else {return}
                objc_setAssociatedObject(base,
                                         &prepareFroReuseBag,
                                         newBag,
                                         objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            })
        
        return bag
    }
}
