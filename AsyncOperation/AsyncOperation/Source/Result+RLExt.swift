/*
 Result+RLExt.swift
 
 Copyright ©2019 Kazuki Miura. All rights reserved.
*/

import Foundation


extension Swift.Result {
	var isSuccess: Bool {
		if case .success = self {
			return true
		}
		return false
	}
	var isFailure: Bool {
		if case .failure = self {
			return true
		}
		return false
	}
}
