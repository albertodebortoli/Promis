//
//  Promis.swift
//  Promis
//
//  Created by Alberto De Bortoli on 14/10/2017.
//  Copyright © 2017 Alberto De Bortoli. All rights reserved.
//

import Foundation

enum PromisError: Error {
    case futureContinuationAlreadySet
    case promiseDeallocatedBeforeBeingResolved
}

public enum FutureState<FutureType> {
    case unresolved
    case result(FutureType)
    case error(Error)
    case cancelled
    
    func getResult() -> FutureType? {
        switch self {
        case .result(let res): return res
        default: return nil
        }
    }
    
    func getError() -> Error? {
        switch self {
        case .error(let err): return err
        default: return nil
        }
    }
    
    func isCancelled() -> Bool {
        switch self {
        case .cancelled: return true
        default: return false
        }
    }
}

func ==<FutureType>(lhs: FutureState<FutureType>, rhs: FutureState<FutureType>) -> Bool {
    var equal: Bool = false
    switch (lhs, rhs) {
    case (.unresolved, .unresolved):
        equal = true
    case (.error, .error):
        equal = true
    case (.result, .result):
        equal = true
    case (.cancelled, .cancelled):
        equal = true
    default:
        break
    }
    return equal
}

func !=<FutureType>(lhs: FutureState<FutureType>, rhs: FutureState<FutureType>) -> Bool {
    return !(lhs == rhs)
}

public class Future<FutureType>: NSObject {
    
    let cv: NSCondition
    var continuation: ((Future) -> Void)?
    var state: FutureState<FutureType> = .unresolved
    
    public override init() {
        self.cv = NSCondition()
        super.init()
    }
    
    public override var description: String {
        return "<Future: state \(stateString())>"
    }
    
    // MARK: Creation
    
    public class func futureWithResult(_ result: FutureType) -> Future<FutureType> {
        let promise = Promise<FutureType>()
        promise.setResult(result)
        return promise.future
    }
    
    public class func futureWithError(_ error: Error) -> Future<FutureType> {
        let promise = Promise<FutureType>()
        promise.setError(error)
        return promise.future
    }
    
    public class func cancelledFuture() -> Future<FutureType> {
        let promise = Promise<FutureType>()
        promise.setCancelled()
        return promise.future
    }
    
    public class func futureWithResolutionOfFuture(_ future: Future<FutureType>) -> Future<FutureType> {
        switch future.state {
        case .result(let value):
            return futureWithResult(value)
        case .error(let err):
            return futureWithError(err)
        default:
            return cancelledFuture()
        }
    }
    
    // MARK: Resolution
    
    public var result: FutureType? {
        get {
            wait()
            return state.getResult()
        }
    }
    
    public var error: Error? {
        get {
            wait()
            return state.getError()
        }
    }
    
    public var isCancelled: Bool {
        get {
            return state.isCancelled()
        }
    }
    
    // MARK: State checks
    
    public func isResolved() -> Bool {
        cv.lock()
        let retVal = state != FutureState<FutureType>.unresolved
        cv.unlock()
        return retVal
    }
    
    public func hasResult() -> Bool {
        cv.lock()
        let retVal = (state.getResult() != nil)
        cv.unlock()
        return retVal
    }
    
    public func hasError() -> Bool {
        cv.lock()
        let retVal = (state.getError() != nil)
        cv.unlock()
        return retVal
    }
    
    // MARK: Waiting for resolution
    
    public func wait() {
        cv.lock()
        while (state == .unresolved) {
            cv.wait()
        }
        cv.unlock()
    }
    
    public func waitUntilDate(_ timeout: Date) -> Bool {
        cv.lock()
        var timeoutExpired = false
        while (state == .unresolved && !timeoutExpired) {
            timeoutExpired = !cv.wait(until: timeout)
        }
        cv.unlock()
        return !timeoutExpired
    }
    
    // MARK: Chaining
    
    public func continues(queue: DispatchQueue? = nil, block: @escaping (Future<FutureType>) -> Void) {
        // rather than making all the chaining APIs 
        // if a continuation has already been set, a crash is desired
        try! setContinuation { future in
            if let queue = queue {
                queue.async {
                    block(future)
                }
            } else {
                block(future)
            }
        }
    }
    
    @discardableResult
    public func continueWithTask<NextFutureType>(queue: DispatchQueue? = nil, task: @escaping (Future) -> Future<NextFutureType>) -> Future<NextFutureType> {
        let promise = Promise<NextFutureType>()
        continues(queue: queue) { future in
            let f2 = task(future)
            f2.continues { fut2 in
                promise.setResolutionOfFuture(fut2)
            }
        }
        return promise.future
    }
    
