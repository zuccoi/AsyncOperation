/*
 EndHandlableOperation.swift
 
 Copyright ©2019 Kazuki Miura. All rights reserved.
*/

import Foundation


open class EndHandlableOperation: Operation {
	
	// MARK: -- Property
	
	/**
		Block which is executed when this operation ended -- cancelled or finished
		
		- important: This block is released after execution
	*/
	open var didEndBlock: (() -> Void)?
	
	private var isCancelledObservation: NSKeyValueObservation?
	private var isFinishedObservationn: NSKeyValueObservation?
	
	// MARK: -- Instance
	
	public override init() {
		super.init()
		let changeHandler: (EndHandlableOperation, NSKeyValueObservedChange<Bool>) -> Void = {[weak self] (op, change) in
			guard
				let self = self,
				let new = change.newValue, new == true,
				let old = change.oldValue, old == false
			else {
				return
			}
			self.executeDidEndBlock()
		}
		self.isCancelledObservation = self.observe(\EndHandlableOperation.isCancelled, options: [.new, .old], changeHandler: changeHandler)
		self.isFinishedObservationn = self.observe(\EndHandlableOperation.isFinished, options: [.new, .old], changeHandler: changeHandler)
	}
	
	// MARK: -- Action
	
	private func executeDidEndBlock() {
		self.didEndBlock?()
		self.didEndBlock = nil
		self.isCancelledObservation = nil
		self.isFinishedObservationn = nil
	}
	
	/**
		Start the receiver with specified didEndBlock
		
		- parameters:
			- didEndBlock: Block which will be set as didEndBlock of the receiver
	*/
	open func start(didEndBlock: (() -> Void)?) {
		self.didEndBlock = didEndBlock
		self.start()
	}
}


extension OperationQueue {
	/**
		Add EndHandlableOperation with specified didEndBlock
		
		- parameters:
			- op: Operation to add
			- didEndBlock: Block which will be set as didEndBlock of op -- it'll be called when the op ended
	*/
	open func addOperation(_ op: EndHandlableOperation, didEndBlock: (() -> Void)?) {
		op.didEndBlock = didEndBlock
		self.addOperation(op)
	}
}
