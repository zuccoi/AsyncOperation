/*
 Result+RLExt.swift
 
 Copyright ©2019 Kazuki Miura. All rights reserved.
*/

import Foundation


extension Swift.Result {
	/// Whether if it is success
	var isSuccess: Bool {
		if case .success = self {
			return true
		}
		return false
	}
	/// Whether if it is fail
	var isFailure: Bool {
		if case .failure = self {
			return true
		}
		return false
	}
}
