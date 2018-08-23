//
//  AssetInputCollectionViewCell.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import UIKit
import Photos.PHImageManager
import Photos.PHAsset

class AssetInputCollectionViewCell: UICollectionViewCell {

	// MARK: - Variables
	
	fileprivate let selectionImageView = UIImageView()
	fileprivate let videoIndicatorImageView = UIImageView()
	fileprivate let assetImageView = UIImageView()
	fileprivate let removeAssetButton = UIButton()
	fileprivate let livePhotoButton = UIButton()
	fileprivate let videoTimeLabel = UILabel()
	fileprivate let videoBackdropView = MIGradientView()
	fileprivate var imageRequestID:PHImageRequestID = 0
	/// Block which will be invoked when user taps remvoe button.
	var removeCompletionHandler: ((UICollectionViewCell) -> Void)?
	/// Block which will be invoked when user taps live photo on off button.
	var livePhotoChangeCompletionHandler: ((UICollectionViewCell, Bool) -> Void)?

	override var isSelected: Bool{
		didSet{
			selectionImageView.isHidden = !isSelected
		}
	}
	class var reuseIdentifier: String{
		return NSStringFromClass(AssetInputCollectionViewCell.classForCoder()) as String
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
		setLivePhotoIndicatorViewHidden(true, selected: false)
		setVideoIndicator(hidden: true)
	}

	/// This will initialize and add all subview and prepare for use.
	private final func configureCellUI(){
		contentView.layer.cornerRadius = 15;
		contentView.clipsToBounds = true;

		//Initialize all components
		addAssetImageView()
		addVideoIndicatorView()
		addRemoveAssetButton()
		addLivePhotoButton()
		
		//Prepare for reuse
		prepareForReuse()
	}
}

// MARK: - Button action methods

extension AssetInputCollectionViewCell {
	@objc final func removeAssetButtonTouchUpInsde(_ button:UIButton){
		removeCompletionHandler?(self)
	}
	
	@objc final func livePhotoButtonTouchUpInsde(_ button:UIButton){
		button.isSelected = !button.isSelected
		livePhotoChangeCompletionHandler?(self,button.isSelected)
	}
}

// MARK: - Helper methods

extension AssetInputCollectionViewCell {
	
	/// Update video indicator visiblity along with backdrop view.
	///
	/// - Parameter hide: Hide or show
	func setVideoIndicator(hidden hide: Bool) {
		videoIndicatorImageView.isHidden = hide
		videoBackdropView.isHidden = hide
		videoTimeLabel.isHidden = hide
	}
	
	
	/// Update live photo button status
	///
	/// - Parameters:
	///   - hide: Should hide or not
	///   - selected: Should select button or not
	func setLivePhotoIndicatorViewHidden(_ hide: Bool, selected: Bool) {
		livePhotoButton.isHidden = hide
		livePhotoButton.isSelected = selected
	}

	/// Converts NSTimeInterval to user redable representation. H:M:SS format.
	///
	/// - Parameter duration: Duration
	/// - Returns: String representation
	func convertDuration(toTimeString duration: TimeInterval) -> String {
		var duration = duration
		var durationString = ""
		let minutes = Int(duration / 60)
		let hours = Int(duration / (60 * 60))
		if hours > 0 {
			duration -= TimeInterval(hours * 60 * 60)
			durationString = durationString + ("\(hours):")
		}
		let minute = Int(duration / (60))
		duration -= TimeInterval(minute * 60)
		let seconds = Int(duration)
		return durationString + (String(format: "%d:%02d", minutes, seconds))
	}

	func cofigure(for asset:Any,assetManager manager:MIAssetsManager, isLivePhotoOff off:Bool){
		cancelImageRequest(manager)
		if let asset = asset as? PHAsset {
			configure(for: asset, assetManager: manager, isLivePhotoOff: off)
		}else if let asset = asset as? MIAsset{
			configure(for: asset, isLivePhotoOff: off)
		}
	}

