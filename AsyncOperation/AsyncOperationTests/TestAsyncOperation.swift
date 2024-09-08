/*
 TestAsyncOperation.swift
 
 Copyright ©2019 Kazuki Miura. All rights reserved.
*/

import Foundation
import AsyncOperation


struct TestAsyncOperationSuccess {
	var startDate: Date
	var endDate: Date
}


enum TestAsyncOperationError: AsyncOperationError {
	case missingResult
	case cancelled(AsyncOperationCanceller)
	case tooLong
	
	static var missingResultError: Self = .missingResultError
	static func cancelledError(_ canceller: AsyncOperationCanceller) -> Self { .cancelled(canceller) }
	var isCancelledError: Bool {
		guard case .cancelled = self else { return false }
		return true
	}
}

class TestAsyncOperation: AsyncOperation<TestAsyncOperationSuccess, TestAsyncOperationError> {
	
	static let maxTimeInterval: TimeInterval = 3
	let timeInterval: TimeInterval
	
	init(timeInterval: TimeInterval) {
		self.timeInterval = timeInterval
		super.init()
	}
	
	deinit {
		NSLog("\(type(of: self)).\(#function) -- line.\(#line)")
	}
	
	override func cancel(canceller: AsyncOperationCanceller) {
		super.cancel(canceller: canceller)
		self.finish(self.result)
	}
	
	override func didStartExecuting() {
		let startDate = Date()
		DispatchQueue.main.asyncAfter(deadline: .now() + self.timeInterval) { [weak self] in
			guard let self = self else { return }
			if self.isCancelled {
				self.finish(self.result)
				return
			}
			self.complete(TestAsyncOperationSuccess(startDate: startDate, endDate: Date()))
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + type(of: self).maxTimeInterval) { [weak self] in
			guard let self = self else { return }
			if self.isCancelled {
				self.finish(self.result)
				return
			}
			self.fail(.tooLong)
		}
	}
}
