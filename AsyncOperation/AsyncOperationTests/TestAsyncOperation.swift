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


class TestAsyncOperation: AsyncOperation<TestAsyncOperationSuccess> {
	
	enum Error: Int, Swift.Error {
		case tooLong
		
		var _code: Int {
			switch self {
			case .tooLong: return 0
			}
		}
	}
	
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
			self.fail(Error.tooLong)
		}
	}
}
