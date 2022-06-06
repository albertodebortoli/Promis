//
//  PromisError.swift
//  Promis
//
//  Created by Alberto De Bortoli on 14/10/2017.
//  Copyright © 2017 Alberto De Bortoli. All rights reserved.
//

import Foundation

enum PromisError: Error {
    case futureContinuationAlreadySet
    case promiseDeallocatedBeforeBeingResolved
}
