//
//  MIAssetPickerView.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import UIKit
import Photos.PHAsset
import MobileCoreServices
import AVFoundation.AVUtilities

/// MIAssetPickerView displayes and manages Assets selection using custom Camera, photo library and selection using native photo and camera pickers.
class MIAssetPickerView: UIView {

	// MARK: - Variables
	
	/// Delegate who whish to listen event's from asset picker changes.
	internal weak var delegate: MIAssetPickerViewDelegate?
	
	/// Asset manage which represent all PHAssets from Photos library.
	internal var assetsManager: MIAssetsManager = MIAssetsManager()
	
	/// Collection view representing assets
	fileprivate var assetsListCollectionView: UICollectionView?
	
	/// Size of asset in view
	fileprivate var assetCellSize = CGSize.zero
	
	/// Currently selected assets
	fileprivate var selectedAssets: [PHAsset] = []

	// MARK: - Life cycle methods
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		initiateComponents()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initiateComponents()
	}
}

// MARK: - Helper methods

extension MIAssetPickerView {
	
	/// Select asset. if already selected then does not anything.
	///
	/// - Parameter asset: Asset to be selected
	fileprivate final func select(asset: PHAsset) {
		if selectedAssets.index(of: asset) == nil {
			selectedAssets.append(asset)
			if let index = assetsManager.index(of: asset) {
				assetsListCollectionView?.selectItem(at: IndexPath(row: index + 3, section: 0), animated: true, scrollPosition: .centeredHorizontally)
			}
		}
	}
	/// Deselect any previously selected asset if any.
	///
	/// - Parameter asset: Asset object
	internal final func deselect(_ asset: PHAsset) {
		if let selectedIndex = selectedAssets.index(of: asset) {
			selectedAssets.remove(at: selectedIndex)
		}
		if let index = assetsManager.index(of: asset) {
			assetsListCollectionView?.deselectItem(at: IndexPath(row: index + 3, section: 0), animated: true)
		}
	}
	
	/// Helper to retirve assets for given indexPaths.
	///
	/// - Parameter indexPaths: Index path at which to retrive asset.
	/// - Returns: Assets for given indexPaths
	fileprivate final func getAssets(at indexPaths:[IndexPath]) -> [PHAsset] {
		var assets = [PHAsset]()
		for indexPath in indexPaths {
			if indexPath.row > 2,let asset = assetsManager.asset(at: indexPath.row - 3) {
				assets.append(asset)
			}
		}
		return assets
	}

	/// Clear all existing selection.
	internal final func clearAllSelections() {
		assetsListCollectionView?.reloadData()
		selectedAssets.removeAll()
	}
	
	/// Opens image picker for camera or Photolibrary.
	///
	/// - Parameter camera: If true opens camera picker else Library.
	fileprivate final func showMessagePicker(forSourceCamera camera: Bool) {
		let imagePickerVC = UIImagePickerController()
		imagePickerVC.delegate = self
		imagePickerVC.allowsEditing = false
		if camera {
			if UIImagePickerController.isSourceTypeAvailable(.camera) {
				imagePickerVC.sourceType = .camera
				if let aCamera = UIImagePickerController.availableMediaTypes(for: .camera) {
					imagePickerVC.mediaTypes = aCamera
				}
				//NOTE: Somehow imagepicker is not allowing to take live photos.
				//NSArray *mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeLivePhoto];
				//imagePickerVC.mediaTypes = mediaTypes;
				let vc: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
				vc?.present(imagePickerVC, animated: true)
			}
		} else {
			if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
				imagePickerVC.sourceType = .photoLibrary
				if let aLibrary = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
					imagePickerVC.mediaTypes = aLibrary
				}
				let vc: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
				vc?.present(imagePickerVC, animated: true)
			}
		}
	}
	
	/// Process media in legacy way.
	///
	/// - Parameter info: Media dictionary
	fileprivate final func processMedia(with info:[String:Any]){
		var info = info
		//If type movie then get thumb of image and set in dict as origional image key.
		var assetImage = UIImage()
		var assetType:AssetType = .photo
		let assetURL = info[UIImagePickerControllerMediaURL] as? URL
		var duration = 0.0
		if (info[UIImagePickerControllerMediaType] as? String) == kUTTypeMovie as String || (info[UIImagePickerControllerMediaType] as? String) == kUTTypeVideo as String {
			assetType = .video
			let asset = AVURLAsset(url: assetURL!, options: nil)
			let generateImg = AVAssetImageGenerator(asset: asset)
			generateImg.appliesPreferredTrackTransform = true
			duration = CMTimeGetSeconds(asset.duration)
			let midpoint: CMTime = CMTimeMakeWithSeconds(duration / 2.0, 600)
			if let refImg = try? generateImg.copyCGImage(at: midpoint, actualTime: nil){
				assetImage = UIImage(cgImage: refImg)
			}else{
				assetImage = UIImage()
			}
		} else if (info[UIImagePickerControllerMediaType] as? String) == kUTTypeImage as String {
			if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
				assetImage = image
			}else{
				assetImage = UIImage()
			}
			assetType = .photo
		}else if #available(iOS 9.1, *) {
			if (info[UIImagePickerControllerMediaType] as? String) == kUTTypeLivePhoto as String {
				if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
					assetImage = image
				}else{
					assetImage = UIImage()
				}
				assetType = .livePhoto
			}
		}
		let assetInput = MIAsset(image: assetImage, type: assetType)
		assetInput.assetURL = assetURL
		assetInput.duration = duration
		delegate?.didSelectMedia(assetInput)
	}

}

