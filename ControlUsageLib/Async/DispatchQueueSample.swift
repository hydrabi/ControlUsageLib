//
//  DispatchQueueSample.swift
//  ControlUsageLib
//
//  Created by 毕志锋 on 2026/9/14.
//

import Foundation

/// DispatchQueue（GCD）常用用法示例。
///
/// DispatchQueue 管理的是“任务”，系统会为任务调度合适的线程。
/// 因此不要把“队列”等同于“线程”：串行队列保证任务逐个执行，
/// 但这些任务不一定永远运行在同一条物理线程上。
final class DispatchQueueSample {

    // MARK: - 1. 创建队列

    /// 串行队列：同一时刻只执行一个任务，并保持任务开始执行的顺序。
    private let serialQueue = DispatchQueue(label: "com.controlusagelib.serial")

    /// 并发队列：允许多个任务同时执行。
    ///
    /// QoS（Quality of Service）用于表达任务优先级：
    /// - userInteractive：与界面即时交互有关，任务应非常短。
    /// - userInitiated：用户主动发起并等待结果。
    /// - utility：下载、导入等有进度的耗时任务。
    /// - background：用户不需要立即感知的后台任务。
    private let concurrentQueue = DispatchQueue(
        label: "com.controlusagelib.concurrent",
        qos: .userInitiated,
        attributes: .concurrent
    )

    // MARK: - 2. async：异步提交任务

    /// async 提交任务后立即返回，不等待闭包执行结束。
    func asyncSample() {
        print("1. 提交任务前")

        serialQueue.async {
            // 该任务稍后由 GCD 调度执行。
            print("2. 执行异步任务")
        }

        // 通常先于异步任务输出，但实际线程调度时机不应作为业务逻辑依据。
        print("3. 提交任务后")
    }

    /// 串行队列按照任务入队顺序逐个执行。
    func serialQueueSample() {
        for index in 1...3 {
            serialQueue.async {
                // 输出顺序固定为 1、2、3。
                print("串行任务：\(index)")
            }
        }
    }

    /// 并发队列允许多个任务重叠执行，完成顺序不确定。
    func concurrentQueueSample() {
        for index in 1...3 {
            concurrentQueue.async {
                // 不能依赖这里的输出顺序。
                print("并发任务开始：\(index)")
                Thread.sleep(forTimeInterval: 0.1)
                print("并发任务结束：\(index)")
            }
        }
    }

    // MARK: - 3. sync：同步提交并取得返回值

    /// sync 会等待闭包执行完成，并将闭包的结果返回给调用者。
    func syncReturnValueSample() -> Int {
        let result: Int = serialQueue.sync {
            // 单表达式闭包可以省略 return，这个 100 就是闭包返回值。
            100
        }

        return result
    }

    /// sync 与 async 最重要的区别是调用者是否等待。
    func syncExecutionOrderSample() {
        print("1. sync 之前")

        serialQueue.sync {
            // 当前闭包结束前，sync 不会返回。
            print("2. sync 闭包内部")
        }

        print("3. sync 之后")
    }

    // MARK: - 4. 主队列与 UI 更新

    /// 主队列是串行队列，UIKit/AppKit 的界面更新应在主队列执行。
    func mainQueueSample() {
        concurrentQueue.async {
            // 在后台执行耗时计算，避免阻塞界面。
            let text = "后台计算结果"

            DispatchQueue.main.async {
                // 实际项目可在这里更新 UILabel、UITableView 等界面。
                print("\(text)，是否主线程：\(Thread.isMainThread)")
            }
        }
    }

    /// 如果当前已经位于主线程，直接执行；否则异步切换到主队列。
    ///
    /// 这种写法适合“允许异步更新”的场景。不要为了强制同步而对主队列
    /// 随意调用 sync，否则调用关系复杂时容易发生死锁。
    func executeOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    // MARK: - 5. 延迟执行

