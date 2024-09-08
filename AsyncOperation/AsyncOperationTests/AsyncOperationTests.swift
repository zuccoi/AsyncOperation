/*
 AsyncOperationTests.swift
 
 Copyright ©2019 Kazuki Miura. All rights reserved.
*/

import XCTest
@testable import AsyncOperation


class AsyncOperationTests: XCTestCase {
	
	func test_completionBlockIsCalledWhenCancelledBeforeStart() {
		var called = false
		let op = TestAsyncOperation(timeInterval: 1)
		op.completionBlock = {
			called = true
		}
		op.cancel()
		XCTAssertTrue(called)
	}
	
	func test_completionBlockWillBeCalledWhenCompleted() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		var completed = false
		var endDate: Date?
		let op = TestAsyncOperation(timeInterval: 1)
		let startDate = Date()
		op.start {
			completed = true
			endDate = Date()
			exp.fulfill()
		}
		
		self.waitForExpectations(timeout: 2) { error in
			XCTAssertNil(error, "ERROR: \(error!)")
			XCTAssertTrue(completed)
			XCTAssertNotNil(endDate)
			if let endDate = endDate {
				XCTAssertTrue(endDate.timeIntervalSince(startDate) > 1)
			}
		}
	}
	
	func test_completionBlockWillBeReleasedWhenCompleted() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		let op = TestAsyncOperation(timeInterval: 1)
		op.start {
			exp.fulfill()
		}
		
		self.waitForExpectations(timeout: 2) { error in
			XCTAssertNil(error, "ERROR: \(error!)")
			XCTAssertNil(op.completionBlock)
		}
	}
	
	func test_completionBlockWillBeReleasedWhenCancelled() {
		let op = TestAsyncOperation(timeInterval: 1)
		op.completionBlock = {}
		XCTAssertNotNil(op.completionBlock)
		op.cancel()
		XCTAssertNil(op.completionBlock)
	}
	
	func test_success() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		let op = TestAsyncOperation(timeInterval: 1)
		op.start {
			do {
				let result = try op.getResult()
				XCTAssertTrue(result.endDate.timeIntervalSince(result.startDate) > 1)
				exp.fulfill()
			} catch {}
		}
		
		self.waitForExpectations(timeout: 2) { error in
			XCTAssertNil(error, "ERROR: \(error!)")
		}
	}
	
	func test_failure() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		let op = TestAsyncOperation(timeInterval: TestAsyncOperation.maxTimeInterval + 1)
		op.start {
			do {
				_ = try op.getResult()
			} catch TestAsyncOperationError.tooLong {
				exp.fulfill()
			} catch {}
		}
		
		self.waitForExpectations(timeout: TestAsyncOperation.maxTimeInterval + 2) { error in
			XCTAssertNil(error, "ERROR: \(error!)")
		}
	}
	
	func test_cancelled() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		let op = TestAsyncOperation(timeInterval: 1)
		op.start {
			do {
				_ = try op.getResult()
			} catch TestAsyncOperationError.cancelled(let canceller) {
				XCTAssertEqual(canceller, .application)
				exp.fulfill()
			} catch {}
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { 
			op.cancel(canceller: .application)
		}
		
		self.waitForExpectations(timeout: 2) { error in
			XCTAssertNil(error, "ERROR: \(error!)")
		}
	}
	
	func test_hasLocalizedDescriptionOfError() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		let op = TestAsyncOperation(timeInterval: 1)
		op.start {
			do {
				_ = try op.getResult()
			} catch let error as NSError {
				let desc = error.localizedDescription
				XCTAssertTrue(!desc.isEmpty)
				exp.fulfill()
			} catch {}
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { 
			op.cancel(canceller: .application)
		}
		
		self.waitForExpectations(timeout: 2) { error in
			XCTAssertNil(error, "ERROR: \(error!)")
		}
	}
	
	func test_cancellerWillBeDefinedEvenIfCancelWasCalled() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		let op = TestAsyncOperation(timeInterval: 1)
		op.start {
			do {
				_ = try op.getResult()
			} catch TestAsyncOperationError.cancelled(let canceller) {
				XCTAssertEqual(canceller, .unknown)
				exp.fulfill()
			} catch {}
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { 
			op.cancel()
		}
		
		self.waitForExpectations(timeout: 2) { error in
			XCTAssertNil(error, "ERROR: \(error!)")
		}
	}
	
	func test_operationIsExecutableWithOperationQueue() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		let queue = OperationQueue()
		queue.maxConcurrentOperationCount = 1
		
		let op = TestAsyncOperation(timeInterval: 1)
		queue.addOperation(op) {
			do {
				_ = try op.getResult()
				exp.fulfill()
			} catch {}
		}
		
		self.waitForExpectations(timeout: 2) { error in
			XCTAssertNil(error, "ERROR: \(error!)")
		}
	}
	
	func test_operationIsRemovedFromQueueAfterCacel() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		// Make queue
		let queue = OperationQueue()
		queue.maxConcurrentOperationCount = 1
		
		// Add operation to the queue
		let op = TestAsyncOperation(timeInterval: 1)
		queue.addOperation(op) {}
		XCTAssertEqual(queue.operationCount, 1)
		
		// Add another operation
		let op2 = TestAsyncOperation(timeInterval: 1)
		queue.addOperation(op2) {
			do {
				_ = try op2.getResult()
				exp.fulfill()
			} catch {}
		}
		XCTAssertEqual(queue.operationCount, 2)
		
		// Cancel the operation
		op.cancel(canceller: .application)
		
		self.waitForExpectations(timeout: 10) { error in
			XCTAssertNil(error, "ERROR: \(error!)")
			XCTAssertEqual(queue.operationCount, 0)
		}
	}
	
	func test_notStartedOperationIsRemovedFromQueueAfterCancel() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		// Make queue
		let queue = OperationQueue()
		queue.maxConcurrentOperationCount = 1
		
		// Add operation to the queue
		let op1 = TestAsyncOperation(timeInterval: 1)
		queue.addOperation(op1) {
			do {
				_ = try op1.getResult()
				exp.fulfill()
			} catch {}
		}
		XCTAssertEqual(queue.operationCount, 1)
		
		// Add another operation
		var op2WasCancelled = false
		let op2 = TestAsyncOperation(timeInterval: 1)
		queue.addOperation(op2) {
			do {
				_ = try op2.getResult()
			} catch TestAsyncOperationError.cancelled(_) {
				op2WasCancelled = true
			} catch {}
		}
		XCTAssertEqual(queue.operationCount, 2)
		
		// Cancel op2
		op2.cancel(canceller: .application)
		
		self.waitForExpectations(timeout: 10) { error in
			XCTAssertNil(error, "ERROR: \(error!)")
			XCTAssertTrue(op2WasCancelled)
			XCTAssertEqual(queue.operationCount, 0)
			for anOp in queue.operations {
				switch anOp {
				case op1:
					XCTFail("op1 is NOT removed from the queue")
				case op2:
					XCTFail("op2 is NOT removed from the queue")
					XCTAssertTrue(op2.isFinished)
				default: break
				}
			}
		}
	}
}
