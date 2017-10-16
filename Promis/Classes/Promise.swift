//
//  Promise.swift
//  Promis
//
//  Created by Alberto De Bortoli on 14/10/2017.
//  Copyright © 2017 Alberto De Bortoli. All rights reserved.
//

import Foundation

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
    
    /**
     Resolves the receiver by setting a result.
     
     - parameter result: The result to use for the resolution.
     */
    public func setResult(_ result: FutureType) {
        future.setResult(result)
    }
    
    /**
     Resolves the receiver by setting an error.
     
     - parameter error: The error to use for the resolution.
     */
    public func setError(_ error: Error) {
        future.setError(error)
    }
    
    /**
     Resolves the receiver by cancelling it.
     */
    public func setCancelled() {
        future.cancel()
    }
    
    /**
     Resolve the receiver with the state of the given future.
     
     - parameter future: The future to use for the resolution.
     */
    public func setResolutionOfFuture(_ future: Future<FutureType>) {
        switch future.state {
        case .result(let value):
            setResult(value)
        case .error(let err):
            setError(err)
        default:
            setCancelled()
        }
    }
    
    // MARK: Generics (templating) supports
    
    /**
     Resolve the receiver with the state of the given future, ignoring the result state. This method allows chaining in `thenWithResult` to match the requirements forced by generics.
     
     - parameter future: The future to use for the resolution.
     */
    func setResolutionOfFutureNotResolvedWithResult<PrevFutureType>(_ future: Future<PrevFutureType>) {
        switch future.state {
        case .error(let err):
            setError(err)
        default:
            setCancelled()
        }
    }
}
