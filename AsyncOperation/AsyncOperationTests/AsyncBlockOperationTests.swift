/*
 AsyncBlockOperationTests.swift
 
 Copyright ©2019 Kazuki Miura. All rights reserved.
*/

import XCTest
import AsyncOperation


class AsyncBlockOperationTests: XCTestCase {
	
	enum Error: Swift.Error {
		case test
	}
	
	func test_complete() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		let op = AsyncBlockOperation(block: { op in
			let op = op
			DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
				if op.isCancelled {
					return
				}
				op.complete()
			})
		})
		op.start {
			if op.isCompleted {
				exp.fulfill()
			}
		}
		
		self.waitForExpectations(timeout: 2) { error in
			XCTAssertNil(error, "ERROR: \(error!)")
		}
	}
	
	func test_fail() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		let op = AsyncBlockOperation(block: { op in
			let op = op
			DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
				if op.isCancelled {
					return
				}
				op.fail(Error.test)
			})
		})
		op.start {
			do {
				_ = try op.getResult()
			} catch Error.test {
				exp.fulfill()
			} catch {}
		}
		
		self.waitForExpectations(timeout: 2) { error in
			XCTAssertNil(error, "ERROR: \(error!)")
		}
	}
	
	func test_cancel() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		let op = AsyncBlockOperation(block: { op in
			let op = op
			DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
				if op.isCancelled {
					op.finish(op.result)
					return
				}
				op.complete()
			})
		})
		op.start {
			do {
				_ = try op.getResult()
			} catch AsyncOperationError.cancelled(let canceller) {
				XCTAssertEqual(canceller, .application)
				exp.fulfill()
			} catch {}
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			op.cancel(canceller: .application)
		}
		
		self.waitForExpectations(timeout: 2) { error in
			XCTAssertNil(error, "ERROR: \(error!)")
		}
	}
	
	func test_operationIsExecutableWithOperationQueue() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		
		let op = AsyncBlockOperation(block: { op in
			let op = op
			DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
				if op.isCancelled {
					return
				}
				op.complete()
			})
		})
		op.completionBlock = {
			do {
				_ = try op.getResult()
				exp.fulfill()
			} catch {}
		}
		
		let queue = OperationQueue()
		queue.addOperation(op)
		
		self.waitForExpectations(timeout: 2) { error in
			XCTAssertNil(error, "ERROR: \(error!)")
		}
	}
}
