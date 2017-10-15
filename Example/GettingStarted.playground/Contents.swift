//: Playground - noun: a place where people can play

import UIKit
import Promis

enum GettingStartedError: Error {
    case malformedData
}

func exampleTask() {
    
    let request = URLRequest(url: URL(string: "http://example.com")!)
    
    download(request: request).continueWithResult { data in
        parse(data: data)
        }.continueWithResult { parsedData in
            map(data: parsedData)
        }.continueWithError { error in
            // executed only in case an error occurred in the chain
            print("error: " + String(describing: error))
        }.continues { future in
            print(future)
    }
}

// MARK: Internal

func download(request: URLRequest) -> Future<Data> {
    print(#function)
    print("request: " + String(describing: request))
    let promise = Promise<Data>()
    // async code retrieving the data here
    let data = "[{\"key\":\"value\"}]".data(using: .utf8)!
    promise.setResult(data)
    return promise.future
}

func parse(data: Data) -> Future<[Dictionary<String,AnyObject>]> {
    print(#function)
    print("data: " + String(describing: data))
    let promise = Promise<[Dictionary<String,AnyObject>]>()
    // parsing code here
    do {
        let parsedData = try JSONSerialization.jsonObject(with: data, options: []) as! [Dictionary<String,AnyObject>]
        promise.setResult(parsedData)
    } catch {
        promise.setError(error)
    }
    // could simply return promise.future, but specific error handling/logging
    // should be done here as part of the responsibilities of the function
    return promise.future.continueWithError(resultTask: {error in
        // handle/log error
    })
}

struct FooBar {
    let value: String
}

func map(data: [Dictionary<String,AnyObject>]) -> Future<[FooBar]> {
    print(#function)
    print("data: " + String(describing: data))
    let promise = Promise<[FooBar]>()
    promise.setResult(data.flatMap { obj -> FooBar? in
        if let value = obj["key"] as? String {
            return FooBar(value: value)
        }
        return nil
    })
    return promise.future
}

exampleTask()
