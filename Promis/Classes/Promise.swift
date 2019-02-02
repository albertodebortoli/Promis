//
//  Promise.swift
//  Promis
//
//  Created by Alberto De Bortoli on 14/10/2017.
//  Copyright © 2017 Alberto De Bortoli. All rights reserved.
//

import Foundation

public class Promise<ResultType> {
    
    public let future: Future<ResultType>
    
    public init() {
        self.future = Future()
    }
    
    deinit {
        if (!future.isResolved()) {
            let error = PromisError.promiseDeallocatedBeforeBeingResolved
            setError(error)
        }
    }
    
    public var description: String {
        return "<Promise: future \(self.future.description)>"
    }
    
    // MARK: Future state setting
    
    /**
     Resolves the receiver by setting a result.
     
     - parameter result: The result to use for the resolution.
     */
    public func setResult(_ result: ResultType) {
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
    public func cancel() {
        future.cancel()
    }
    
    /**
     Resolve the receiver with the state of the given future.
     
     - parameter future: The future to use for the resolution.
     */
    public func setResolution(of future: Future<ResultType>) {
        switch future.state {
        case .result(let value):
            setResult(value)
        case .error(let err):
            setError(err)
        default:
            cancel()
        }
    }
    
    // MARK: Generics (templating) supports
    
    /**
     Resolve the receiver with the state of the given future, ignoring the result state. This method allows chaining in `thenWithResult` to match the requirements forced by generics.
     
     - parameter future: The future to use for the resolution.
     */
    func setResolutionOfFutureNotResolvedWithResult<PrevResultType>(_ future: Future<PrevResultType>) {
        switch future.state {
        case .error(let err):
            setError(err)
        default:
            cancel()
        }
    }
}