	/// This will configure current cell based on asset. this retrives asset image using assetManager.
	///
	/// - Parameters:
	///   - asset: asset to be used for cell configuration
	///   - assetsManager: asset manager
	///   - off: turn of live photo button or on
	private final func configure(for asset: PHAsset, assetManager assetsManager: MIAssetsManager, isLivePhotoOff off:Bool) {
			if asset.mediaType == .video {
				videoTimeLabel.text = convertDuration(toTimeString: asset.duration)
				setVideoIndicator(hidden: false)
			}else if #available(iOS 9.1, *){
				if asset.mediaSubtypes == .photoLive {
					setLivePhotoIndicatorViewHidden(false, selected: off)
				}
			}
		imageRequestID = assetsManager.requestImage(for: asset, size: bounds.size, isNeededDegraded: true, completionHander: { [weak self](image, isDegraded) in
			self?.assetImageView.image = image
		})
	}
	
	/// This will configure current cell based on asset.
	///
	/// - Parameters:
	///   - asset: asset to be used for cell configuration
	///   - off: turn of live photo button or on
	private final func configure(for asset: MIAsset, isLivePhotoOff off: Bool) {
		assetImageView.image = asset.image
		if asset.assetType == .video {
			videoTimeLabel.text = convertDuration(toTimeString: asset.duration)
			setVideoIndicator(hidden: false)
		} else if asset.assetType == .livePhoto {
			setLivePhotoIndicatorViewHidden(false, selected: off)
		}
	}

	
	/// This method will cancel any previous image loading request. this will be effective in reusing cell.
	///
	/// - Parameter assetsManager: assets manager
	private final func cancelImageRequest(_ assetsManager: MIAssetsManager) {
		assetsManager.cancel(imageRequest: imageRequestID)
		imageRequestID = 0
	}
	
}

// MARK: - UI helper methods extention

extension AssetInputCollectionViewCell {
	
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
	private final func addVideoIndicatorView() {
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
		
		videoTimeLabel.translatesAutoresizingMaskIntoConstraints = false
		videoTimeLabel.textColor = UIColor.white
		videoTimeLabel.font = videoTimeLabel.font.withSize(12)
		contentView.addSubview(videoTimeLabel)
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[videoTimeLabel]-5-|", options: .directionMask, metrics: nil, views: ["videoTimeLabel":videoTimeLabel]))
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[videoTimeLabel]-5-|", options: .directionLeftToRight, metrics: nil, views: ["videoTimeLabel":videoTimeLabel]))
	}
	
	
	/// Add remove button
	private final func addRemoveAssetButton() {
		removeAssetButton.translatesAutoresizingMaskIntoConstraints = false
		removeAssetButton.setImage(UIImage.fromMIBundle(named: "RemoveItem"), for: .normal)
		removeAssetButton.addTarget(self, action: #selector(removeAssetButtonTouchUpInsde(_:)), for: .touchUpInside)
		contentView.addSubview(removeAssetButton)
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[removeAssetButton]", options: .directionMask, metrics: nil, views: ["removeAssetButton":removeAssetButton]))
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[removeAssetButton]-5-|", options: .directionLeftToRight, metrics: nil,views: ["removeAssetButton":removeAssetButton]))
	}
	
	/**
	Add Live photo button.
	*/
	private final func addLivePhotoButton() {
		livePhotoButton.translatesAutoresizingMaskIntoConstraints = false
		livePhotoButton.setImage(UIImage.fromMIBundle(named: "Live"), for: .normal)
		livePhotoButton.setImage(UIImage.fromMIBundle(named: "LifeOff"), for: .selected)
		livePhotoButton.addTarget(self, action: #selector(livePhotoButtonTouchUpInsde(_:)), for: .touchUpInside)
		contentView.addSubview(livePhotoButton)
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[livePhotoButton]", options: .directionMask, metrics: nil, views: ["livePhotoButton":livePhotoButton]))
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[livePhotoButton]", options: .directionLeftToRight, metrics: nil, views:["livePhotoButton":livePhotoButton]))
	}
}
