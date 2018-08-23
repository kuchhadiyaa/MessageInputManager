//
//  MIAsset.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import Foundation
import UIKit

/// Message Input media asset. This will be used instead PHAsset in camera capture or earlier version of iOS 10 where image selection from camera,library does not provide PHAsset.
class MIAsset: NSObject {
	
	/// UIImage representing assets data.
	var image: UIImage
	
	/// URL of Asset. If asset is video or live photo.
	var assetURL: URL?
	
	/// Type of asset.
	var assetType: AssetType
	
	/// Duration in case of media type is video
	var duration: TimeInterval = 0.0
	
	// MARK: - Life cycle methods
	
	init(image:UIImage,type:AssetType) {
		self.image = image
		self.assetType = type
	}
}

/// MessageInput Asset types.
///
/// - video: Video
/// - livePhoto: Live Photo
/// - photo: Photo
enum AssetType : Int {
	//Asset type video
	case video
	//Asset type live photo
	case livePhoto
	//Asset type photo.
	case photo
}