// MARK: - Collection view data source methods

extension MIAssetPickerView : UICollectionViewDataSource {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		//All assets + 3 cell for custom camera,image picker camera and photolibrary.
		return assetsManager.numberOfAssets() + 3
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		var cell: UICollectionViewCell?
		if indexPath.row == 0 || indexPath.row == 1 {
			let staticAssetCell = collectionView.dequeueReusableCell(withReuseIdentifier: StaticCollectionViewCell.reuseIdentifier, for: indexPath) as! StaticCollectionViewCell
			cell = staticAssetCell
			staticAssetCell.configureCell(forCamera: (indexPath.row == 0))
		} else if indexPath.row == 2 {
			let photoCaptureCell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCaptureCollectionViewCell.reuseIdentifier, for: indexPath) as! PhotoCaptureCollectionViewCell
			photoCaptureCell.captureCompletionHandler = { [weak self] asset in
				self?.delegate?.didSelectMedia(asset)
			}
			cell = photoCaptureCell
		} else {
			let assetCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetCollectionViewCell.reuseIdentifier, for: indexPath) as? AssetCollectionViewCell
			cell = assetCollectionViewCell
		}
		return cell!
	}
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if let assetCell = cell as? AssetCollectionViewCell {
			assetCell.cancelImageRequest(assetsManager)
			guard let asset = assetsManager.asset(at: indexPath.row - 3)else {return}
			assetCell.configure(for: asset, assetManager: assetsManager)
		}
	}
}

// MARK: - Collection view delegate methods

extension MIAssetPickerView : UICollectionViewDelegate {
	
	func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		return true
	}
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard indexPath.row > 2 else {
			guard indexPath.row != 2 else {return}
			showMessagePicker(forSourceCamera: indexPath.row == 0)
			return
		}
		if let asset = assetsManager.asset(at: indexPath.row - 3){
			let selectedIndex = selectedAssets.index(of: asset)
			if selectedIndex == nil {
				selectedAssets.append(asset)
			}
			delegate?.didSelect(asset: asset)
		}
	}
	func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		guard indexPath.row > 2 else {
			guard indexPath.row != 2 else {return}
			showMessagePicker(forSourceCamera: indexPath.row == 0)
			return
		}
		if let asset = assetsManager.asset(at: indexPath.row - 3){
			if let selectedIndex = selectedAssets.index(of: asset) {
				selectedAssets.remove(at: selectedIndex)
			}
			delegate?.didDeselect(asset: asset)
		}
	}
}

// MARK: - Collection view flow layout delegate methods

extension MIAssetPickerView : UICollectionViewDelegateFlowLayout{
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		if indexPath.row == 2 {
			let cellHeight: CGFloat = collectionView.frame.size.height - 3
			let cellSize = AVMakeRect(aspectRatio: CGSize(width: 0.75, height: 1), insideRect: CGRect(x: 0, y: 0, width: cellHeight, height: cellHeight)).size
			return cellSize
		} else if indexPath.row == 0 || indexPath.row == 1 {
			let cellHeight: CGFloat = (collectionView.frame.size.height - 4) / 2
			let cellSize = CGSize(width: 70, height: cellHeight)
			return cellSize
		} else {
			let cellHeight: CGFloat = (collectionView.frame.size.height - 4) / 2
			assetCellSize = CGSize(width: cellHeight, height: cellHeight)
			assetsManager.assetCacheSize = assetCellSize
			return assetCellSize
		}
	}
	
	
}

// MARK: - Collection view datasource prefetching methods

extension MIAssetPickerView : UICollectionViewDataSourcePrefetching {
	func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
		let assets = getAssets(at: indexPaths)
		assetsManager.startCachingImages(for: assets, for: assetCellSize)
	}
	func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
		let assets = getAssets(at: indexPaths)
		assetsManager.stopCachingImages(for: assets, for: assetCellSize)
	}
}

// MARK: - Asset manager delegate methods

extension MIAssetPickerView:MIAssetsManagerDelegate {
	
	func assetManager(_ manager: MIAssetsManager, insertedAssets assets: [PHAsset], atIndexPaths indexPaths: [IndexPath]) {
		assetsListCollectionView?.insertItems(at: indexPaths)
	}
	
