//
//  MIAssetPickerViewDelegate.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import UIKit
import Photos.PHAsset

/// Protocol representing asset picker view actions.
protocol MIAssetPickerViewDelegate: NSObjectProtocol {
	
	/// Invoked when user select media in asset picker.
	///
	/// - Parameter asset: selected asset
	func didSelect(asset: PHAsset)
	
	/// Invoked when user deselect media in asset picker. This method will also invoked when media get's delted from photo library.
	///
	/// - Parameter asset: Deselected asset
	func didDeselect(asset: PHAsset)

	/// Invoked when user select media in asset picker.
	///
	/// - Parameter asset: Selected media
	func didSelectMedia(_ asset: MIAsset)

	/// Invoked when asset library update media.
	///
	/// - Parameter assets: Updated assets
	func didUpdate(assets: [PHAsset])
}
