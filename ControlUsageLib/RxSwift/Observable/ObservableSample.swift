//
//  ObservableSample.swift
//  ControlUsageLib
//
//  Created by 毕志锋 on 2024/2/24.
//

import Foundation
import RxSwift
import RxCocoa
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
    
//    RxRelay 既是 可监听序列 也是 观察者。
//
//    他和 Subjects 相似，唯一的区别是不会接受 onError 或 onCompleted 这样的终止事件。
//
//    在将非 Rx 样式的 API 转化为 Rx 样式时，Subjects 是非常好用的。不过一旦 Subjects 接收到了终止事件 onError 或 onCompleted。他就无法继续工作了，也不会转发后续任何事件。有些时候这是合理的，但在多数场景中这并不符合我们的预期。
//
//    在这些场景中一个更严谨的做法就是，创造一种特殊的 Subjects，这种 Subjects 不会接受终止事件。有了他，我们将 API 转化为 Rx 样式时，就不必担心一个意外的终止事件，导致后续事件转发失效。
//
//    我们将这种特殊的 Subjects 称作 RxRelay：
    //PublishRelay 就是 PublishSubject 去掉终止事件 onError 或 onCompleted。
    func publishRelaySample() {
        let relay = PublishRelay<String>()
        relay.subscribe {
            print($0)
        }.disposed(by: disposeBag)
        
        relay.accept("🐶")
        relay.accept("🐱")
    }
    
//    ReplayRelay 就是 ReplaySubject 去掉终止事件 onError 或 onCompleted。
//    BehaviorRelay 就是 BehaviorSubject 去掉终止事件 onError 或 onCompleted。
    
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
        //倒计时60s
        let countDownSeconds:Int = 60
        
        timer
            .take(countDownSeconds) //执行60次
            .map({
                //将倒计时时间从0->60变为60->0
                return countDownSeconds - $0
            })
            .subscribe(onNext:{
                [weak self] event in guard let strongSelf = self else { return }
                print(event)
            }).disposed(by: disposeBag)
    }
}
