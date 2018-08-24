//
//  MIMessageInputViewDelegate.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import Foundation


/// Protocol representing message input view actions.
public protocol MIMessageInputViewDelegate:NSObjectProtocol {
	
	/// 	When user press send button this method will be invoked. This method provides message in text view, assets selected by user and array which represents live status off for any live assets in selected assets
	/// 	It's delegate class's responsibility to manage live off assets based on provided index as it must be done while retriving origional asset data and which will be processed while sending actual message. so This method will give all assets as PHAsset and it's delegate's responsiblity to determine wether it's photo or video or live (on or off).
	///
	/// - Parameters:
	///   - message: Text message
	///   - assets: Array of assets selected by user to send. Array contains two types of assets. one is system asset PHAsset 	and other custom asset i.e. MPAsset. delegate must check that which asset current one is before using.
	///   - indexes: Indexes of Life photos and user turned them off to send as normal photo.
	func send(message: String?, selectedAssets assets: NSArray, liveOffAssetsIndexes indexes: NSArray)
}
