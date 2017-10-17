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
    private(set) public var state: FutureState<FutureType> = .unresolved
    
    public override init() {
        self.cv = NSCondition()
        super.init()
    }
    
    public override var description: String {
        return "<Future: state \(stateString())>"
    }
    
    // MARK: Creation
    
    /**
     Initializes a new resolved future with a result.
     
     - parameter result: The result to use to resolve the future
     
     - returns: A newly created future, resolved with result.
     */
    public class func futureWithResult(_ result: FutureType) -> Future<FutureType> {
        let promise = Promise<FutureType>()
        promise.setResult(result)
        return promise.future
    }
    
    /**
     Initializes a new resolved future with an error.
     
     - parameter error: The error to use to resolve the future
     
     - returns: A newly created future, resolved with error.
     */
    public class func futureWithError(_ error: Error) -> Future<FutureType> {
        let promise = Promise<FutureType>()
        promise.setError(error)
        return promise.future
    }
    
    /**
     Initializes a new resolved future in cancelled state.
     
     - returns: A newly created future, resolved with cancellation.
     */
    public class func cancelledFuture() -> Future<FutureType> {
        let promise = Promise<FutureType>()
        promise.cancel()
        return promise.future
    }
    
    /**
     Initializes a new resolved future.
     
     - parameter future: The future with the state to use to resolve the returning future
     
     - returns: A newly created and resolved future.
     */
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
    
    /**
     If the receiver is not resolved, the function waits for resolution before returning the result.
     */
    public var result: FutureType? {
        get {
            wait()
            return state.getResult()
        }
    }
    
    /**
     If the receiver is not resolved, the function waits for resolution before returning the error.
     */
    public var error: Error? {
        get {
            wait()
            return state.getError()
        }
    }
    
    /**
     If the receiver is not resolved, the function waits for resolution before returning if it was cancelled.
     */
    public var isCancelled: Bool {
        get {
            return state.isCancelled()
        }
    }
    
    // MARK: State checks
    
    /**
     True if the future is in a resolved state, false otherwise.
     */
    public func isResolved() -> Bool {
        cv.lock()
        let retVal = state != FutureState<FutureType>.unresolved
        cv.unlock()
        return retVal
    }
    /**
     True if the future has a result, false otherwise.
     */
    public func hasResult() -> Bool {
        cv.lock()
        let retVal = (state.getResult() != nil)
        cv.unlock()
        return retVal
    }
    
    /**
     True if the future has an error, false otherwise.
     */
    public func hasError() -> Bool {
        cv.lock()
        let retVal = (state.getError() != nil)
        cv.unlock()
        return retVal
    }
    
    // MARK: Waiting for resolution
    
    /**
     Blocks the current thread waiting for the receiver to be resolved.
     */
    public func wait() {
        cv.lock()
        while (state == .unresolved) {
            cv.wait()
        }
        cv.unlock()
    }
    
    /**
     Blocks the current thread waiting for the receiver to be resolved before a given date.
     */
    public func waitUntilDate(_ date: Date) -> Bool {
        cv.lock()
        var timeoutExpired = false
        while (state == .unresolved && !timeoutExpired) {
            timeoutExpired = !cv.wait(until: date)
        }
        cv.unlock()
        return !timeoutExpired
    }
    
    // MARK: State setting (Private)
    
    /**
     Resolves the receiver by setting a result.
     
     - parameter result: The result to use for the resolution.
     */
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
    
    /**
     Resolves the receiver by setting an error.
     
     - parameter error: The error to use for the resolution.
     */
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
    
    /**
     Resolves the receiver by cancelling it.
     */
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
    
    /**
     The string representation of the state of the receiver.
     
     - returns: A string describing the state.
     */
    func stateString() -> String {
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
