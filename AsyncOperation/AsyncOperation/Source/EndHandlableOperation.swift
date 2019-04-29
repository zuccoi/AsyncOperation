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
	
	// MARK: -- Instance
	
	public override init() {
		super.init()
		self.addObserver(self, forKeyPath: #keyPath(EndHandlableOperation.isCancelled), options: [.old, .new], context: nil)
		self.addObserver(self, forKeyPath: #keyPath(EndHandlableOperation.isFinished), options: [.old, .new], context: nil)
	}
	
	deinit {
		self.removeObserver(self, forKeyPath: #keyPath(EndHandlableOperation.isCancelled))
		self.removeObserver(self, forKeyPath: #keyPath(EndHandlableOperation.isFinished))
	}
	
	// MARK: -- Action
	
	private func executeDidEndBlock() {
		self.didEndBlock?()
		self.didEndBlock = nil
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
	
	override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard
			let keyPath = keyPath,
			let change = change,
			let object = object as? EndHandlableOperation, object === self
		else {
			return
		}
		switch keyPath {
		case #keyPath(EndHandlableOperation.isCancelled), #keyPath(EndHandlableOperation.isFinished):
			guard
				let new = (change[NSKeyValueChangeKey.newKey] as? NSNumber)?.boolValue, new == true,
				let old = (change[NSKeyValueChangeKey.oldKey] as? NSNumber)?.boolValue, old == false
			else {
				return
			}
			self.executeDidEndBlock()
		default: break
		}
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
