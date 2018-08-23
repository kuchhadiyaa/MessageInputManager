//
//  MIAssetsManagerDelegate.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import Foundation
import Photos.PHAsset

/// Protocol representing asset manager actions.
protocol MIAssetsManagerDelegate: NSObjectProtocol {
	
	/// Invoked when asset manager detect assets insertion in photos library.
	///
	/// - Parameters:
	///   - manager: Assets manager object
	///   - assets: New Assets inserted in library
	///   - indexPaths: IndexPaths of new inserted assets
	func assetManager(_ manager: MIAssetsManager, insertedAssets assets: [PHAsset], atIndexPaths indexPaths: [IndexPath])
	
	/// Invoked when asset manager detect assets updation in photos library.
	///
	/// - Parameters:
	///   - manager: Assets manager object
	///   - assets: Assets updated in library
	///   - indexPaths: IndexPaths of updated assets
	func assetManager(_ manager: MIAssetsManager, updatedAssets assets: [PHAsset], atIndexPaths indexPaths: [IndexPath])
	
	/// Invoked when asset manager detect assets removal in photos library.
	///
	/// - Parameters:
	///   - manager: Assets manager object
	///   - assets: Removed assets in library
	///   - indexPaths: IndexPaths of removed assets
	func assetManager(_ manager: MIAssetsManager, removedAssets assets: [PHAsset], atIndexPaths indexPaths: [IndexPath])
	
	/// This will be invoked when asset manager can not determine the changes and hence everhthing to be reloaded.
	///
	/// - Parameter manager: Assets manager object
	func assetManagerReloadAlbum(_ manager: MIAssetsManager)
	
	/// Invoked when asset manager detect change in authorization.
	///
	/// - Parameters:
	///   - manager: Assets manager object
	///   - oldStatus: Old authorization status
	///   - newStatus: New authorization statu
	func assetManager(_ manager: MIAssetsManager, authorizationStatusChanged oldStatus: PHAuthorizationStatus, newStatus: PHAuthorizationStatus)
}
