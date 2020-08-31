/*
 AsyncOperation.swift
 
 Copyright ©2019 Kazuki Miura. All rights reserved.
*/

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#endif


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


open class AsyncOperation<Success>: Operation {
	public typealias Failure = Swift.Error
	public typealias Result = Swift.Result<Success, Failure>
	
	// MARK: Property
	
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
	
	/// Status of this operation
	private(set) var status: State = State.waiting {
		willSet {
			let oldValue = self.status
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
			switch self.status {
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
	
#if os(iOS) || os(tvOS)
	private var backgroundTaskID: UIBackgroundTaskIdentifier?
	private var application: UIApplication?
#endif
	
	/// Flag that indicates whether this operation succeeded
	open var isCompleted: Bool {
		return self.result?.isSuccess ?? false
	}
	
	open override var isReady: Bool {
		if self.status == .waiting {
			return super.isReady
		} else {
			return self.status == .ready
		}
	}
	
	open override var isExecuting: Bool {
		if self.status == .waiting {
			return super.isExecuting
		} else {
			return self.status == .executing
		}
	}
	
	open override var isFinished: Bool {
		if self.status == .waiting {
			return super.isFinished
		} else {
			return self.status == .finished
		}
	}
	
	open override var isCancelled: Bool {
		return self.status == .cancelled || {
			switch self.error {
			case .some(AsyncOperationError.cancelled(_)): return true
			default: return false
			}
		}()
	}
	
	open override var isAsynchronous: Bool {
		return true
	}
	
	// MARK: Background Task
	
#if os(iOS) || os(tvOS)
	@discardableResult public func beginBackgroundTask(on app: UIApplication) -> Self {
		if self.backgroundTaskID != nil {
			return self
		}
		self.application = app
		self.backgroundTaskID = app.beginBackgroundTask(withName: self.name, expirationHandler: {[weak self] in
			guard let self = self else { return }
			self.cancel(canceller: .system)
		})
		return self
	}
	
	private func endBackGroundTask() {
		if let backgroundTaskID = self.backgroundTaskID,
			let app = self.application
		{
			app.endBackgroundTask(backgroundTaskID)
			self.backgroundTaskID = nil
		}
	}
	
	deinit {
		self.endBackGroundTask()
	}
#endif
	
	// MARK: Operation
	
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
		let completionBlock = self.completionBlock
		self.completionBlock = nil
		self.result = result
		self.status = .finished
		completionBlock?()
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
		// Check status
		if self.status == .finished || self.status == .cancelled {
			return
		}
		
		// Cancel
		self.result = Result.failure(AsyncOperationError.cancelled(canceller))
		self.status = .cancelled
		super.cancel()
	}
	
	open override func cancel() {
		self.cancel(canceller: .unknown)
	}
	
	/**
		Start the receiver with specified completionBlock
		
		- parameters:
			- completionBlock: Block which will be set as completionBlock of the receiver
	*/
	open func start(completionBlock: (() -> Void)?) {
		self.completionBlock = completionBlock
		self.start()
	}
	
	open override func start() {
		if self.isCancelled {
			self.finish(.failure(self.error ?? AsyncOperationError.cancelled(.middleware)))
			return
		}
		if !self.isReady {
			NSLog("Cannot start operation cos' it is not ready to start")
			return
		}
		if self.isFinished {
			self.finish(self.result)
			return
		}
		type(of: self).dispatchQueue.async {
			self.main()
		}
	}
	
	open override func main() {
		if self.isCancelled {
			self.finish(.failure(self.error ?? AsyncOperationError.cancelled(.middleware)))
			return
		}
		if self.isFinished {
			self.finish(self.result)
			return
		}
		self.status = .executing
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


extension OperationQueue {
	/**
		Add AsyncOperation with specified completionBlock
		
		- parameters:
			- op: Operation to add
			- completionBlock: Block which will be set as completionBlock of op
	*/
	open func addOperation(_ op: Operation, completionBlock: (() -> Void)?) {
		op.completionBlock = completionBlock
		self.addOperation(op)
	}
}
