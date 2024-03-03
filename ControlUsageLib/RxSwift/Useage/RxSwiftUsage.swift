//
//  RxSwiftUsage.swift
//  ControlUsageLib
//
//  Created by 毕志锋 on 2024/3/3.
//

import Foundation
import RxSwift
import RxCocoa

/// RxSwift
class RxSwiftUsage:NSObject {
    let disposeBag = DisposeBag()
    //最简单的使用方式 发送信号 订阅信号
    var subject:PublishSubject<Int> = PublishSubject()
    

    //MARK: - 基本使用方法
    /// 信号发送，信号订阅；最基本的使用方法
    func subjectSendAndReceiveSample() {
        subject.onNext(1)
        subject.subscribe(onNext:{ param in
            
        }).disposed(by: disposeBag)
    }
    
    /// 测试rxswift sentMessage方法的调用方法
    @objc dynamic func testMethod() {
        
    }
    
    func sentMessageSample() {
        //sentMessage 会在调用方法前发送值。
        self.rx.sentMessage(#selector(testMethod)).subscribe(onNext:{_ in }).disposed(by: disposeBag)
        //methodInvoked 会在调用方法之后发送值
        self.rx.methodInvoked(#selector(testMethod)).subscribe(onNext:{_ in }).disposed(by: disposeBag)
    }
}
