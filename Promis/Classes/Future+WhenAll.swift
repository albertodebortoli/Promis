//
//  Future+WhenAll.swift
//  Promis
//
//  Created by Alberto De Bortoli on 14/10/2017.
//  Copyright © 2017 Alberto De Bortoli. All rights reserved.
//

import Foundation

extension Future {
    
    @discardableResult
    public class func whenAll(_ futures: [Future]) -> Future<[Future]> {
        let promise = Promise<[Future]>()
        let results = futures
        var counter = Int32(results.count)
        for element in futures {
            element.finally { _ in
                if (OSAtomicDecrement32(&counter) == 0) {
                    promise.setResult(results)
                }
            }
        }
        return promise.future
    }
    
}
