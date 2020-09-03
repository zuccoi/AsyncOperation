/*
 AsyncBlockOperation.swift
 
 Copyright ©2019 Kazuki Miura. All rights reserved.
*/

import Foundation


public typealias AsyncBlock = (AsyncBlockOperation) -> Void


final public class AsyncBlockOperation: AsyncOperation<AsyncOperationSuccess> {
	
	// MARK: Property
	
	/// Block associated with this operation
	private(set) var block: AsyncBlock?
	
	// MARK: Instance
	
	/**
		Initialize the receiver with block
		
		- parameters:
			- queuePriority: The execution priority of the operation in an operation queue
			- block: Block associated with the receiver
	*/
	public init(queuePriority: Operation.QueuePriority = .normal, block: @escaping AsyncBlock) {
		self.block = block
		super.init()
		self.queuePriority = queuePriority
	}
	
	// MARK: Operation
	
	public override func didStartExecuting() {
		super.didStartExecuting()
		guard let block = self.block else {
			self.complete()
			return
		}
		block(self)
	}
	
	public override func didStopExecuting() {
		self.block = nil
		super.didStopExecuting()
	}
}