    /// asyncAfter 表示“不早于指定时间执行”，不是精确定时器。
    func asyncAfterSample() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // 系统繁忙时可能晚于 1 秒执行。
            print("至少延迟 1 秒后执行")
        }
    }

    /// wallDeadline 使用墙上时钟，适合与实际日期时间相关的调度。
    func wallDeadlineSample() {
        let deadline = DispatchWallTime.now() + .seconds(1)

        serialQueue.asyncAfter(wallDeadline: deadline) {
            print("按墙上时钟延迟执行")
        }
    }

    // MARK: - 6. Barrier：并发读、独占写

    /// 演示 barrier 的执行顺序。
    ///
    /// barrier 之前已提交的任务全部完成后，barrier 才会执行；
    /// barrier 执行期间没有其他任务并发执行；完成后才继续后续任务。
    func barrierSample() {
        concurrentQueue.async {
            print("读取任务 1")
        }

        concurrentQueue.async {
            print("读取任务 2")
        }

        concurrentQueue.async(flags: .barrier) {
            // 写操作独占这条自建并发队列。
            print("独占写入")
        }

        concurrentQueue.async {
            print("写入完成后的读取任务")
        }
    }

    // MARK: - 7. DispatchGroup：等待一组任务

    /// 使用 queue.async(group:) 管理一组普通同步任务。
    func groupAsyncSample(completion: @escaping () -> Void) {
        let group = DispatchGroup()

        for index in 1...3 {
            concurrentQueue.async(group: group) {
                // 队列会自动为该任务管理 Group 的 enter 和 leave。
                print("Group 任务完成：\(index)")
            }
        }

        group.notify(queue: .main) {
            // notify 不阻塞当前线程，所有任务完成后再异步执行。
            completion()
        }
    }

    /// 使用 enter/leave 管理自身还包含异步回调的任务。
    func groupEnterLeaveSample(completion: @escaping () -> Void) {
        let group = DispatchGroup()

        for index in 1...3 {
            group.enter()

            simulateAsyncRequest(index: index) {
                print("异步请求完成：\(index)")

                // 每次 enter 必须严格对应一次 leave，否则 notify 永远不会执行。
                group.leave()
            }
        }

        group.notify(queue: .main, execute: completion)
    }

    /// 模拟具有异步回调的网络请求。
    private func simulateAsyncRequest(index: Int, completion: @escaping () -> Void) {
        concurrentQueue.asyncAfter(deadline: .now() + 0.1) {
            print("请求结果：\(index)")
            completion()
        }
    }

    /// group.wait 会阻塞当前线程，直到任务完成或超时。
    ///
    /// 不要在主线程等待耗时任务，否则界面会卡住；多数业务应优先使用 notify。
    func groupWaitSample() {
        let group = DispatchGroup()

        concurrentQueue.async(group: group) {
            // queue.async(group:) 会自动登记并完成该 Group 任务。
            Thread.sleep(forTimeInterval: 0.1)
        }

        let result = group.wait(timeout: .now() + 1)

        switch result {
        case .success:
            print("Group 中的任务已全部完成")
        case .timedOut:
            print("等待 Group 超时")
        }
    }

    // MARK: - 8. DispatchSemaphore：限制并发数量

    /// value 为 2，表示最多允许两个任务同时进入受控区域。
    func semaphoreSample() {
        let semaphore = DispatchSemaphore(value: 2)
        let group = DispatchGroup()

        for index in 1...5 {
            group.enter()

            concurrentQueue.async {
                // 计数大于 0 时减 1 并继续；等于 0 时阻塞当前工作线程。
                semaphore.wait()

                // defer 保证任务退出时归还许可，避免其他任务永久等待。
                defer {
                    semaphore.signal()
                    group.leave()
                }

                print("受限任务开始：\(index)")
                Thread.sleep(forTimeInterval: 0.1)
                print("受限任务结束：\(index)")
            }
        }

        group.notify(queue: .main) {
            print("全部受限任务完成")
        }
    }

    // MARK: - 9. DispatchWorkItem：封装任务

    /// WorkItem 可以被提交、通知和标记取消。
    func workItemSample() {
        let workItem = DispatchWorkItem(qos: .utility) {
            // 一个可以保存并在稍后提交的工作单元。
            print("执行 DispatchWorkItem")
        }

        workItem.notify(queue: .main) {
            print("DispatchWorkItem 已结束")
        }

        concurrentQueue.async(execute: workItem)

        // cancel 只会设置取消标记，不保证已经运行的代码立即停止。
        // 长任务需要自行分段检查取消状态并主动结束。
        // workItem.cancel()
    }

    /// 等待 WorkItem 完成会阻塞当前线程，仅适用于确实需要同步结果的后台代码。
    func workItemWaitSample() {
        let workItem = DispatchWorkItem {
            Thread.sleep(forTimeInterval: 0.1)
            print("WorkItem 任务完成")
        }

        concurrentQueue.async(execute: workItem)
        workItem.wait()

        print("确认 WorkItem 完成后继续")
    }

    // MARK: - 10. concurrentPerform：并行循环

    /// 并行执行固定次数的同步计算。
    ///
    /// concurrentPerform 会阻塞调用线程，直到所有迭代完成，
    /// 因此不要直接在主线程处理大量数据。
    func concurrentPerformSample() {
        DispatchQueue.concurrentPerform(iterations: 5) { index in
            // 每次迭代的执行顺序不确定，应避免直接修改未受保护的共享变量。
            let square = index * index
            print("\(index) 的平方是 \(square)")
        }
    }

    // MARK: - 11. Target Queue：统一调度资源

    /// 多条队列可以指向同一个目标队列，用于统一 QoS 或限制最终并发度。
    func targetQueueSample() {
        let targetQueue = DispatchQueue(
            label: "com.controlusagelib.target",
            qos: .utility
        )

        let queueA = DispatchQueue(
            label: "com.controlusagelib.target.a",
            target: targetQueue
        )
        let queueB = DispatchQueue(
            label: "com.controlusagelib.target.b",
            target: targetQueue
        )

        // 因为目标队列是串行队列，A、B 最终不会同时执行。
        queueA.async {
            print("目标队列任务 A")
        }
        queueB.async {
            print("目标队列任务 B")
        }
    }

    // MARK: - 12. initiallyInactive：准备完成后统一启动

    /// initiallyInactive 队列在 activate 前不会执行已经提交的任务。
    func initiallyInactiveSample() {
        let queue = DispatchQueue(
            label: "com.controlusagelib.inactive",
            attributes: .initiallyInactive
        )

        queue.async {
            print("队列激活后执行")
        }

        // 队列只能激活一次，激活后不能恢复为 inactive。
        queue.activate()
    }

    // MARK: - 13. 常见死锁说明

    /// 以下代码仅用于说明风险，不能实际调用。
    private func deadlockExplanation() {
        // serialQueue.sync {
        //     serialQueue.sync {
        //         同一串行队列等待自己执行内部任务，会永久死锁。
        //     }
        // }

        // DispatchQueue.main.sync {
        //     如果这段代码本来就在主线程，主队列会等待自己，造成死锁。
        // }
    }
}

