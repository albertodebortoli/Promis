//
//  PromisTests.swift
//  Promis
//
//  Created by Alberto De Bortoli on 11/10/2017.
//  Copyright © 2017 Alberto De Bortoli. All rights reserved.
//

import XCTest
@testable import Promis

class PromisTests: XCTestCase {
    
    let TestErrorDomain = "com.albertodebortoli.promis.tests"
    
    func test_GivenUnresolvedPromise_WhenCheckingFutureState_ThenStateIsUnresolved() {
        let p = Promise<String>()
        let f = p.future
        XCTAssert(f.state == .unresolved)
    }
    
    func test_GivenUnresolvedPromise_WhenAskingFutureState_ThenStateChecksReturnFalse() {
        let p = Promise<String>()
        let f = p.future
        XCTAssertFalse(f.isResolved())
        XCTAssertFalse(f.hasResult())
        XCTAssertFalse(f.hasError())
        XCTAssertFalse(f.isCancelled)
    }
    
    func test_GivenFutureWithResult_ThenFutureHasResult() {
        let f = Future<Bool>.future(withResult: true)
        XCTAssertTrue(f.isResolved())
        XCTAssertTrue(f.hasResult())
        XCTAssertFalse(f.hasError())
        XCTAssertFalse(f.isCancelled)
    }
    
    func test_GivenFutureWithError_ThenFutureHasError() {
        let error = NSError(domain: TestErrorDomain, code:0, userInfo:nil)
        let f = Future<Bool>.future(withError: error)
        XCTAssertTrue(f.isResolved())
        XCTAssertFalse(f.hasResult())
        XCTAssertTrue(f.hasError())
        XCTAssertFalse(f.isCancelled)
    }
    
    func test_GivenCancelledFuture_ThenFutureIsCancelled() {
        let f = Future<Bool>.cancelledFuture()
        XCTAssertTrue(f.isResolved())
        XCTAssertFalse(f.hasResult())
        XCTAssertFalse(f.hasError())
        XCTAssertTrue(f.isCancelled)
    }
    
    func test_GivenFutureWithResult_WhenCreatingFutureWithResolutionOfFuture_ThenFutureHasResult() {
        let f = Future<Bool>.future(withResult: true)
        let f2 = Future<Bool>.futureWithResolution(of: f)
        XCTAssertTrue(f2.isResolved())
        XCTAssertTrue(f2.hasResult())
        XCTAssertFalse(f2.hasError())
        XCTAssertFalse(f2.isCancelled)
    }
    
    func test_GivenFutureWithError_WhenCreatingFutureWithResolutionOfFuture_ThenFutureHasError() {
        let error = NSError(domain: TestErrorDomain, code:0, userInfo:nil)
        let f = Future<Bool>.future(withError: error)
        let f2 = Future<Bool>.futureWithResolution(of: f)
        XCTAssertTrue(f2.isResolved())
        XCTAssertFalse(f2.hasResult())
        XCTAssertTrue(f2.hasError())
        XCTAssertFalse(f2.isCancelled)
    }
    
    func test_GivenCancelledFuture_WhenCreatingFutureWithResolutionOfFuture_ThenFutureIsCancelled() {
        let f = Future<Bool>.cancelledFuture()
        let f2 = Future<Bool>.futureWithResolution(of: f)
        XCTAssertTrue(f2.isResolved())
        XCTAssertFalse(f2.hasResult())
        XCTAssertFalse(f2.hasError())
        XCTAssertTrue(f2.isCancelled)
    }
    
    func test_GivenPromise_WhenSetResult_ThenFutureHasResult() {
        let p = Promise<String>()
        let f = p.future
        
        p.setResult("1")
        XCTAssertTrue(f.isResolved())
        XCTAssertTrue(f.hasResult())
        XCTAssertFalse(f.hasError())
        XCTAssertFalse(f.isCancelled)
        
        XCTAssertEqual(f.result!, "1")
        XCTAssertNil(f.error)
    }
    
