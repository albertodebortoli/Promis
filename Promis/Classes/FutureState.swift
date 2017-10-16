//
//  Future+WhenAll.swift
//  Promis
//
//  Created by Alberto De Bortoli on 14/10/2017.
//  Copyright © 2017 Alberto De Bortoli. All rights reserved.
//

import Foundation

public enum FutureState<FutureType> {
    case unresolved
    case result(FutureType)
    case error(Error)
    case cancelled
    
    func getResult() -> FutureType? {
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
