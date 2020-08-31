/*
 AsyncBlockOperation.swift
 
 Copyright ©2019 Kazuki Miura. All rights reserved.
*/

import Foundation


public typealias AsyncBlock = (AsyncBlockOperation) -> Void


final public class AsyncBlockOperation: AsyncOperation<AsyncOperationSuccess> {
	
	// MARK: Property
	
	/// Block associated with this operation
	public let block: AsyncBlock
	
	// MARK: Instance
	
	/**
		Initialize the receiver with block
		
		- parameters:
			- block: Block associated with the receiver
	*/
	public init(block: @escaping AsyncBlock) {
		self.block = block
	}
	
	// MARK: Operation
	
	public override func didStartExecuting() {
		self.block(self)
	}
}
