//
//  Future+Chaining.swift
//  Promis
//
//  Created by Alberto De Bortoli on 14/10/2017.
//  Copyright © 2017 Alberto De Bortoli. All rights reserved.
//

import Foundation

extension Future {
    
    // MARK: Chaining
    
    /**
     Continues the execution of the receiver with a finally block.
     
     - parameter queue: An optional queue used to execute the block on
     - parameter block: The block to execute as continuation of the future receiving the receiver as a parameter
     */
    public func finally(queue: DispatchQueue? = nil, block: @escaping (Future<FutureType>) -> Void) {
        // rather than making all the chaining APIs throwable
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
    
    /**
     Continues the execution of the receiver allowing chaining.
     
     - parameter queue: An optional queue used to execute the block on
     - parameter block: The block to execute as continuation of the future receiving the receiver as a parameter and returning a new future (possibly with a different type)
     
     - returns: A new future resolved with the resolution of the future returned by the block parameter.
     */
    @discardableResult
    public func then<NextFutureType>(queue: DispatchQueue? = nil, task: @escaping (Future) -> Future<NextFutureType>) -> Future<NextFutureType> {
        let promise = Promise<NextFutureType>()
        finally(queue: queue) { future in
            let f2 = task(future)
            f2.finally(queue: queue) { fut2 in
                promise.setResolutionOfFuture(fut2)
            }
        }
        return promise.future
    }
    
    /**
     Continues the execution of the receiver allowing chaining.
     
     - parameter queue: An optional queue used to execute the block on
     - parameter block: The block to execute as continuation of the future receiving the result of the receiver as a parameter and returning a new future (possibly with a different type). The block is not execute if the receiver is not resolved with a result.
     
     - returns: A new future resolved with the resolution of the future returned by the block parameter.
     */
    @discardableResult
    public func thenWithResult<NextFutureType>(queue: DispatchQueue? = nil, resultTask: @escaping (FutureType) -> Future<NextFutureType>) -> Future<NextFutureType> {
        let promise = Promise<NextFutureType>()
        finally(queue: queue) { future in
            guard case .result(let value) = self.state else {
                promise.setResolutionOfFutureNotResolvedWithResult(future)
                return
            }
            let f2 = resultTask(value)
            f2.finally(queue: queue) { fut2 in
                promise.setResolutionOfFuture(fut2)
            }
        }
        return promise.future
    }
    
    /**
     Continues the execution of the receiver allowing chaining.
     
     - parameter queue: An optional queue used to execute the block on
     - parameter block: The block to execute as continuation of the future receiving the error of the receiver as a parameter. The block is not execute if the receiver is not resolved with error.
     
     - returns: A new future resolved with the resolution of the receiver.
     */
    @discardableResult
    public func onError(queue: DispatchQueue? = nil, resultTask: @escaping (Error) -> Void) -> Future {
        let promise = Promise<FutureType>()
        finally(queue: queue) { future in
            guard case .error(let err) = self.state else {
                promise.setResolutionOfFuture(future)
                return
            }
            resultTask(err)
            promise.setResolutionOfFuture(future)
        }
        return promise.future
    }
    
    // MARK: Chaining (Private)
    
    /**
     Continues the execution of the receiver with a finally block.
     
     - parameter block: The block to execute as continuation of the future receiving the receiver as a parameter.
    */
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
