/*
 EndHandlableOperationTests.swift
 
 Copyright ©2019 Kazuki Miura. All rights reserved.
*/

import XCTest
import AsyncOperation


class EndHandlableOperationTests: XCTestCase {
	
	func test_completionBlockWillNotBeCalledWhenCancelledBeforeStart() {
		var called = false
		let op = Operation()
		op.completionBlock = {
			called = true
		}
		op.cancel()
		XCTAssertFalse(called)
	}
	
	func test_didEndBlockWillBeCalledWhenCancelledBeforeStart() {
		var called = false
		let op = EndHandlableOperation()
		op.didEndBlock = {
			called = true
		}
		op.cancel()
		XCTAssertTrue(called)
	}
	
	func test_didEndBlockWillBeReleasedAfterExecution() {
		let op = EndHandlableOperation()
		op.didEndBlock = {}
		XCTAssertNotNil(op.didEndBlock)
		op.cancel()
		XCTAssertNil(op.didEndBlock)
	}
	
}
