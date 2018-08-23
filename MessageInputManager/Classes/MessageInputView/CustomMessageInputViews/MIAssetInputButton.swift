//
//  MIAssetInputButton.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import UIKit

/// Custom UIButton which becomes first responder.
class MIAssetInputButton: UIButton {

	// MARK: - Variables
	
	/// Custom input view for this responder.
	weak var assetInputView:MIAssetPickerView?

	// MARK: - Lifecycle methods
	
	override var canBecomeFirstResponder: Bool{
		return true
	}
	
	override var inputView: UIView?{
		return assetInputView
	}
	
	override func willMove(toWindow newWindow: UIWindow?) {
		super.willMove(toWindow: newWindow)
		if newWindow == nil{
			isSelected = false
		}
	}
}
