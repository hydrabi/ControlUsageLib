//
//  ObservableSample.swift
//  ControlUsageLib
//
//  Created by 毕志锋 on 2024/2/24.
//

import Foundation
import RxSwift
import RxCocoa

class Person {
    var name = "1"
}

class ObservableSample {
    
    let disposeBag = DisposeBag()
    
    let timer = Observable<Int>.interval(RxTimeInterval.seconds(1),
                                         scheduler: MainScheduler.instance)
    
    //PublishSubject 将对观察者发送订阅后产生的元素，而在订阅前发出的元素将不会发送给观察者。
//    1,next(A)
//    1,next(B)
//    1,next(C)
//    2,next(C)
//    1,next(D)
//    2,next(D)
    func publishSubjectSample() {
        let disposeBag = DisposeBag()
        let subject = PublishSubject<String>()
        subject.subscribe {
            print("1,\($0)")
        }.disposed(by: disposeBag)
        
        subject.onNext("A")
        subject.onNext("B")
        
        subject.subscribe {
            print("2,\($0)")
        }.disposed(by: disposeBag)
        
        subject.onNext("C")
        subject.onNext("D")
    }
    
    //观察者对 BehaviorSubject 进行订阅时，它会将源 Observable 中最新的元素发送出来（如果不存在最新的元素，就发出默认元素）。然后将随后产生的元素发送出来。
//Subscription: 1 Event: next(🔴)
//Subscription: 1 Event: next(🐶)
//Subscription: 1 Event: next(🐱)
//Subscription: 2 Event: next(🐱)
//Subscription: 1 Event: next(🅰️)
//Subscription: 2 Event: next(🅰️)
//Subscription: 1 Event: next(🅱️)
//Subscription: 2 Event: next(🅱️)
    func behaviorSubjectSample() {
        let disposeBag = DisposeBag()
        let subject = BehaviorSubject(value: "🔴")

        subject
          .subscribe { print("Subscription: 1 Event:", $0) }
          .disposed(by: disposeBag)

        subject.onNext("🐶")
        subject.onNext("🐱")

        subject
          .subscribe { print("Subscription: 2 Event:", $0) }
          .disposed(by: disposeBag)

        subject.onNext("🅰️")
        subject.onNext("🅱️") 
    }
    
//    ReplaySubject 将对观察者发送全部的元素，无论观察者是何时进行订阅的。
//
//    这里存在多个版本的 ReplaySubject，有的只会将最新的 n 个元素发送给观察者，有的只会将限制时间段内最新的元素发送给观察者。
//
//    如果把 ReplaySubject 当作观察者来使用，注意不要在多个线程调用 onNext, onError 或 onCompleted。这样会导致无序调用，将造成意想不到的结果。
    
    func replaySubjectSample() {
        let disposeBag = DisposeBag()
        let subject = ReplaySubject<String>.create(bufferSize: 1)

        subject
          .subscribe { print("Subscription: 1 Event:", $0) }
          .disposed(by: disposeBag)

        subject.onNext("🐶")
        subject.onNext("🐱")

        subject
          .subscribe { print("Subscription: 2 Event:", $0) }
          .disposed(by: disposeBag)

        subject.onNext("🅰️")
        subject.onNext("🅱️")
    }
    
    /// 倒计时
    func countdownSample() {
        //interval：每隔一段时间，发出一个索引数，将发出无数个
        //timer：在一段延时后，每隔一段时间产生一个元素
//        let timer = Observable<Int>.interval(RxTimeInterval.seconds(1),
//                                             scheduler: MainScheduler.instance)
        //倒计时60s
        let countDownSeconds:Int = 60
        //用于随时停止倒计时的subject
        let countDownStopped = BehaviorSubject(value: false)
        //剩余时间信号
        let leftTime = BehaviorSubject(value: countDownSeconds)
        
        timer.subscribe(onNext:{
                [weak self] event in guard let strongSelf = self else { return }
                print(event)
            }).disposed(by: disposeBag)

    }
}
