//
//  MIAssetsManager.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import Foundation
import Photos

/// MIAssetsManager is responsible for representing the assets in camera roll album. This observs changes in library and notifies delegates of change if any.
class MIAssetsManager:NSObject {
	
	// MARK: - Variables
	
	/// Asset cache size for asset List. 
	var assetCacheSize:CGSize = CGSize.zero
	
	/// Delegate who which to be notified of assets changes.
	weak var delegate:MIAssetsManagerDelegate?
	
	// MARK: - Internal variables
	
	/// Image cache manager
	fileprivate var imageManager = PHCachingImageManager()
	/// All assets in Asset collection.
	fileprivate var assetsArray: [PHAsset] = []
	/// Fetch result for asetcollection
	fileprivate var fetchResult: PHFetchResult<PHAsset>?
	/// Assetcollection for camera roll album
	fileprivate var cameraRollAssetCollection: PHAssetCollection?
	/// Represents if already fetched albums of not.
	fileprivate var isAlbumFetched = false
	/// Current authorization statu
	fileprivate var authorizationStatus = PHPhotoLibrary.authorizationStatus()
	
	// MARK: - Life cycle methods
	
	override init() {
		super.init()
		initializeAssets()
	}
}

// MARK: - Data source methods
extension MIAssetsManager {
	
	/// Number of assets in collection
	///
	/// - Returns: assets count
	func numberOfAssets() -> Int {
		//Return Asset count
		return assetsArray.count
	}
	
	/// Request image for given asset size and degradation options. this will notify image fetch via completion handler. You can cancel this request before it completion by calling cancelImagerRequest.
	/// Completion block will be invoked multiple times depending on image quality.
	///
	/// - Parameters:
	///   - asset: Asset for which image is required
	///   - size: Size of Image
	///   - isDegraded: Require degraded image. this affects performance
	///   - completionHandler: Completion handler invoked when image manager returns image
	/// - Returns: returns Reqest ID which can be used to cancel existing request
	func requestImage(for asset: PHAsset, size: CGSize, isNeededDegraded isDegraded: Bool, completionHander completionHandler: @escaping (UIImage?, Bool) -> Void) -> PHImageRequestID {
		let requestID = imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: nil, resultHandler: { result, info in
			let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
			DispatchQueue.main.async(execute: {
				completionHandler(result, isDegraded)
			})
		})
		return requestID
	}
	
	/// Cancels any existing image fetch request.
	///
	/// - Parameter requestID: Request ID
	func cancel(imageRequest requestID: PHImageRequestID) {
		imageManager.cancelImageRequest(requestID)
	}
}

// MARK: - Indexing and Caching methods
extension MIAssetsManager {
	
	/// Returns asset at given index if index is in range of array size else returns nil
	///
	/// - Parameter index: Index
	/// - Returns: Asset if index is valid
	func asset(at index: Int) -> PHAsset? {
		if index < assetsArray.count {
			return assetsArray[index]
		}
		return nil
	}
	
	/// Returns index of given asset.
	///
	/// - Parameter asset: Asset object
	/// - Returns: Index of given asset
	func index(of asset: PHAsset) -> Int? {
		return assetsArray.index(of: asset)
	}
	
	/// Start caching given assets for given size.
	///
	/// - Parameters:
	///   - assets: Assets to be cached
	///   - size: Size of cached assets
	func startCachingImages(for assets: [PHAsset], for size: CGSize) {
		imageManager.startCachingImages(for: assets, targetSize: size, contentMode: .aspectFill, options: nil)
	}
	
	/// Stop caching existing cache request if any for given assets and size
	///
	/// - Parameters:
	///   - assets: Cached assets
	///   - size: Previous cached asset size
	func stopCachingImages(for assets: [PHAsset], for size: CGSize) {
		imageManager.stopCachingImages(for: assets, targetSize: size, contentMode: .aspectFill, options: nil)
	}
}

// MARK: - Helper internal methods extention
extension MIAssetsManager {
	
	/// Initialize assets by image manager.
	fileprivate final func initializeAssets() {
		registerObserver()
		imageManager = PHCachingImageManager()
		authorizationStatus = PHPhotoLibrary.authorizationStatus()
		authorization({ [weak self] status in
			self?.authorizationStatus = PHPhotoLibrary.authorizationStatus()
			if status {
				self?.fetchAlbum()
			} else {
				self?.clearAlbum()
			}
		})
	}
	
	/// Fetch Camera roll album.
	fileprivate final func fetchAlbum() {
		if !isAlbumFetched {
			isAlbumFetched = true
			let fetchResultCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
			guard let assetCollection = fetchResultCollection.firstObject else {return}
			cameraRollAssetCollection = assetCollection
			
			let fetchOptions = PHFetchOptions()
			fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
			fetchResult = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
			let indexSet = NSIndexSet(indexesIn: NSRange(location: 0, length: fetchResult!.count))
			assetsArray = fetchResult!.objects(at: indexSet as IndexSet)
		}
	}
	
	/// Clear fetched album and assets.
	fileprivate final func clearAlbum() {
		unregisterObserver()
		imageManager.stopCachingImagesForAllAssets()
		assetsArray.removeAll()
		fetchResult = nil
		cameraRollAssetCollection = nil
		isAlbumFetched = false
	}
	
