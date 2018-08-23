//
//  StaticCollectionViewCell.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import UIKit

/// Collection view cell for asset selection from gallery or camera.
class StaticCollectionViewCell: UICollectionViewCell {

	// MARK: - Variables
	fileprivate var assetTitleLabel = UILabel()
	fileprivate var assetDestinationIconImageView = UIImageView()

	class var reuseIdentifier: String{
		return NSStringFromClass(StaticCollectionViewCell.classForCoder()) as String
	}

	// MARK: - Life cycle methods
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		configureCell()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		configureCell()
	}
	
	// MARK: - Helper methods
	
	/// Initialize and configure cell subview
	internal final func configureCell(){
		let backdropView = UIView()
		backdropView.backgroundColor = UIColor.white
		backdropView.layer.cornerRadius = 5
		backdropView.clipsToBounds = true
		backdropView.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(backdropView)
		
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[backdropView]-0-|", options: .directionMask, metrics: nil, views: ["backdropView":backdropView]))
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-2-[backdropView]-2-|", options: .directionLeftToRight, metrics: nil, views: ["backdropView":backdropView]))
		
		assetDestinationIconImageView.translatesAutoresizingMaskIntoConstraints = false
		assetDestinationIconImageView.layer.cornerRadius = 5
		assetDestinationIconImageView.clipsToBounds = true
		backdropView.addSubview(assetDestinationIconImageView)
		backdropView.addConstraint(assetDestinationIconImageView.centerYAnchor.constraint(equalTo: backdropView.centerYAnchor, constant: -10))
		backdropView.addConstraint(assetDestinationIconImageView.centerXAnchor.constraint(equalTo: backdropView.centerXAnchor, constant: 0))

		assetTitleLabel.translatesAutoresizingMaskIntoConstraints = false
		let font: UIFont = assetTitleLabel.font
		assetTitleLabel.font = font.withSize(14)
		backdropView.addSubview(assetTitleLabel)
		backdropView.addConstraint(assetTitleLabel.centerYAnchor.constraint(equalTo: backdropView.centerYAnchor, constant: 20))
		backdropView.addConstraint(assetTitleLabel.centerXAnchor.constraint(equalTo: backdropView.centerXAnchor, constant: 0))
	}
	
	/// Configure this cell to use as camera cell or Photo cell.
	///
	/// - Parameter camera: Prepare for camera or photo library
	internal func configureCell(forCamera camera: Bool) {
		if camera{
			assetTitleLabel.text = "Camera"
			assetDestinationIconImageView.image = UIImage.fromMIBundle(named: "Camera")
		}else{
			assetTitleLabel.text = "Photos"
			assetDestinationIconImageView.image = UIImage.fromMIBundle(named: "Photos")
		}
	}

}