    func test_GivenPromise_WhenSetResult_ThenFutureHasStateResolvedWithResult() {
        let p = Promise<String>()
        let f = p.future
        
        p.setResult("1")
        XCTAssert(f.state == .result("1"))
    }
    
    func test_GivenPromise_WhenSetError_ThenFutureHasError() {
        let p = Promise<String>()
        let f = p.future
        
        let error = NSError(domain: TestErrorDomain, code:0, userInfo:nil)
        p.setError(error)
        XCTAssertTrue(f.isResolved())
        XCTAssertFalse(f.hasResult())
        XCTAssertTrue(f.hasError())
        XCTAssertFalse(f.isCancelled)
        
        XCTAssertNil(f.result)
        XCTAssertEqual(f.error! as NSError, error)
    }
    
    func test_GivenPromise_WhenSetError_ThenFutureHasStateResolvedWithError() {
        let p = Promise<String>()
        let f = p.future
        
        let error = NSError(domain: TestErrorDomain, code:0, userInfo:nil)
        p.setError(error)
        XCTAssert(f.state == .error(error))
    }
    
    func test_GivenPromise_WhenCancelled_ThenFutureIsCancelled() {
        let p = Promise<String>()
        let f = p.future
        
        p.cancel()
        XCTAssertTrue(f.isResolved())
        XCTAssertFalse(f.hasResult())
        XCTAssertFalse(f.hasError())
        XCTAssertTrue(f.isCancelled)
        
        XCTAssertNil(f.result)
        XCTAssertNil(f.error)
    }
    
    func test_GivenPromise_WhenCancelled_ThenFutureHasStateResolvedWithCancellation() {
        let p = Promise<String>()
        let f = p.future
        
        p.cancel()
        XCTAssert(f.state == .cancelled)
    }
    
    func test_GivenPromise_WhenFutureSetResultWhileWaiting_ThenResultIsSet() {
        let p = Promise<String>()
        let f = p.future
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            p.setResult("1")
        }
        
