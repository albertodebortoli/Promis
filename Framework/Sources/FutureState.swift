//
//  Future+WhenAll.swift
//  Promis
//
//  Created by Alberto De Bortoli on 14/10/2017.
//  Copyright © 2017 Alberto De Bortoli. All rights reserved.
//

import Foundation

public enum FutureState<ResultType> {
    case unresolved
    case result(ResultType)
    case error(Error)
    case cancelled
    
    func getResult() -> ResultType? {
        guard case .result(let value) = self else { return nil }
        return value
    }
    
    func getError() -> Error? {
        guard case .error(let err) = self else { return nil }
        return err
    }
    
    func isCancelled() -> Bool {
        return self == .cancelled
    }
}

func ==<ResultType>(lhs: FutureState<ResultType>, rhs: FutureState<ResultType>) -> Bool {
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

func !=<ResultType>(lhs: FutureState<ResultType>, rhs: FutureState<ResultType>) -> Bool {
    return !(lhs == rhs)
}
