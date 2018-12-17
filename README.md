# Promis

[![Build Status](https://app.bitrise.io/app/c860d39fa5072b30/status.svg?token=kgZIlFlJdRBIvy3xnG6gaQ&branch=master)](https://app.bitrise.io/app/c860d39fa5072b30)
[![Version](https://img.shields.io/cocoapods/v/Promis.svg?style=flat)](http://cocoapods.org/pods/Promis)
[![License](https://img.shields.io/cocoapods/l/Promis.svg?style=flat)](http://cocoapods.org/pods/Promis)
[![Platform](https://img.shields.io/cocoapods/p/Promis.svg?style=flat)](http://cocoapods.org/pods/Promis)

The easiest Future and Promises framework in Swift. No magic. No boilerplate.

## Overview

While starting from the Objective-C implementation of [JustPromises](https://github.com/justeat/JustPromises) and keeping the code minimalistic, this library adds the following:

- conversion to Swift 4
- usage of generics to allow great type inference that wasn't possible in Objective-C
- overall refactoring for fresh and modern code
- remove the unnecessary and misleading concept of Progress causing bad patterns to emerge

You can read about the theory behind Future and Promises on [Wikipedia](https://en.wikipedia.org/wiki/Futures_and_promises), here are the main things you should know to get started.

- Promises represent the promise that a task will be fulfilled in the future while the future holds the state of such resolution.
- Futures, when created are in the unresolved state and can be resolved with one of 3 states: with a result, an error, or being cancelled.
- Futures can be chained, allowing to avoid the [pyramid of doom](https://twitter.com/piscis168/status/641237956070666240) problem, clean up asynchronous code paths and simplify error handling.

Promis brags about being/having:

- Fully unit-tested and documented 💯
- Thread-safe 🚦
- Clean interface 👼
- Support for chaining ⛓
- Support for cancellation 🙅‍♂️
- Queue-based block execution if needed 🚆
- Result type provided via generics 🚀
- Keeping the magic to the minimum, leaving the code in a readable state without going off of a tangent with fancy and unnecessary design decisions ಠ_ಠ

## Alternatives

Other open-source solutions exist such as:
- [FutureKit](https://github.com/FutureKit/FutureKit)
- [PromiseKit](https://github.com/mxcl/PromiseKit)
- [JustPromises](https://github.com/justeat/JustPromises)
- [Promises](https://github.com/google/promises)

Promis takes inspiration from the Objective-C version of JustPromises developed by the iOS Team of [Just Eat](https://www.just-eat.com/) which is really concise and minimalistic, while other libraries are more weighty.

## Usage

The following example should outline the main benefits of using futures via chaining.

```swift
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
```

The functions used in the example have the following signatures:

```swift
func getData(request: URLRequest) -> Future<Data>
func parse(data: Data) -> Future<[Dictionary<String,AnyObject>]>
func map(data: [Dictionary<String,AnyObject>]) -> Future<[FooBar]>
```

Promises and Futures are parametrized leveraging the power of the generics, meaning that Swift can infer the type of the result compile type. This was a considerable limitation in the Objective-C world and we can now prevent lots of issues at build time thanks to the static typing nature of the language. The state of the future is an enum defined as follows:

```swift
enum FutureState<ResultType> {
    case unresolved
    case result(ResultType)
    case error(Error)
    case cancelled
}
```

Promises are created and resolved like so:

```swift
let promise = Promise<ResultType>()
promise.setResult(value)
// or
promise.setError(error)
// or
promise.cancel()
```

Continuation methods used for chaining are the following:

```swift
func then<NextResultType>(queue: DispatchQueue? = nil, task: @escaping (Future) -> Future<NextResultType>) -> Future<NextResultType>
func thenWithResult<NextResultType>(queue: DispatchQueue? = nil, continuation: @escaping (ResultType) -> Future<NextResultType>) -> Future<NextResultType> {
func onError(queue: DispatchQueue? = nil, continuation: @escaping (Error) -> Void) -> Future {
func finally(queue: DispatchQueue? = nil, block: @escaping (Future<ResultType>) -> Void)
```

All the functions can accept an optional `DispatchQueue` used to perform the continuation blocks.


### Best practices

Functions wrapping async tasks should follow the below pattern:

```swift
func wrappedAsyncTask() -> Future<ResultType> {

    let promise = Promise<Data>()
    someAsyncOperation() { data, error in
        // resolve the promise according to how the async operations did go
        switch (data, error) {
        case (let data?, _):
            promise.setResult(data)
        case (nil, let error?):
            promise.setError(error)
        // etc.
        }
    }
    return promise.future
}
```

You could chain an `onError` continuation before returning the future to allow in-line error handling, which I find to be a very handy pattern.

```swift
// ...
return promise.future.onError {error in
    // handle/log error
}
```

### Pitfalls

When using `then` or `thenWithResult`, the following should be taken in consideration.

```swift
...}.thenWithResult { data -> Future<NextResultType> in
    /**
    If a block is not trivial, Swift cannot infer the type of the closure and gives the error
    'Unable to infer complex closure return type; add explicit type to disambiguate'
    so you'll have to add `-> Future<NextResultType> to the block signature
    
    You can make the closure complex just by adding any extra statement (like a print).
    
    All the more reason to structure your code as done in the first given example :)
    */
    print("complex closure")
    return parse(data: data)
}
```

Please check the GettingStarted playground in the demo app to see the complete implementation of the above examples.

## Installation

### CocoaPods

Add `Promis` to your Podfile

```ruby
use_frameworks!
target 'MyTarget' do
    pod 'Promis', '~> x.y.z'
end
```

```bash
$ pod install
```

### Carthage

```ruby
github "albertodebortoli/Promis" ~> "x.y.z"
```

Then on your application target *Build Phases* settings tab, add a "New Run Script Phase". Create a Run Script with the following content:

```ruby
/usr/local/bin/carthage copy-frameworks
```

and add the following paths under "Input Files":

```ruby
$(SRCROOT)/Carthage/Build/iOS/Promis.framework
```

## Author

Alberto De Bortoli <albertodebortoli.website@gmail.com>
Twitter: [@albertodebo](https://twitter.com/albertodebo)
GitHub: [albertodebortoli](https://github.com/albertodebortoli)
website: [albertodebortoli.com](http://albertodebortoli.com)

## License

Promis is available under the Apache 2 license in respect of JustPromises which this library takes inspiration from. See the [LICENSE](LICENSE) file for more info.