        XCTAssertEqual(f.result, "1")
    }
    
    func test_GivenPromise_WhenFutureSetResultWhileExplicitlyWaiting_ThenResultIsSet() {
        let p = Promise<String>()
        let f = p.future
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            p.setResult("1")
        }
        
        f.wait()
        XCTAssertTrue(f.hasResult())
        XCTAssertEqual(f.result!, "1")
    }
    
    func test_GivenPromise_WhenNotSatisfiedAndDealloced_ThenFutureHasError() {
        var f: Future<String>!
        autoreleasepool {
            let p = Promise<String>()
            f = p.future
        }
        
        XCTAssertTrue(f.hasError())
        XCTAssert((f.error as! PromisError) == .promiseDeallocatedBeforeBeingResolved)
    }
    
    func test_GivenPromise_WhenFutureIsAskedToWaitUntilDateAndSetResult_ThenFutureHasResult() {
        let p = Promise<String>()
        let f = p.future
        
        XCTAssertFalse(f.waitUntilDate(Date(timeIntervalSinceNow: 1)))
        
        p.setResult("1")
        XCTAssertTrue(f.waitUntilDate(Date(timeIntervalSinceNow: 1)))
        
        XCTAssertTrue(f.hasResult())
        XCTAssertEqual(f.result, "1")
    }
    
    func test_GivenPromise_WhenSetContinuationAndResultIsSet_ThenContinuationIsExecuted() {
        let p = Promise<String>()
        let f = p.future
        
        let exp: XCTestExpectation = expectation(description: "test expectation")
        f.finally { future in
            XCTAssertEqual(future.result, "1")
            exp.fulfill()
        }
        
        p.setResult("1")
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func test_GivenPromise_WhenSetContinuationOnGlobalQueueAndResultIsSet_ThenContinuationIsExecuted() {
        let p = Promise<String>()
        let f = p.future
        
        let exp: XCTestExpectation = expectation(description: "test expectation")
        let queue = DispatchQueue.global()
        
        f.finally(queue: queue) { future in
            XCTAssertEqual(future.result, "1")
            exp.fulfill()
        }
        
        p.setResult("1")
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func test_GivenPromise_WhenFutureContinuesWithSynchronousTaskAndResultIsSet_ThenNewFutureHasResult() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.then { future -> Future<String> in
            let p = Promise<String>()
            p.setResult(future.result! + "2")
            return p.future
        }
        
        p.setResult("1")
        XCTAssertTrue(f2.hasResult())
        XCTAssertEqual(f2.result!, "12")
    }
    
    func test_GivenPromise_WhenFutureContinuesWithNotSatisfyingSynchronousTaskAndResultIsSet_ThenNewFutureHasError() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.then { future -> Future<String> in
            let p = Promise<String>()
            return p.future
        }
        
        p.setResult("1")
        XCTAssertTrue(f2.hasError())
        XCTAssertNotNil(f2.error)
    }
    
    func test_GivenPromise_WhenFutureContinuesWithAsynchronousTaskAndResultIsSet_ThenNewFutureHasResult() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.then { future -> Future<String> in
            let p = Promise<String>()
            
            let queue = DispatchQueue.global()
            queue.asyncAfter(deadline: .now() + 1, execute: {
                p.setResult(future.result! + "2")
            })
            
            return p.future
        }
        
        p.setResult("1")
        f2.wait()
        XCTAssertTrue(f2.hasResult())
        XCTAssertEqual(f2.result!, "12")
    }
    
    func test_GivenPromise_WhenContinuesWithTaskAndSetResult_ThenFutureHasResult() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.then { future -> Future<String> in
            XCTAssertTrue(future.hasResult())
            return Future.futureWithResolution(of: future)
        }
        
        p.setResult("42")
        XCTAssertTrue(f2.hasResult())
        XCTAssertEqual(f2.result!, "42")
    }
    
    func test_GivenPromise_WhenContinuesWithTaskAndSetError_ThenFutureHasError() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.then { future -> Future<String> in
            XCTAssertTrue(future.hasError())
            return Future<String>.futureWithResolution(of: future)
        }
        
        let error = NSError(domain: TestErrorDomain, code:0, userInfo:nil)
        p.setError(error)
        XCTAssertTrue(f2.hasError())
        XCTAssertEqual(f2.error! as NSError, error)
    }
    
    func test_GivenPromise_WhenContinuesWithTaskAndCancelled_ThenFutureIsCancelled() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.then { future -> Future<String> in
            XCTAssertTrue(future.isCancelled)
            return Future.futureWithResolution(of: future)
        }
        
        p.cancel()
        XCTAssertTrue(f2.isCancelled)
    }
    
    func test_GivenPromise_WhenContinuesWithTaskOnGlobalQueueAndResultIsSet_ThenFutureHasResult() {
        let p = Promise<String>()
        let f = p.future
        
        let queue = DispatchQueue.global()
        
        let f2 = f.then(queue: queue) { future -> Future<String> in
            let p = Promise<String>()
            p.setResult(future.result! + "2")
            return p.future
        }
        
        p.setResult("1")
        
        f2.wait()
        XCTAssertTrue(f2.hasResult())
        XCTAssertEqual(f2.result!, "12")
    }
    
    func test_GivenPromise_WhenFutureContinuesWithResultAndResultIsSet_ThenResultIsSetOnSubsequentFuture() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.thenWithResult { val -> Future<String> in
            let p = Promise<String>()
            p.setResult(val + "2")
            return p.future
        }
        
        p.setResult("1")
        XCTAssertTrue(f2.hasResult())
        XCTAssertEqual(f2.result!, "12")
    }
    
    func test_GivenPromise_WhenFutureContinuesWithResultAndErrorIsSet_ThenSubsequentFutureHasError() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.thenWithResult { val -> Future<String> in
            let p = Promise<String>()
            p.setResult(val + "2")
            return p.future
        }
        
        let error = NSError(domain: TestErrorDomain, code:0, userInfo:nil)
        p.setError(error)
        
        XCTAssertTrue(f2.hasError())
        XCTAssertEqual(f2.error! as NSError, error)
    }
    
    func test_GivenPromise_WhenFutureContinuesWithResultAndIsCancelled_ThenSubsequentFutureIsCancelled() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.thenWithResult { val -> Future<String> in
            XCTAssert(false, "This block should not be called")
            let p = Promise<String>()
            p.setResult(val + "2")
            return p.future
        }
        
        p.cancel()
        XCTAssertTrue(f2.isCancelled)
        XCTAssertNil(f2.result)
    }
    
    func test_GivenPromise_WhenContinuesWithResultAndCancelledFuture_ThenFutureIsCancelled() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.thenWithResult { val in
            return Future<String>.cancelledFuture()
        }
        
        p.setResult("1")
        
        XCTAssertTrue(f2.isCancelled)
        XCTAssertNil(f2.result)
    }
    
    func test_GivenPromise_WhenContinuesWithResultAndSetResult_ThenFutureHasResult() {
        let p = Promise<String>()
        let f = p.future
        
        let queue = DispatchQueue.global()
        
        let f2 = f.thenWithResult(queue: queue) { val -> Future<String> in
            let p = Promise<String>()
            p.setResult(val + "2")
            return p.future
        }
        
        p.setResult("1")
        
        f2.wait()
        XCTAssertTrue(f2.hasResult())
        XCTAssertEqual(f2.result!, "12")
    }
    
    func test_GivenPromise_WhenContinuesWithResultOnGlobalQueueAndCancelled_ThenFutureIsCancelled() {
        let p = Promise<String>()
        let f = p.future
        
        let queue = DispatchQueue.global()
        
        let f2 = f.thenWithResult(queue: queue) { val in
            return Future<String>.cancelledFuture()
        }
        
        p.setResult("1")
        
        f2.wait()
        XCTAssertTrue(f2.isCancelled)
        XCTAssertNil(f2.result)
    }
    
    func test_GivenPromise_WhenFutureContinuesWithErrorAndResultIsSet_ThenSubsequentFutureHasError() {
        let p = Promise<String>()
        let f = p.future
        
        let exp: XCTestExpectation = expectation(description: "test expectation")
        
        let f2 = f.onError { err in
            XCTAssert(false, "This block should not be called")
            }.then { future -> Future<String> in
                XCTAssert(true, "This block should be called")
                exp.fulfill()
                return Future.futureWithResolution(of: future)
        }
        
        p.setResult("1")
        
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertTrue(f2.hasResult())
        XCTAssertEqual(f2.result!, "1")
    }
    
    func test_GivenPromise_WhenFutureContinuesWithErrorAndErrorIsSet_ThenSubsequentFutureHasError() {
        let p = Promise<String>()
        let f = p.future
        
        let exp: XCTestExpectation = expectation(description: "test expectation")
        
        let f2 = f.onError { err in
            XCTAssert(true, "This block should be called")
            }.then { future -> Future<String> in
                XCTAssert(true, "This block should be called")
                exp.fulfill()
                return Future.futureWithResolution(of: future)
        }
        
        let error = NSError(domain: TestErrorDomain, code:0, userInfo:nil)
        p.setError(error)
        
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertTrue(f2.hasError())
        XCTAssertEqual(f2.error! as NSError, error)
    }
    
    func test_GivenPromise_WhenFutureContinuesWithErrorAndIsCancelled_ThenSubsequentFutureIsCancelled() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.onError { err in
            XCTAssert(false, "This block should not be called")
        }
        
        p.cancel()
        
        XCTAssertTrue(f2.isCancelled)
        XCTAssertNil(f2.result)
    }
    
    func test_GivenPromise_WhenContinuesWithErrorAndSetResult_ThenFutureHasResult() {
        let p = Promise<String>()
        let f = p.future
        
        let queue = DispatchQueue.global()
        
        let f2 = f.onError(queue: queue) { err in
            XCTAssert(false, "This block should not be called")
        }
        
        p.setResult("1")
        
        f2.wait()
        XCTAssertTrue(f2.hasResult())
        XCTAssertEqual(f2.result!, "1")
    }
    
    func test_GivenPromise_WhenContinuesWithErrorOnGlobalQueueAndSetError_ThenFutureHasError() {
        let p = Promise<String>()
        let f = p.future
        
        let exp: XCTestExpectation = expectation(description: "test expectation")
        
        let queue = DispatchQueue.global()
        
        let f2 = f.onError(queue: queue) { err in
            exp.fulfill()
        }
        
        let error = NSError(domain: TestErrorDomain, code:0, userInfo:nil)
        p.setError(error)
        
        f2.wait()
        
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertTrue(f2.hasError())
        XCTAssertNotNil(f2.error)
    }
    
    func test_GivenPromise_WhenSetContinuationTwice_ThemExceptionIsRaised() {
        let p = Promise<String>()
        let f = p.future
        
        try! f.setContinuation { future in }
                
        XCTAssertThrowsError(try f.setContinuation { future in })
    }
    
    func test_GivenPromises_WhenAllPromisesSucceeded_ThenWhenAllFutureHasResult() {
        let p1 = Promise<String>()
        let p2 = Promise<String>()
        let p3 = Promise<String>()
        
        let futures = [p1.future, p2.future, p3.future]
        let allFuture = Future.whenAll(futures)
        
        XCTAssertFalse(allFuture.hasResult())
        p3.setResult("3")
        XCTAssertFalse(allFuture.hasResult())
        p1.setResult("1")
        XCTAssertFalse(allFuture.hasResult())
        p2.setResult("2")
        
        XCTAssertTrue(allFuture.hasResult())
        
        let results = allFuture.result!
        XCTAssertEqual(results[0].result!, "1")
        XCTAssertEqual(results[1].result!, "2")
        XCTAssertEqual(results[2].result!, "3")
    }
    
    func test_GivenPromises_WhenAllPromisesAreSatisfied_ThenWhenAllFutureHasResult() {
        let p1 = Promise<String>()
        let p2 = Promise<String>()
        let p3 = Promise<String>()
        
        let futures = [p1.future, p2.future, p3.future]
        let allFuture = Future.whenAll(futures)
        
        XCTAssertFalse(allFuture.hasResult())
        p3.cancel()
        XCTAssertFalse(allFuture.hasResult())
        p1.setResult("1")
        XCTAssertFalse(allFuture.hasResult())
        let error = NSError(domain: TestErrorDomain, code:0, userInfo:nil)
        p2.setError(error)
        
        XCTAssertTrue(allFuture.hasResult())
        
        let results = allFuture.result!
        XCTAssertEqual(results[0].result, "1")
        XCTAssertTrue(results[1].hasError())
        XCTAssert(results[1].state == .error(error))
        XCTAssertTrue(results[2].isCancelled)
    }
    
    func test_GivenUnresolvedPromise_WhenPrintedDescription_ThenProperDescriptionIsPrinted() {
        let p = Promise<String>()
        let testValue: String = "Unresolved".lowercased()
        let targetValue: String = p.description.lowercased()
        XCTAssertNotNil(targetValue.range(of: testValue))
    }
    
    func test_GivenPromiseResolvedWithResult_WhenPrintedDescription_ThenProperDescriptionIsPrinted() {
        let p = Promise<String>()
        p.setResult("42")
        let testValue = "Resolved with result".lowercased()
        let targetValue = p.description.lowercased()
        XCTAssertNotNil(targetValue.range(of: testValue))
    }
    
    func test_GivenPromiseResolvedWithError_WhenPrintedDescription_ThenProperDescriptionIsPrinted() {
        let p = Promise<String>()
        p.setError(NSError(domain: TestErrorDomain, code:0, userInfo:nil))
        let testValue = "Resolved with error".lowercased()
        let targetValue = p.description.lowercased()
        XCTAssertNotNil(targetValue.range(of: testValue))
    }
    
    func test_GivenCancelledPromise_WhenPrintedDescription_ThenProperDescriptionIsPrinted() {
        let p = Promise<String>()
        p.cancel()
        let testValue = "Resolved with cancellation".lowercased()
        let targetValue = p.description.lowercased()
        XCTAssertNotNil(targetValue.range(of: testValue))
    }
    
}