// MARK: - 14. 使用串行队列保护共享状态

/// 使用一条私有串行队列保护计数器。
///
/// 关键规则：对 value 的所有读写都必须经过 stateQueue；
/// 队列保护的是访问路径，而不是让 value 本身自动变成“线程安全属性”。
final class DispatchQueueSafeCounter {

    private let stateQueue = DispatchQueue(label: "com.controlusagelib.counter")
    private var value = 0

    /// 异步写入：调用后立即返回，修改稍后按入队顺序执行。
    func increment() {
        stateQueue.async {
            self.value += 1
        }
    }

    /// 同步读取共享值。
    func currentValue() -> Int {
        stateQueue.sync {
            // 1. 读取任务排在此前已经提交的任务之后。
            // 2. 串行队列保证读取时没有其他队列任务正在写 value。
            // 3. sync 等待闭包结束，并把闭包返回的 Int 交给调用者。
            // 单表达式闭包隐式 return，因此这里等价于 return value。
            value
        }
    }

    /// 将“读取、计算、写入”整体放入队列，避免复合操作发生数据竞争。
    func addAndGet(_ amount: Int) -> Int {
        stateQueue.sync {
            value += amount
            return value
        }
    }
}

// MARK: - 15. 使用 Barrier 实现线程安全缓存

/// 读多写少场景下，允许并发读取，并通过 barrier 独占写入。
final class DispatchQueueSafeCache<Key: Hashable, Value> {

    private let stateQueue = DispatchQueue(
        label: "com.controlusagelib.cache",
        attributes: .concurrent
    )
    private var storage: [Key: Value] = [:]

    /// 同步读取：允许多个读取任务同时执行。
    func value(forKey key: Key) -> Value? {
        stateQueue.sync {
            storage[key]
        }
    }

    /// 异步 barrier 写入：方法会立即返回，写入稍后独占执行。
    func setValue(_ value: Value, forKey key: Key) {
        stateQueue.async(flags: .barrier) {
            self.storage[key] = value
        }
    }

    /// 同步 barrier 写入：方法返回时可以确认写入已经完成。
    func setValueAndWait(_ value: Value, forKey key: Key) {
        stateQueue.sync(flags: .barrier) {
            storage[key] = value
        }
    }

    /// 同步 barrier 删除并返回旧值。
    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        stateQueue.sync(flags: .barrier) {
            storage.removeValue(forKey: key)
        }
    }
}
