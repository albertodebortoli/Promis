import UIKit
import Promis

enum GettingStartedError: Error {
    case malformedData
}

//: This is an example of basic usage chaining functions that return futures. The method mimics a common getData-parse-map sequence of actions.

func basicExample() {
    
    let request = URLRequest(url: URL(string: "http://example.com")!)
    
    // starts by hitting an API to download data
    getData(request: request).thenWithResult { data in
        // continue by parsing the retrieved data
        parse(data: data)
        }.thenWithResult { parsedData in
            // continue by mapping the parsed data
            map(data: parsedData)
        }.onError { error in
            // executed only in case an error occurred in the chain
            print("error: " + String(describing: error))
        }.finally(queue: .main) { future in
            // always executed, no matter the state of the previous future or how the chain did perform
            switch future.state {
            case .result(let value):
                print(String(describing: value))
            case .error(let err):
                print(String(describing: err))
            case .cancelled:
                print("future is in a cancelled state")
            case .unresolved:
                print("this really cannot be if any chaining block is executed")
            }
    }
}

func explicitTypesExample() {
    
    let request = URLRequest(url: URL(string: "http://example.com")!)
    
    // starts by hitting an API to download data
    getData(request: request).thenWithResult { data -> Future<[Dictionary<String,AnyObject>]> in
        /**
         If a block is not trivial, Swift cannot infer the type of the closure and gives the error
         'Unable to infer complex closure return type; add explicit type to disambiguate'
         so you'll have to add `-> Future<<#NextFutureType#>> to the block signature
         
         You can make it complex just by adding a print statement.
         
         All the more reason to structure your code as done in the first given example :)
         */
        print("complex closure")
        return parse(data: data)
        }.thenWithResult { parsedData -> Future<[FooBar]> in
            // continue by mapping the parsed data
            print("complex closure")
            return map(data: parsedData)
        }.onError { error in
            // executed only in case an error occurred in the chain
            // in the case of `onError`, Swift has no problem of inferring the type
            // as the block does not return any future, chaining is done using the previous future
            print("complex closure")
            print("error: " + String(describing: error))
        }.finally(queue: .main) { future in
            // always executed, no matter the state of the previous future or how the chain did perform
            switch future.state {
            case .result(let value):
                print(String(describing: value))
            case .error(let err):
                print(String(describing: err))
            case .cancelled:
                print("future is in a cancelled state")
            case .unresolved:
                print("this really cannot be if any chaining block is executed")
            }
    }
}

//: This method acts as a wrapper of a generic GET request to an API

func getData(request: URLRequest) -> Future<Data> {
    print(#function)
    print("request: " + String(describing: request))
    let promise = Promise<Data>()
    // async code retrieving the data here
    let data = "[{\"key\":\"value\"}]".data(using: .utf8)!
    promise.setResult(data)
    return promise.future
}

//: This method parses a result retrieved from an API as Data

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
    return promise.future.onError() {error in
        // handle/log error
    }
}

struct FooBar {
    let value: String
}

//: This method maps the previously parsed data to domain-specific object(s)

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

basicExample()
