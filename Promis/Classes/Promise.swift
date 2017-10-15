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
    
    func setResolutionOfFutureNotResolvedWithResult<PrevFutureType>(_ future: Future<PrevFutureType>) {
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
