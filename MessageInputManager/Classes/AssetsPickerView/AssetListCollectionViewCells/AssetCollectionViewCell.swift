//
//  AssetCollectionViewCell.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import UIKit
import Photos.PHImageManager
import Photos.PHAsset

/// Collection view cell representing asset details.
class AssetCollectionViewCell: UICollectionViewCell {

	// MARK: - Variables
	
	fileprivate let selectionImageView = UIImageView()
	fileprivate let videoIndicatorImageView = UIImageView()
	fileprivate let assetImageView = UIImageView()
	fileprivate let videoBackdropView = MIGradientView()
	fileprivate var imageRequestID:PHImageRequestID = 0
	override var isSelected: Bool{
		didSet{
			selectionImageView.isHidden = !isSelected
		}
	}
	class var reuseIdentifier: String{
		return NSStringFromClass(AssetCollectionViewCell.classForCoder()) as String
	}

	// MARK: - Life cycle methods
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		configureCellUI()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		configureCellUI()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		assetImageView.image = nil
		setVideoIndicator(hidden: true)
	}
	
	// MARK: - UI helper methods
	
	/// This will initialize and add all subview and prepare for use.
	private final func configureCellUI(){
		//Initialize all components
		addAssetImageView()
		addVideoIndicatorView()
		addSelectionIndicatorView()
		
		//Prepare for reuse
		prepareForReuse()
	}
	
	/// This method will add image view representing asset thumb.
	private final func addAssetImageView() {
		assetImageView.translatesAutoresizingMaskIntoConstraints = false
		assetImageView.contentMode = .scaleAspectFill
		assetImageView.clipsToBounds = true
		contentView.addSubview(assetImageView)
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[assetImageView]-0-|", options: .directionMask, metrics: nil, views: ["assetImageView":assetImageView]))
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[assetImageView]-0-|", options: .directionLeftToRight, metrics: nil, views: ["assetImageView":assetImageView]))
	}
	
	/// This method will add video indicator view with backdrop view.
	func addVideoIndicatorView() {
		videoIndicatorImageView.translatesAutoresizingMaskIntoConstraints = false
		videoIndicatorImageView.clipsToBounds = true
		videoIndicatorImageView.contentMode = .scaleAspectFill
		videoIndicatorImageView.image = UIImage.fromMIBundle(named: "Video")
		
		videoBackdropView.translatesAutoresizingMaskIntoConstraints = false
		let videoBackdropLayer = videoBackdropView.layer as? CAGradientLayer
		videoBackdropLayer?.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
		contentView.addSubview(videoBackdropView)
		contentView.addSubview(videoIndicatorImageView)
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[videoIndicatorImageView]-5-|", options: .directionMask, metrics: nil, views: ["videoIndicatorImageView":videoIndicatorImageView]))
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[videoIndicatorImageView]", options: .directionLeftToRight, metrics: nil, views: ["videoIndicatorImageView":videoIndicatorImageView]))
		contentView.addConstraint(videoBackdropView.heightAnchor.constraint(equalToConstant: videoIndicatorImageView.image?.size.height ?? 0 + 10))
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[videoBackdropView]-0-|", options: .directionMask, metrics: nil, views: ["videoBackdropView":videoBackdropView]))
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[videoBackdropView]-0-|", options: .directionLeftToRight, metrics: nil, views: ["videoBackdropView":videoBackdropView]))
	}
	
	/// Adds selection indicator image view.
	func addSelectionIndicatorView() {
		selectionImageView.translatesAutoresizingMaskIntoConstraints = false
		selectionImageView.clipsToBounds = true
		selectionImageView.contentMode = .scaleAspectFill
		selectionImageView.image = UIImage.fromMIBundle(named: "Select")
		contentView.addSubview(selectionImageView)
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[selectionImageView]-5-|", options: .directionMask, metrics: nil, views: ["selectionImageView":selectionImageView]))
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[selectionImageView]-5-|", options: .directionLeftToRight, metrics: nil, views: ["selectionImageView":selectionImageView]))
	}

}

// MARK: - Helper methods

extension AssetCollectionViewCell {

	/// Update video indicator visiblity along with backdrop view.
	///
	/// - Parameter hide: Hide or show
	func setVideoIndicator(hidden hide: Bool) {
		videoIndicatorImageView.isHidden = hide
		videoBackdropView.isHidden = hide
	}

	func configure(for asset: PHAsset, assetManager assetsManager: MIAssetsManager) {
		if asset.mediaType == .video {
			setVideoIndicator(hidden: false)
		}
		imageRequestID = assetsManager.requestImage(for: asset, size: bounds.size, isNeededDegraded: true, completionHander: { [weak self](image, isDegraded) in
			self?.assetImageView.image = image
		})
	}
	
	func cancelImageRequest(_ assetsManager: MIAssetsManager) {
		assetsManager.cancel(imageRequest: imageRequestID)
		imageRequestID = 0
	}

}
