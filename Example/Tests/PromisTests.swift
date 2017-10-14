//
//  PromisTests.swift
//  Promis
//
//  Created by Alberto De Bortoli on 11/10/2017.
//  Copyright © 2017 Just Eat. All rights reserved.
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
        
        p.setCancelled()
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
        
        p.setCancelled()
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
        XCTAssertNotNil(f.error)
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
        f.continues { future in
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
        
        f.continues(queue: queue) { future in
            XCTAssertEqual(future.result, "1")
            exp.fulfill()
        }
        
        p.setResult("1")
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func test_GivenPromise_WhenFutureContinuesWithSynchronousTaskAndResultIsSet_ThenNewFutureHasResult() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.continueWithTask { future -> Future<String> in
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
        
        let f2 = f.continueWithTask { future -> Future<String> in
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
        
        let f2 = f.continueWithTask { future -> Future<String> in
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
        
        let f2 = f.continueWithTask { future -> Future<String> in
            XCTAssertTrue(future.hasResult())
            return Future.futureWithResolutionOfFuture(future)
        }
        
        p.setResult("42")
        XCTAssertTrue(f2.hasResult())
        XCTAssertEqual(f2.result!, "42")
    }
    
    func test_GivenPromise_WhenContinuesWithTaskAndSetError_ThenFutureHasError() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.continueWithTask { future -> Future<String> in
            XCTAssertTrue(future.hasError())
            return Future<String>.futureWithResolutionOfFuture(future)
        }
        
        let error = NSError(domain: TestErrorDomain, code:0, userInfo:nil)
        p.setError(error)
        XCTAssertTrue(f2.hasError())
        XCTAssertEqual(f2.error! as NSError, error)
    }
    
    func test_GivenPromise_WhenContinuesWithTaskAndCancelled_ThenFutureIsCancelled() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.continueWithTask { future -> Future<String> in
            XCTAssertTrue(future.isCancelled)
            return Future.futureWithResolutionOfFuture(future)
        }
        
        p.setCancelled()
        XCTAssertTrue(f2.isCancelled)
    }
    
    func test_GivenPromise_WhenContinuesWithTaskOnGlobalQueueAndResultIsSet_ThenFutureHasResult() {
        let p = Promise<String>()
        let f = p.future
        
        let queue = DispatchQueue.global()
        
        let f2 = f.continueWithTask(queue: queue) { future -> Future<String> in
            let p = Promise<String>()
            p.setResult(future.result! + "2")
            return p.future
        }
        
        p.setResult("1")
        
        f2.wait()
        XCTAssertTrue(f2.hasResult())
        XCTAssertEqual(f2.result!, "12")
    }
    
    func test_GivenPromise_WhenFutureContinuesWithSuccessTaskAndResultIsSet_ThenResultIsSetOnSubsequentFuture() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.continueWithResult { val -> Future<String> in
            let p = Promise<String>()
            p.setResult(val + "2")
            return p.future
        }
        
        p.setResult("1")
        XCTAssertTrue(f2.hasResult())
        XCTAssertEqual(f2.result!, "12")
    }
    
    func test_GivenPromise_WhenFutureContinuesWithSuccessTaskAndErrorIsSet_ThenSubsequentFutureHasError() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.continueWithResult { val -> Future<String> in
            let p = Promise<String>()
            p.setResult(val + "2")
            return p.future
        }
        
        let error = NSError(domain: TestErrorDomain, code:0, userInfo:nil)
        p.setError(error)
        
        XCTAssertTrue(f2.hasError())
        XCTAssertEqual(f2.error! as NSError, error)
    }
    
    func test_GivenPromise_WhenFutureContinuesWithSuccessTaskAndIsCancelled_ThenSubsequentFutureIsCancelled() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.continueWithResult { val -> Future<String> in
            XCTAssert(false, "This block should not be called")
            let p = Promise<String>()
            p.setResult(val + "2")
            return p.future
        }
        
        p.setCancelled()
        XCTAssertTrue(f2.isCancelled)
        XCTAssertNil(f2.result)
    }
    
    func test_GivenPromise_WhenContinuesWithSuccessCancelledTask_ThenFutureIsCancelled() {
        let p = Promise<String>()
        let f = p.future
        
        let f2 = f.continueWithResult { val in
            return Future<String>.cancelledFuture()
        }
        
        p.setResult("1")
        
        XCTAssertTrue(f2.isCancelled)
        XCTAssertNil(f2.result)
    }
    
    func test_GivenPromise_WhenContinuesWithSuccessAndSetResult_ThenFutureHasResult() {
        let p = Promise<String>()
        let f = p.future

        let queue = DispatchQueue.global()

        let f2 = f.continueWithResult(queue: queue) { val -> Future<String> in
            let p = Promise<String>()
            p.setResult(val + "2")
            return p.future
        }

        p.setResult("1")

        f2.wait()
        XCTAssertTrue(f2.hasResult())
        XCTAssertEqual(f2.result!, "12")
    }

    func test_GivenPromise_WhenContinuesWithSuccessCancelledTaskOnGlobalQueue_ThenFutureIsCancelled() {
        let p = Promise<String>()
        let f = p.future
        
        let queue = DispatchQueue.global()
        
        let f2 = f.continueWithResult(queue: queue) { val in
            return Future<String>.cancelledFuture()
        }
        
        p.setResult("1")
        
        f2.wait()
        XCTAssertTrue(f2.isCancelled)
        XCTAssertNil(f2.result)
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
        p3.setCancelled()
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
    
    func test_GivenCanceledPromise_WhenPrintedDescription_ThenProperDescriptionIsPrinted() {
        let p = Promise<String>()
        p.setCancelled()
        let testValue = "Resolved with cancellation".lowercased()
        let targetValue = p.description.lowercased()
        XCTAssertNotNil(targetValue.range(of: testValue))
    }
    
}
