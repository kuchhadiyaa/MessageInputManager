//
//  ConversationDetailView.swift
//  MessageInputManager_Example
//
//  Created by Akshay Kuchhadiya on 23/08/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import MessageInputManager

class ConversationDetailView: UIView {

	// MARK: - Variables
	let messageInputView:MIMessageInputView = MIMessageInputView()
	
	// MARK: - Life cycle methods
	
	override var canBecomeFirstResponder: Bool{
		return true
	}
	override var inputAccessoryView: UIView?{
		return messageInputView
	}

}
