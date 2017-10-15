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
        switch self {
        case .result(let res): return res
        default: return nil
        }
    }
    
    func getError() -> Error? {
        switch self {
        case .error(let err): return err
        default: return nil
        }
    }
    
    func isCancelled() -> Bool {
        switch self {
        case .cancelled: return true
        default: return false
        }
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
