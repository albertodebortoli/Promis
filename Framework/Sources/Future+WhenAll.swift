//
//  Future+WhenAll.swift
//  Promis
//
//  Created by Alberto De Bortoli on 14/10/2017.
//  Copyright © 2017 Alberto De Bortoli. All rights reserved.
//

import Foundation

extension Future {
    
    /**
     Creates and returns a future that is resolved with a result when all the futures passed as parametes are resolved.
     
     - parameter futures: An array of futures
     
     - returns: A future of type [FutureState] with the resolved states of all the futures passed as parameters.
     */
    @discardableResult
    public class func whenAll<T>(_ futures: [Future<T>]) -> Future<[FutureState<T>]> {
        let future = Future<[FutureState<T>]>()
        var counter = Int32(futures.count)
        var states = Array<FutureState<T>>(repeating: .unresolved, count: Int(counter))
        for (index, element) in futures.enumerated() {
            element.finally { [unowned future] fut in
                states[index] = fut.state
                if (OSAtomicDecrement32(&counter) == 0) {
                    future.setResult(states)
                }
            }
        }
        return future
    }
}
