//
//  Future.swift
//  Promis
//
//  Created by Alberto De Bortoli on 14/10/2017.
//  Copyright © 2017 Alberto De Bortoli. All rights reserved.
//

import Foundation

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
    
    // MARK: State setting (Private)
    
    func setResult(_ result: FutureType) {
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
    
    func setError(_ error: Error) {
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
    
    func cancel() {
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
    
}
