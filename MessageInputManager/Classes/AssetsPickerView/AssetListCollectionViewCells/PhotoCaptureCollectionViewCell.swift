//
//  PhotoCaptureCollectionViewCell.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import UIKit
import Photos

class PhotoCaptureCollectionViewCell: UICollectionViewCell {

	// MARK: - Variables
	lazy var cameraController = {
		return MICameraManager(delegate: self)
	}()
	var captureCompletionHandler: ((MIAsset) -> Void)?
	let previewView = MIVideoPreviewView()
	let cameraSwitchButton = UIButton()
	let captureButton = UIButton()
	let permissionLabel = UILabel()
	
	/// ReuseIdentifier of the cell
	internal class var reuseIdentifier: String{
		return NSStringFromClass(PhotoCaptureCollectionViewCell.classForCoder()) as String
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
		
		backgroundColor = UIColor.white
		addPreviewView()
		addPermissionLabel()
		addCaptureButton()
		addCameraSwitchButton()
		
		cameraController.configurePreview(view: previewView)
	}
	
	/// This method will add preview view for video rendering.
	func addPreviewView() {
		
		previewView.clipsToBounds = true
		previewView.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(previewView)
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[previewView]-0-|", options: .directionMask, metrics: nil, views: ["previewView":previewView]))
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[previewView]-0-|", options: .directionLeftToRight, metrics: nil, views: ["previewView":previewView]))
	}

	/// This method will add permission label.
	func addPermissionLabel() {
		
		permissionLabel.translatesAutoresizingMaskIntoConstraints = false
		permissionLabel.textColor = UIColor.lightGray
		permissionLabel.numberOfLines = 0
		permissionLabel.textAlignment = .center
		permissionLabel.isHidden = true
		contentView.addSubview(permissionLabel)
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-4-[permissionLabel]-4-|", options: .directionLeftToRight, metrics: nil, views: ["permissionLabel":permissionLabel]))
		contentView.addConstraint(permissionLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor))
	}
	
	/// This method will add capture button.
	func addCaptureButton() {

		captureButton.translatesAutoresizingMaskIntoConstraints = false
		captureButton.isHidden = true
		captureButton.setImage(UIImage.fromMIBundle(named: "Capture"), for: .normal)
		captureButton.addTarget(self, action: #selector(captureButtonTouchUpInsde(_:)), for: .touchUpInside)
		contentView.addSubview(captureButton)
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[captureButton]-5-|", options: .directionLeftToRight, metrics: nil, views: ["captureButton":captureButton]))
		contentView.addConstraint(captureButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor))
	}
	
	/// Add button to switch camera from front to back and back to front.
	func addCameraSwitchButton() {
		
		cameraSwitchButton.translatesAutoresizingMaskIntoConstraints = false
		cameraSwitchButton.isHidden = true
		cameraSwitchButton.setImage(UIImage.fromMIBundle(named: "CameraSwitch"), for: .normal)
		cameraSwitchButton.addTarget(self, action: #selector(cameraSwitchButtonTouchUpInsde(_:)), for: .touchUpInside)
		contentView.addSubview(cameraSwitchButton)
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[cameraSwitchButton]", options: .directionMask, metrics: nil, views: ["cameraSwitchButton":cameraSwitchButton]))
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[cameraSwitchButton]-5-|", options: .directionLeftToRight, metrics: nil, views: ["cameraSwitchButton":cameraSwitchButton]))
	}

}

// MARK: - Button action methods
extension PhotoCaptureCollectionViewCell {
	@objc final func captureButtonTouchUpInsde(_ button:UIButton){
		cameraController.capturePhoto { [weak self](image, metaData, error) in
			if let error = error {
				//Hande error
				print(error)
			}else if let image = image{
				//Process the photo
				self?.captureCompletionHandler?(MIAsset(image: image, type: .photo))
			}
		}
	}
	@objc final func cameraSwitchButtonTouchUpInsde(_ button:UIButton){
		if cameraController.canSwitchCamera() {
			cameraController.switchCamera()
		}
	}

}


// MARK: - Camera manager delegate methods

extension PhotoCaptureCollectionViewCell : MICameraManagerDelgate {
	func cameraPermissionDidChange(status: AVAuthorizationStatus) {
		permissionLabel.text = "Application requires access to your camera."
		switch status {
		case .authorized:
			permissionLabel.isHidden = true
			captureButton.isHidden = false
			updateSwitchButtonVisiblity()
		default:
			permissionLabel.isHidden = false
			captureButton.isHidden = true
			cameraSwitchButton.isHidden = true
		}
	}
	
	func cameraSessionInterrupted(message: String) {
		permissionLabel.isHidden = false
		captureButton.isHidden = true
		cameraSwitchButton.isHidden = true
		permissionLabel.text = message
	}
	
	func cameraSessionInterruptionEnded() {
		permissionLabel.isHidden = true
		captureButton.isHidden = false
		updateSwitchButtonVisiblity()
	}
	
	/// Helper manage camera switch button visiblity based on capture devices.
	fileprivate final func updateSwitchButtonVisiblity(){
		if cameraController.canSwitchCamera() {
			cameraSwitchButton.isHidden = false
		}else{
			cameraSwitchButton.isHidden = true
		}
	}
}
