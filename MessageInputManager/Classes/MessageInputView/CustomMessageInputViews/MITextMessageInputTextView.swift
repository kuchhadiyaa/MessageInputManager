//
//  MITextMessageInputTextView.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import UIKit

/// Custom text view which determines scroling ability based on content height. When scroll is enabled it will return fix intrinsic height and else dynamic height based on content so content become visible.
class MITextMessageInputTextView: UITextView {

	// MARK: - Life cycle methods
	
	override var intrinsicContentSize: CGSize{
		
		/// Calculate if textview size exceeds 150 then enable scroll and return size with 150 height else return height less than 150 and disable scroll. this will increase size of textview till 150 and then allow scroll to make text visible.
		var selfSize: CGSize = frame.size
		let messageInputViewSize = sizeThatFits(CGSize(width: bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
		if messageInputViewSize.height <= 150 {
			isScrollEnabled = false
			selfSize.height = messageInputViewSize.height
		} else {
			isScrollEnabled = true
			selfSize.height = 150
		}
		return selfSize
	}
}
