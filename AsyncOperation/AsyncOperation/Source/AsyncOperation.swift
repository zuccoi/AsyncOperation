/*
 AsyncOperation.swift
 
 Copyright ©2019 Kazuki Miura. All rights reserved.
*/

import Foundation


public struct AsyncOperationSuccess {}


public enum AsyncOperationCanceller {
	case unknown
	case system
	case middleware
	case application
	case user
}


public enum AsyncOperationError: Swift.Error {
	public var _domain: String {
		return "AsyncOperationError"
	}
	case cancelled(AsyncOperationCanceller)
	case missingResult
	
	public var _code: Int {
		switch self {
		case .cancelled(let canceller):
			switch canceller {
			case .unknown: return -5
			case .system: return -4
			case .middleware: return -3
			case .application: return -2
			case .user: return -1
			}
		case .missingResult: return 1
		}
	}
}


open class AsyncOperation<Success>: EndHandlableOperation {
	public typealias Failure = Swift.Error
	public typealias Result = Swift.Result<Success, Failure>
	
	// MARK: -- Property
	
	/// Operation queue on which instance is excuted when it starts
	open class var dispatchQueue: DispatchQueue {
		return DispatchQueue.global(qos: .default)
	}
	
	public enum State: String {
		case waiting = "isWaiting"
		case ready = "isReady"
		case executing = "isExecuting"
		case finished = "isFinished"
		case cancelled = "isCancelled"
	}
	
	/// State of this operation
	private(set) var state: State = State.waiting {
		willSet {
			let oldValue = self.state
			let assert = {
				assertionFailure("Invalid change from \(oldValue) to \(newValue)")
			}
			switch newValue {
			case .waiting: assert()
			case .ready:
				if oldValue != .waiting {
					assert()
				}
			case .executing:
				switch oldValue {
				case .ready, .waiting: break
				default: assert()
				}
				self.willStartExecuting()
			case .finished:
				if oldValue == .executing {
					self.willStopExecuting()
				}
				self.willFinish()
			case .cancelled:
				if oldValue == .executing {
					self.willStopExecuting()
				}
				self.willCancel()
			}
			self.willChangeValue(forKey: State.ready.rawValue)
			self.willChangeValue(forKey: State.executing.rawValue)
			self.willChangeValue(forKey: State.finished.rawValue)
			self.willChangeValue(forKey: State.cancelled.rawValue)
		}
		didSet {
			switch self.state {
			case .waiting: break
			case .ready: break
			case .executing:
				self.didStartExecuting()
			case .finished:
				if oldValue == .executing {
					self.didStopExecuting()
				}
				self.didFinish()
			case .cancelled:
				if oldValue == .executing {
					self.didStopExecuting()
				}
				self.didCancel()
			}
			self.didChangeValue(forKey: State.cancelled.rawValue)
			self.didChangeValue(forKey: State.finished.rawValue)
			self.didChangeValue(forKey: State.executing.rawValue)
			self.didChangeValue(forKey: State.ready.rawValue)
		}
	}
	
	/// Result of this operation
	open var result: Result?
	
	/// Error obtained from result
	open var error: Swift.Error? {
		if let result = self.result {
			if case .failure(let error) = result {
				return error
			}
		}
		return nil
	}
	
	/// Flag that indicates whether this operation succeeded
	open var isCompleted: Bool {
		return self.result?.isSuccess ?? false
	}
	
	open override var isReady: Bool {
		if self.state == .waiting {
			return super.isReady
		} else {
			return self.state == .ready
		}
	}
	
	open override var isExecuting: Bool {
		if self.state == .waiting {
			return super.isExecuting
		} else {
			return self.state == .executing
		}
	}
	
	open override var isFinished: Bool {
		if self.state == .waiting {
			return super.isFinished
		} else {
			return self.state == .finished
		}
	}
	
	open override var isCancelled: Bool {
		return self.state == .cancelled
	}
	
	open override var isAsynchronous: Bool {
		return true
	}
	
	// MARK: -- Operation
	
	/// Called before isExecuting flag will be raised
	open func willStartExecuting() {}
	
	/// Called after isExecuting flag was raised
	open func didStartExecuting() {}
	
	/// Called before isExecuting flag will be down
	open func willStopExecuting() {}
	
	/// Called after isExecuting flag was down
	open func didStopExecuting() {}
	
	/// Called before isFinish flag will be raised
	open func willFinish() {}
	
	/// Called after isFinish flag was down
	open func didFinish() {}
	
	/// Called before isCancelled flag will be raised
	open func willCancel() {}
	
	/// Called after isCancelled flag was down
	open func didCancel() {}
	
	/**
		Finish this operation with specified result
		
		- parameters:
			- result: Result of this operation
	*/
	open func finish(_ result: Result?) {
		if self.state == .cancelled {
			return
		}
		self.result = result
		self.state = .finished
	}
	
	/**
		Finish this operation with specified failure
		
		- parameters:
			- failure: Error of this operation
	*/
	open func fail(_ failure: Failure) {
		self.finish(Result.failure(failure))
	}
	
	/**
		Finish this operation with specified success result
		
		- parameters:
			- success: Success of this operation
	*/
	open func complete(_ success: Success) {
		self.finish(Result.success(success))
	}
	
	/**
		Cancel this operation with specified canceller
		
		- parameters:
			- canceller: Canceller of this operation
		
		If you call cancel(), cancel(canceller: .unknown) is called.
		This function call cancel() function of superclass
	*/
	open func cancel(canceller: AsyncOperationCanceller) {
		if self.state == .finished || self.state == .cancelled {
			return
		}
		self.result = Result.failure(AsyncOperationError.cancelled(canceller))
		self.state = .cancelled
		super.cancel()
		self.completionBlock = nil
	}
	
	open override func cancel() {
		self.cancel(canceller: .unknown)
	}
	
	open override func start() {
		if self.isCancelled {
			self.finish(nil)
			return
		}
		if !self.isReady {
			NSLog("Cannot start operation cos' it is not ready to start")
			return
		}
		type(of: self).dispatchQueue.async {
			self.main()
		}
	}
	
	open override func main() {
		if !self.isCancelled && !self.isFinished {
			self.state = .executing
		}
	}
	
	/**
		Get resut of this operation
	*/
	open func getResult() throws -> Success {
		guard let result = self.result else {
			throw AsyncOperationError.missingResult
		}
		return try result.get()
	}
}


extension AsyncOperation where Success == AsyncOperationSuccess {
	/**
		Finish this operation with specified error. If error is nil, this calles complete()
		
		- parameters:
			- error: Error of this operation, or nil if it succeeded
	*/
	open func finish(withError error: Failure?) {
		if let error = error {
			self.fail(error)
		}
		else {
			complete()
		}
	}
	
	/**
		Finish this operation with success
	*/
	open func complete() {
		self.complete(Success())
	}
}
