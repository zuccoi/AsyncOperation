# AsyncOperation

Generic subclass of Operation to get result asynchronously.

## Usage

```Swift
// Define success type
struct MyOperationSuccess {
    // …
}

// Define error type
enum MyOperationError: AsyncOperationError {
    // …
}

// Make subclass of AsyncOperation whose success type is `MyOperationSuccess` and error type is `MyOperationError`
class MyOperation: AsyncOperation<MyOperationSuccess, MyOperationError> {
    // …
    
    override func didStartExecuting() {
        // Do something…
        // When completed, call `self.complete()` with `MyOperationSuccess` instance
        // When failed, call `self.fail()` with `Error`
    }
}

// Make `MyOperation` instance
let op = MyOperation()
// Start the operation with `completionBlock`. Alternatively, you can add the operation into `OperationQueue`.
op.start {
    do {
        let result = try op.getResult() // Type of 'result' is `MyOperationSuccess`
        // Do something with result…
    } catch MyOperationError.cancelled(let canceller) {
        // Handle cancellation…
    } catch {}
        // Handle other errors…
    }
}
```

## Background Task
You can start background task for `AsyncOperation` easily.
```
let op = MyOperation()
op.beginBackgroundTask(on: UIApplication.shared).start {
    do {
        let result = try op.getResult()
        // Do something with reuslt…
    } catch MyOperationError.cancelled(let canceller) {
        // Handle cancellation…
    } catch {
        // Handle other errors…
    }
}
```
When background task is expired, the operation calls `self.cancel(canceller: .system)`

## AsyncBlockOperation
`AsyncBlockOperation` is provided to make an operation with block.

## Requirements

- Swift 5.0 or later
- iOS 11.0.1 or later
- Mac OS T.B.D.
- watchOS T.B.D.
- tvOS T.B.D.

## Installation

#### [Carthage](https://github.com/Carthage/Carthage)

- Insert `github "zuccoi/AsyncOperation"` to your Cartfile.
- Run `carthage update`.
- Link your app with `AsyncOperation.framework` in `Carthage/Build`.

#### [CocoaPods](https://github.com/cocoapods/cocoapods)

- Insert `pod 'ZUAsyncOperation'` to your Podfile.
- Run `pod install`.

#### Manually
Copy files under Source folder to your project (e.g. AsyncOperation.swift).

## License
MIT.