	/// Determins authorization. if not determined then will ask for it.
	///
	/// - Parameter completionHandler: Invoked after permission has been determined.
	fileprivate final func authorization(_ completionHandler: @escaping (Bool) -> Void) {
		if PHPhotoLibrary.authorizationStatus() == .authorized {
			completionHandler(true)
		} else {
			PHPhotoLibrary.requestAuthorization({ status in
				DispatchQueue.main.async(execute: {
					switch status {
					case .authorized:
						completionHandler(true)
					default:
						completionHandler(false)
					}
				})
			})
		}
	}
	
	/// Register self as objserver for photolibrary.
	fileprivate final func registerObserver() {
		PHPhotoLibrary.shared().register(self)
	}
	
	/// Unregister self as photolibarary observer.
	fileprivate final func unregisterObserver() {
		PHPhotoLibrary.shared().unregisterChangeObserver(self)
	}
	
	/// Checks and notifies if authorization changes from previous state. If authorization is authorized then this will fetch album (if previously not fetched) else clear fetched data.
	///
	/// - Returns: Return true if current authorization is authorized.
	fileprivate final func notifyIfAuthorizationStatusChanged() -> Bool {
		let newStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
		if newStatus == .authorized {
			if !isAlbumFetched {
				fetchAlbum()
			}
		} else {
			clearAlbum()
		}
		if newStatus != authorizationStatus {
			delegate?.assetManager(self, authorizationStatusChanged: authorizationStatus, newStatus: newStatus)
		}
		authorizationStatus = newStatus
		return authorizationStatus == .authorized
	}
}

// MARK: - Asset manager extention for PhotoLibrary change observer
extension MIAssetsManager:PHPhotoLibraryChangeObserver {
	
	@objc func photoLibraryDidChange(_ changeInstance: PHChange) {
		if notifyIfAuthorizationStatusChanged() {
			syncronizeAssets(for: changeInstance)
		}
	}
	
	/// Determines assets changes and notify delegates.
	///
	/// - Parameter changeInstance: Change instance
	fileprivate final func syncronizeAssets(for changeInstance:PHChange){
		guard let fetchResult = fetchResult else {return}
		guard let assetsChangeDetail: PHFetchResultChangeDetails<PHAsset> = changeInstance.changeDetails(for: fetchResult) else {return}
		self.fetchResult = assetsChangeDetail.fetchResultAfterChanges
		// reload if hasIncrementalChanges is false
		if assetsChangeDetail.hasIncrementalChanges{
			//Sync removed assets first.
			if let removedAssetsIndexSet = assetsChangeDetail.removedIndexes {
				let removedAssets = assetsChangeDetail.removedObjects
				var removedAssetsIndexPath:[IndexPath] = []
				removedAssetsIndexSet.enumerated().forEach { (offset,element) in
					let asset = assetsChangeDetail.fetchResultBeforeChanges[element]
					if let index = self.assetsArray.index(of: asset) {
						self.assetsArray.remove(at: index)
						removedAssetsIndexPath.append(IndexPath(row: element + 3, section: 0))
					}
				}
				stopCachingImages(for: removedAssets, for: assetCacheSize)
				//Notify of remove item
				notifySubscriber({ manager in
					manager.delegate?.assetManager(manager, removedAssets: removedAssets, atIndexPaths: removedAssetsIndexPath)
				})
			}
			//Sync inserted assets.
			if let insertedAssetsIndexSet = assetsChangeDetail.insertedIndexes {
				let insertedAssets = assetsChangeDetail.insertedObjects
				var insertedAssetsIndexPath:[IndexPath] = []
				insertedAssetsIndexSet.enumerated().forEach { (index,element) in
					let asset = assetsChangeDetail.fetchResultAfterChanges[element]
					self.assetsArray.insert(asset, at: element)
					insertedAssetsIndexPath.append(IndexPath(row: element + 3, section: 0))
				}
				startCachingImages(for: insertedAssets, for: assetCacheSize)
				//Notify subscriber
				notifySubscriber({ manager in
					manager.delegate?.assetManager(manager, insertedAssets: insertedAssets, atIndexPaths: insertedAssetsIndexPath)
				})
			}
			//Sync updated assets
			if let updatedAssetsIndexSet = assetsChangeDetail.changedIndexes{
				let updatedAssets = assetsChangeDetail.changedObjects
				var reloadAssetsIndexPath:[IndexPath] = []
				updatedAssetsIndexSet.enumerated().forEach { (index,element) in
					reloadAssetsIndexPath.append(IndexPath(row: element + 3, section: 0))
				}
				stopCachingImages(for: updatedAssets, for: assetCacheSize)
				startCachingImages(for: updatedAssets, for: assetCacheSize)
				notifySubscriber({ manager in
					manager.delegate?.assetManager(manager, updatedAssets: updatedAssets, atIndexPaths: reloadAssetsIndexPath)
				})
			}
		}else{
			// reload if hasIncrementalChanges is false
			let indexSet = NSIndexSet(indexesIn: NSRange(location: 0, length: fetchResult.count))
			assetsArray = fetchResult.objects(at: indexSet as IndexSet)
			notifySubscriber({ manager in
				manager.delegate?.assetManagerReloadAlbum(manager)
			})
		}
	}
	
	fileprivate func notifySubscriber(_ action: @escaping (MIAssetsManager) -> Void) {
		DispatchQueue.main.async(execute: { [weak self] in
			guard let weakSelf = self else {return}
			action(weakSelf)
		})
	}

}