    @discardableResult
    public func continueWithResult<NextFutureType>(queue: DispatchQueue? = nil, resultTask: @escaping (FutureType) -> Future<NextFutureType>) -> Future<NextFutureType> {
        let promise = Promise<NextFutureType>()
        continues { future in
            switch self.state {
            case .result(let val):
                let execution = {
                    let f2 = resultTask(val)
                    f2.continues { fut2 in
                        promise.setResolutionOfFuture(fut2)
                    }
                }
                if let queue = queue {
                    queue.async {
                        execution()
                    }
                } else {
                    execution()
                }
            default:
                promise.setResolutionOfFutureNotResolvedWithResult(future)
            }
        }
        return promise.future
    }
    
    @discardableResult
    public func continueWithError(queue: DispatchQueue? = nil, resultTask: @escaping (Error) -> Void) -> Future {
        let promise = Promise<FutureType>()
        continues { future in
            switch self.state {
            case .error(let err):
                let execution = {
                    resultTask(err)
                    promise.setResolutionOfFuture(future)
                }
                if let queue = queue {
                    queue.async {
                        execution()
                    }
                } else {
                    execution()
                }
            default:
                promise.setResolutionOfFuture(future)
            }
        }
        return promise.future
    }
    
    @discardableResult
    public class func whenAll(_ futures: [Future]) -> Future<[Future]> {
        let promise = Promise<[Future]>()
        let results = futures
        var counter = Int32(results.count)
        for element in futures {
            element.continues { _ in
                if (OSAtomicDecrement32(&counter) == 0) {
                    promise.setResult(results)
                }
            }
        }
        return promise.future
    }
    
    // MARK: State setting (Private)
    
    fileprivate func setResult(_ result: FutureType) {
        cv.lock()
        assert(state == .unresolved, "Cannot set result. Future already resolved")
        
        state = .result(result)
        let continuation = self.continuation
        self.continuation = nil
        
        cv.signal()
        cv.unlock()
        
        if let cont = continuation {
            cont(self)
        }
    }
    
    fileprivate func setError(_ error: Error) {
        cv.lock()
        assert(state == .unresolved, "Cannot set error. Future already resolved")
        
        state = .error(error)
        let continuation = self.continuation
        self.continuation = nil
        
        cv.signal()
        cv.unlock()
        
        if let cont = continuation {
            cont(self)
        }
    }
    
    fileprivate func cancel() {
        cv.lock()
        assert(state == .unresolved, "Cannot cancel. Future already resolved")
        
        state = .cancelled
        let continuation = self.continuation
        self.continuation = nil
        
        cv.signal()
        cv.unlock()
        
        if let cont = continuation {
            cont(self)
        }
    }
    
    private func stateString() -> String {
        var retVal: String = "Unresolved"
        switch state {
        case .result(let value):
            retVal = "Resolved with result: \(value)"
        case .error (let error):
            retVal = "Resolved with error: \(error)"
        case .cancelled:
            retVal = "Resolved with cancellation"
        case .unresolved:
            retVal = "Unresolved"
        }
        return retVal
    }
    
    // MARK: Chaining (Private)
    
    private func setContinuation(_ block: @escaping (Future) -> Void) throws {
        cv.lock()
        guard continuation == nil else {
            cv.unlock()
            throw PromisError.futureContinuationAlreadySet
        }
        continuation = block
        let resolved = state != .unresolved
        
        cv.unlock()
        if (resolved) {
            continuation!(self)
        }
    }
}

public class Promise<FutureType>: NSObject {
    
    public let future: Future<FutureType>
    
    public override init() {
        self.future = Future()
        super.init()
    }
    
    deinit {
        if (!future.isResolved()) {
            let error = PromisError.promiseDeallocatedBeforeBeingResolved
            setError(error)
        }
    }
    
    public override var description: String {
        return "<Promise: future \(self.future)>"
    }
    
    // MARK: Future state setting
    
    public func setResult(_ result: FutureType) {
        future.setResult(result)
    }
    
    public func setError(_ error: Error) {
        future.setError(error)
    }
    
    public func setCancelled() {
        future.cancel()
    }
    
    public func setResolutionOfFuture(_ future: Future<FutureType>) {
        switch future.state {
        case .result(let value):
            setResult(value)
        case .error(let err):
            setError(err)
        case .cancelled:
            setCancelled()
        default: break
        }
    }
    
    // MARK: Generics (templating) supports
    
    fileprivate func setResolutionOfFutureNotResolvedWithResult<PrevFutureType>(_ future: Future<PrevFutureType>) {
        switch future.state {
        case .result(_):
            break
        case .error(let err):
            setError(err)
        case .cancelled:
            setCancelled()
        default: break
        }
    }
}
