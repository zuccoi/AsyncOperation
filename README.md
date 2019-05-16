# AsyncOperation

Generic subclass of Operation to get result asynchronously.

## Usage

```Swift
// Define success type
struct MyOperationSuccess {
    // …
}

// Make subclass of AsyncOperation whose success type is `MyOperationSuccess`
class MyOperation: AsyncOperation<MyOperationSuccess> {
    // …
    
    override func didStartExecuting() {
        // Do something…
        // When completed, call `self.complete()` with `MyOperationSuccess` instance
        // When failed, call `self.fail()` with `Error`
    }
}

// Make `MyOperation` instance
let op = MyOperation()
// Start the operation with `didEndBlock` which is called when the operation is cancelled or finished. Alternatively, you can add the operation into `OperationQueue`.
op.start {
    do {
        let result = try op.getResult() // Type of 'result' is `MyOperationSuccess`
        // Do something with result…
    } catch AsyncOperationError.cancelled(let canceller) {
        // Handle cancellation…
    } catch {
        // Handle other errors…
    }
}
```

## More
`AsyncBlockOperation` is provided to make an operation with block.

## Requirements

- Swift 5.0 or later
- iOS 11.0.1 or later
- Mac OS T.B.D.
- watchOS T.B.D.
- tvOS T.B.D.

## Installation

#### [Carthage](https://github.com/Carthage/Carthage)
Not supported yet.

#### [CocoaPods](https://github.com/cocoapods/cocoapods)

- Insert `pod 'ZUAsyncOperation'` to your Podfile.
- Run `pod install`.

#### Manually
Copy files under Source folder to your project (e.g. AsyncOperation.swift).

## License
MIT.