	func assetManager(_ manager: MIAssetsManager, updatedAssets assets: [PHAsset], atIndexPaths indexPaths: [IndexPath]) {
		delegate?.didUpdate(assets: assets)
		assetsListCollectionView?.reloadItems(at: indexPaths)
	}
	
	func assetManager(_ manager: MIAssetsManager, removedAssets assets: [PHAsset], atIndexPaths indexPaths: [IndexPath]) {
		for asset in assets {
			delegate?.didDeselect(asset: asset)
			if let index = selectedAssets.index(of: asset) {
				selectedAssets.remove(at: index)
			}
		}
		assetsListCollectionView?.deleteItems(at: indexPaths)
	}
	
	func assetManagerReloadAlbum(_ manager: MIAssetsManager) {
		assetsListCollectionView?.reloadData()
	}
	
	func assetManager(_ manager: MIAssetsManager, authorizationStatusChanged oldStatus: PHAuthorizationStatus, newStatus: PHAuthorizationStatus) {
		assetsListCollectionView?.reloadData()
	}
}

// MARK: - UIImagePickerControllerDelegate methods

extension MIAssetPickerView : UINavigationControllerDelegate, UIImagePickerControllerDelegate {
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		if #available(iOS 11.0, *) {
			if let asset = info[UIImagePickerControllerPHAsset] as? PHAsset {
				//User selected asset from gallery. process it as normal selection and deselection.
				select(asset)
				delegate?.didSelect(asset: asset)
			} else {
				//User captured photo or video from camera.
				processMedia(with: info)
			}
		} else {
			// Fallback on earlier versions
			processMedia(with: info)
		}
		picker.dismiss(animated: true)
	}

	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.dismiss(animated: true)
	}
}

// MARK: - Initialization methods

extension MIAssetPickerView {
	
	/// Initialize UI and setup initial values
	fileprivate final func initiateComponents(){
		assetsManager.delegate = self
		initializeAndConfigureViews()
	}
	
	/// Setup subviews
	fileprivate final func initializeAndConfigureViews(){
		autoresizingMask = .flexibleHeight
		backgroundColor = UIColor.groupTableViewBackground
		
		initializeAndConfigureCollection()
	}
	
	/// Initialize collection view and add as subview.
	fileprivate final func initializeAndConfigureCollection(){
		let flowLayout = AssetInputFlowLayout()
		flowLayout.scrollDirection = .horizontal
		flowLayout.sectionInset = UIEdgeInsetsMake(1, 5, 1, 5)
		flowLayout.minimumInteritemSpacing = 2
		flowLayout.minimumLineSpacing = 2
		let assetsListCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
		assetsListCollectionView.translatesAutoresizingMaskIntoConstraints = false
		assetsListCollectionView.backgroundColor = UIColor.clear
		assetsListCollectionView.dataSource = self
		assetsListCollectionView.delegate = self
		if #available(iOS 10.0, *) {
			assetsListCollectionView.prefetchDataSource = self
		}
		assetsListCollectionView.bounces = true
		assetsListCollectionView.showsVerticalScrollIndicator = false
		assetsListCollectionView.showsHorizontalScrollIndicator = false
		assetsListCollectionView.alwaysBounceHorizontal = true
		assetsListCollectionView.alwaysBounceVertical = false
		assetsListCollectionView.allowsMultipleSelection = true
		addSubview(assetsListCollectionView)
		self.assetsListCollectionView = assetsListCollectionView
		
		//Configure collection view
		
		assetsListCollectionView.register(StaticCollectionViewCell.self, forCellWithReuseIdentifier: StaticCollectionViewCell.reuseIdentifier)
		assetsListCollectionView.register(AssetCollectionViewCell.self, forCellWithReuseIdentifier: AssetCollectionViewCell.reuseIdentifier)
		assetsListCollectionView.register(PhotoCaptureCollectionViewCell.self, forCellWithReuseIdentifier: PhotoCaptureCollectionViewCell.reuseIdentifier)
		
		//Add layout
		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[assetsListCollectionView]", options: .directionMask, metrics: nil, views: ["assetsListCollectionView":assetsListCollectionView]))
		addConstraint(assetsListCollectionView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -5))
		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[assetsListCollectionView]-0-|", options: .directionLeftToRight, metrics: nil, views: ["assetsListCollectionView":assetsListCollectionView]))
		
	}
}

// MARK: - Custom flow layout

class AssetInputFlowLayout : UICollectionViewFlowLayout{
	override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
		return UICollectionViewFlowLayoutInvalidationContext()
	}
	override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		/// Return true when height changes as Height will affect cell size and hence re-calculation of layout.
		guard let oldBounds = collectionView?.bounds else {return true}
		return oldBounds.height != newBounds.height
	}
}

