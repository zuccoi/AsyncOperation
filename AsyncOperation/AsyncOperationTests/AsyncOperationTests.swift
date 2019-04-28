/*
 AsyncOperationTests.swift
 
 Copyright ©2019 Kazuki Miura. All rights reserved.
*/

import XCTest
@testable import AsyncOperation


class AsyncOperationTests: XCTestCase {
	
	func test_didEndBlockWillBeCalledWhenCompletion() {
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
	
	func test_didEndBlockWillReleasedAfterExecution() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		let op = TestAsyncOperation(timeInterval: 1)
		op.start {
			exp.fulfill()
		}
		
		self.waitForExpectations(timeout: 2) { error in
			XCTAssertNil(error, "ERROR: \(error!)")
			XCTAssertNil(op.didEndBlock)
		}
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
			} catch TestAsyncOperation.Error.tooLong {
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
			} catch AsyncOperationError.cancelled(let canceller) {
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
	
	func test_canellerWillBeDefinedEvenIfCancelWasCalled() {
		let expDesc = "\(type(of: self)).\(#function) \(#line)"
		let exp = expectation(description: expDesc)
		
		let op = TestAsyncOperation(timeInterval: 1)
		op.start {
			do {
				_ = try op.getResult()
			} catch AsyncOperationError.cancelled(let canceller) {
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
}
