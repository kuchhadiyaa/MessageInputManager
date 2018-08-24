//
//  MIMessageInputView.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import UIKit
import Photos.PHAsset

public class MIMessageInputView: UIView {

	// MARK: - Variables
	
	public weak var delegate:MIMessageInputViewDelegate?
	public var textMessageLength = 1000
	public var inputPlaceholder = "Message" {
		didSet{
			placeholderLabel.text = inputPlaceholder
		}
	}

	fileprivate var assetInputButton: MIAssetInputButton = MIAssetInputButton()
	fileprivate var sendButton = UIButton()

	fileprivate var assetInputCollectionView: UICollectionView?
	fileprivate var assetInputView: UIView = UIView()

	fileprivate var placeholderLabel = UILabel()
	fileprivate var messageInputTextView = MITextMessageInputTextView()
	
	fileprivate var textInputToSuperViewConstraint: NSLayoutConstraint?
	fileprivate var textInputToAssetInputConstraint: NSLayoutConstraint?
	fileprivate var assetInputHeightConstraint: NSLayoutConstraint?
	
	fileprivate var livePhotoOffForAssets = NSMutableArray()
	fileprivate var assetsInput = NSMutableArray()
	fileprivate var assetPickerView = MIAssetPickerView()

	// MARK: - Life cycle methods
	
	public convenience init(){
		self.init(frame: CGRect.zero)
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		initializeComponents()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initializeComponents()
	}
	
	private final func initializeComponents(){
		assetPickerView.delegate = self
		configureView()
	}
	
	public override var intrinsicContentSize: CGSize{
		return CGSize.zero
	}
}

// MARK: - Asset picker delegate methods

extension MIMessageInputView: MIAssetPickerViewDelegate {
	func didSelect(asset: PHAsset) {
		if !assetsInput.contains(asset) {
			let indexPath = IndexPath(row: assetsInput.count, section: 0)
			assetsInput.add(asset)
			assetInputCollectionView?.insertItems(at: [indexPath])
			assetInputCollectionView?.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
		}
		updateAssetInputView()
	}
	
	func didDeselect(asset: PHAsset) {
		let index = assetsInput.index(of: asset)
		if index != NSNotFound {
			let indexPath = IndexPath(row: index, section: 0)
			livePhotoOffForAssets.remove(indexPath)
			assetsInput.remove(asset)
			assetInputCollectionView?.deleteItems(at: [indexPath])
		}
		updateAssetInputView()
	}
	
	func didSelectMedia(_ asset: MIAsset) {
		let indexPath = IndexPath(row: assetsInput.count, section: 0)
		assetsInput.add(asset)
		assetInputCollectionView?.insertItems(at: [indexPath])
		assetInputCollectionView?.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)

		updateAssetInputView()
	}
	
	func didUpdate(assets: [PHAsset]) {
		var updatedItems = [IndexPath]()
		for asset in assets {
			let assetIndex = assetsInput.index(of: asset)
			if assetIndex != NSNotFound {
				let indexPath = IndexPath(row: assetIndex, section: 0)
				if #available(iOS 9.1, *),asset.mediaSubtypes != .photoLive && livePhotoOffForAssets.contains(indexPath) {
					livePhotoOffForAssets.remove(indexPath)
				}
				updatedItems.append(indexPath)
			}
		}
		if updatedItems.count > 0{
			assetInputCollectionView?.reloadItems(at: updatedItems)
		}
		updateAssetInputView()
	}
}

extension MIMessageInputView : UICollectionViewDataSource {
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return assetsInput.count
	}
	
	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		return collectionView.dequeueReusableCell(withReuseIdentifier: AssetInputCollectionViewCell.reuseIdentifier, for: indexPath)
	}
	public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		let assetInputCell = cell as! AssetInputCollectionViewCell
		//Remove completion handler
		assetInputCell.removeCompletionHandler = {[weak self] cell in
			if let indexPath = collectionView.indexPath(for: cell) {
				self?.livePhotoOffForAssets.remove(indexPath)
				let asset = self?.assetsInput.object(at: indexPath.row)
				self?.assetsInput.removeObject(at: indexPath.row)
				collectionView.deleteItems(at: [indexPath])
				if let asset = asset as? PHAsset {
					self?.assetPickerView .deselect(asset)
				}
				
			}
			self?.updateAssetInputView()
		}
		
		//Live photo setting update
		assetInputCell.livePhotoChangeCompletionHandler = { [weak self](cell, liveOff) in
			if let indexPath = collectionView.indexPath(for: cell) {
				if liveOff {
					self?.livePhotoOffForAssets.add(indexPath)
				}else{
					self?.livePhotoOffForAssets.remove(indexPath)
				}
			}
		}
		//Fill cell Data
		assetInputCell.cofigure(for: assetsInput.object(at: indexPath.row), assetManager: assetPickerView.assetsManager, isLivePhotoOff: livePhotoOffForAssets.contains(indexPath))
	}
	
}

extension MIMessageInputView : UICollectionViewDelegateFlowLayout {
	public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		//Height will be of collection and width determinded based on image aspect ratio.
		let assetCellHeight = collectionView.bounds.size.height - 10
		let asset = assetsInput.object(at: indexPath.row)
		var cellSize = CGSize(width: assetCellHeight, height: assetCellHeight)
		if let asset = asset as? PHAsset {
			let scaleFactor = assetCellHeight / CGFloat(asset.pixelHeight)
			cellSize = CGSize(width: CGFloat(asset.pixelWidth) * scaleFactor, height: assetCellHeight)
		}else if let asset = asset as? MIAsset {
			let scaleFactor = assetCellHeight / asset.image.size.height
			cellSize = CGSize(width: asset.image.size.width * scaleFactor, height: assetCellHeight)
		}
		return cellSize
	}
}

// MARK: - Button action methods

extension MIMessageInputView {
	@objc final func mediaInputButtonTouchUpInsde(_ button:UIButton){
		if button.isSelected {
			button.resignFirstResponder()
		}else{
			messageInputTextView.resignFirstResponder()
			button.becomeFirstResponder()
		}
		button.isSelected = !button.isSelected
	}
	
	@objc final func sendMessageButtonTouchUpInsde(_ button:UIButton){
		delegate?.send(message: messageInputTextView.text, selectedAssets: NSArray(array: assetsInput), liveOffAssetsIndexes: NSArray(array: livePhotoOffForAssets))
		messageInputTextView.text = ""
		assetsInput.removeAllObjects()
		livePhotoOffForAssets.removeAllObjects()
		assetInputCollectionView?.reloadData()
		assetPickerView.clearAllSelections()
		updateAssetInputView()
		updatePlaceholderLabel()
	}
}

// MARK: - UItext view delegate methods
extension MIMessageInputView: UITextViewDelegate {
	public func textViewDidChange(_ textView: UITextView) {
		//Update height of text view by intrinsic content size. and update send button status when text changes.
		let textInputViewSize = textView.sizeThatFits(CGSize(width: textView.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
		if textInputViewSize.height <= 150 {
			UIView.animate(withDuration: 0.2) {
				textView.invalidateIntrinsicContentSize()
				textView.superview?.setNeedsLayout()
				textView.superview?.layoutIfNeeded()
			}
		}
		updateSendButton()
		updatePlaceholderLabel()
	}
	
	public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		// Limit number of characters in message.
		var currentText = textView.text as NSString
		currentText = currentText.replacingCharacters(in: range, with: text) as NSString
		if currentText.length > textMessageLength {
			return false
		}
		return true
	}
	public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
		assetInputButton.resignFirstResponder()
		assetInputButton.isSelected = false
		return true
	}
	
}

// MARK: - Helper method

extension MIMessageInputView {
	
	/// Update Send button
	private final func updateSendButton(){
		if assetsInput.count > 0 || messageInputTextView.text != ""{
			sendButton.isEnabled = true;
		}else{
			sendButton.isEnabled = false;
		}
	}
	
	/// Update asset input visiblity
	private final func updateAssetInputView(){
		let hideAssetInputView = assetsInput.count == 0
		if assetInputView.isHidden != hideAssetInputView {
			func performAnimation(to alpha:CGFloat){
				assetInputView.alpha = alpha
				if hideAssetInputView{
					textInputToAssetInputConstraint?.isActive = !hideAssetInputView
					textInputToSuperViewConstraint?.isActive = hideAssetInputView
				}else{
					textInputToSuperViewConstraint?.isActive = hideAssetInputView
					textInputToAssetInputConstraint?.isActive = !hideAssetInputView
				}
				assetInputView.superview?.invalidateIntrinsicContentSize()
				assetInputView.superview?.layoutIfNeeded()
			}
			if hideAssetInputView {
				UIView.animate(withDuration: 0.25, animations: {
					performAnimation(to: 0)
				}) { [weak self](completion) in
					self?.assetInputView.isHidden = hideAssetInputView
				}
			}else{
				assetInputView.isHidden = hideAssetInputView
				assetInputView.alpha = 0
				UIView.animate(withDuration: 0.25) {
					performAnimation(to: 1)
				}
			}
		}
		updateSendButton()
	}

	/// Update visiblity of Placeholder label
	private final func updatePlaceholderLabel(){
		placeholderLabel.isHidden = messageInputTextView.text != ""
	}
}

// MARK: - UI Helper methods

extension MIMessageInputView{
	private final func configureView(){
		translatesAutoresizingMaskIntoConstraints = false
		autoresizingMask = [.flexibleWidth,.flexibleHeight]
		
		//Main stack view.
		
		let mainStackView = UIStackView()
		mainStackView.translatesAutoresizingMaskIntoConstraints = false
		mainStackView.distribution = .fill
		mainStackView.axis = .horizontal
		mainStackView.spacing = 10
		addSubview(mainStackView)
		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[mainStackView(>=30)]", options: .directionLeadingToTrailing, metrics: nil, views: ["mainStackView":mainStackView]))
		
		addConstraint(mainStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -5))
		addConstraint(mainStackView.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor, constant: 0))
		addConstraint(mainStackView.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor, constant: 0))
				
		configureInputView(containerView: mainStackView)
	}
	
	private final func configureInputView(containerView stackView:UIStackView){
		
		//Create container to wrap both collection and text input.
		
		let inputContainerView = UIView()
		inputContainerView.translatesAutoresizingMaskIntoConstraints = false
		inputContainerView.clipsToBounds = true
		inputContainerView.backgroundColor = UIColor.groupTableViewBackground
		inputContainerView.layer.cornerRadius = 15
		inputContainerView.layer.borderWidth = 0.5
		inputContainerView.layer.borderColor = UIColor.lightGray.cgColor
		//Add both to container
		configureAssetsInputView()
		initializeMessageInputTextView()
		initializeSendButton()
		inputContainerView.addSubview(assetInputView)
		inputContainerView.addSubview(placeholderLabel)
		inputContainerView.addSubview(messageInputTextView)
		inputContainerView.addSubview(sendButton)
		
		//Setup layout for both views. Vertical spacing between textinput <-> collection and textInput <-> super view will determine height of inputview and will be used to show hide asset input. One will be active at a time.
		
		inputContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[textMessageInput]-1-|", options: .directionMask, metrics: nil, views: ["textMessageInput":messageInputTextView]))
		inputContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[assetInputView]", options: .directionMask, metrics: nil, views: ["assetInputView":assetInputView]))
		textInputToSuperViewConstraint = NSLayoutConstraint(item: messageInputTextView, attribute: .top, relatedBy: .equal, toItem: inputContainerView, attribute: .top, multiplier: 1, constant: 0)
		textInputToAssetInputConstraint = NSLayoutConstraint(item: messageInputTextView, attribute: .top, relatedBy: .equal, toItem: assetInputView, attribute: .bottom, multiplier: 1, constant: 0)
		inputContainerView.addConstraint(textInputToSuperViewConstraint!)
		
		inputContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[sendButton]-5-|", options: .directionMask, metrics: nil, views: ["sendButton":sendButton]))
		inputContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[assetInputView]-0-|", options: .directionLeftToRight, metrics: nil, views: ["assetInputView":assetInputView]))
		inputContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-7.5-[textMessageInput]-0-[sendButton]-2-|", options: .directionLeftToRight, metrics: nil, views: ["sendButton":sendButton,"textMessageInput":messageInputTextView]))
		
		inputContainerView.addConstraint(placeholderLabel.leftAnchor.constraint(equalTo: messageInputTextView.leftAnchor, constant: 4))
		inputContainerView.addConstraint(placeholderLabel.rightAnchor.constraint(equalTo: messageInputTextView.rightAnchor))
		inputContainerView.addConstraint(placeholderLabel.bottomAnchor.constraint(equalTo: messageInputTextView.bottomAnchor))
		inputContainerView.addConstraint(placeholderLabel.topAnchor.constraint(equalTo: messageInputTextView.topAnchor))

		let mediaUploadButton = initializeMediaUploadButton()
		stackView.addArrangedSubview(embeddViewInSpacerView(mediaUploadButton))
		stackView.addArrangedSubview(inputContainerView)
	}
	
	private final func configureAssetsInputView(){
		
		assetInputView.translatesAutoresizingMaskIntoConstraints = false
		assetInputView.clipsToBounds = true
		assetInputView.isHidden = true
		
		let flowLayout = UICollectionViewFlowLayout()
		flowLayout.scrollDirection = .horizontal
		flowLayout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5)
		flowLayout.minimumInteritemSpacing = 5
		flowLayout.minimumLineSpacing = 5
		
		let assetInputCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
		assetInputCollectionView.translatesAutoresizingMaskIntoConstraints = false
		assetInputCollectionView.backgroundColor = UIColor.clear
		assetInputCollectionView.dataSource = self
		assetInputCollectionView.delegate = self
		assetInputCollectionView.bounces = true
		assetInputCollectionView.showsVerticalScrollIndicator = false
		assetInputCollectionView.showsHorizontalScrollIndicator = false
		
		assetInputCollectionView.alwaysBounceHorizontal = true
		assetInputCollectionView.alwaysBounceVertical = false
		
		self.assetInputCollectionView = assetInputCollectionView
		
		assetInputCollectionView.register(AssetInputCollectionViewCell.self, forCellWithReuseIdentifier: AssetInputCollectionViewCell.reuseIdentifier)
		
		let lineView = UIView()
		lineView.translatesAutoresizingMaskIntoConstraints = false
		lineView.clipsToBounds = true
		lineView.backgroundColor = UIColor.lightGray
		assetInputView.addSubview(assetInputCollectionView)
		assetInputView.addSubview(lineView)
		let height: CGFloat = (UIScreen.main.bounds.size.width - 60) / 2
		assetInputHeightConstraint = assetInputCollectionView.heightAnchor.constraint(equalToConstant: height)
		assetInputView.addConstraint(assetInputHeightConstraint!)
		assetInputView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[assetInputCollectionView]-0-[lineView(0.5)]-4-|", options: .directionMask, metrics: nil, views: ["assetInputCollectionView":assetInputCollectionView,"lineView":lineView]))
		assetInputView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[lineView]-0-|", options: .directionLeftToRight, metrics: nil, views: ["lineView":lineView]))
		assetInputView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[assetInputCollectionView]-0-|", options: .directionLeftToRight, metrics: nil, views: ["assetInputCollectionView":assetInputCollectionView]))
	}
	
	private final func initializeMessageInputTextView() {
		messageInputTextView.translatesAutoresizingMaskIntoConstraints = false
		messageInputTextView.delegate = self
		messageInputTextView.backgroundColor = UIColor.clear
		messageInputTextView.font = placeholderLabel.font.withSize(16)
		
		placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
		placeholderLabel.textColor = UIColor.lightGray
		placeholderLabel.text = inputPlaceholder
		placeholderLabel.font = placeholderLabel.font.withSize(16)
		
	}
	
	private final func initializeSendButton() {
		sendButton.translatesAutoresizingMaskIntoConstraints = false
		sendButton.isEnabled = false
		sendButton.setImage(UIImage.fromMIBundle(named: "Send"), for: .normal)
		sendButton.setImage(UIImage.fromMIBundle(named: "SendDisabled"), for: .disabled)
		sendButton.addTarget(self, action: #selector(sendMessageButtonTouchUpInsde(_:)), for: .touchUpInside)
		sendButton.addConstraint(sendButton.widthAnchor.constraint(equalToConstant: 30))
	}
	private final func initializeMediaUploadButton() -> UIButton{
		assetInputButton.translatesAutoresizingMaskIntoConstraints = false
		assetInputButton.setImage(UIImage.fromMIBundle(named: "Photo"), for: .selected)
		assetInputButton.setImage(UIImage.fromMIBundle(named: "PhotoDisabled"), for: .normal)
		assetInputButton.addTarget(self, action: #selector(mediaInputButtonTouchUpInsde(_:)), for: .touchUpInside)
		assetInputButton.assetInputView = assetPickerView
		assetInputButton.addConstraint(assetInputButton.widthAnchor.constraint(equalToConstant: 30))
		return assetInputButton

	}
	private final func embeddViewInSpacerView(_ view:UIView) -> UIView{
		let spacerView = UIView()
		spacerView.translatesAutoresizingMaskIntoConstraints = false
		spacerView.clipsToBounds = true
		spacerView.addSubview(view)

		spacerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[view]-7-|", options: .directionMask, metrics: nil, views: ["view":view]))
		spacerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: .directionLeftToRight, metrics: nil, views: ["view":view]))

		return spacerView
	}
}

extension UIImage {
	class func fromMIBundle(named name:String) -> UIImage?{
		return UIImage(named: name, in: UIImage.MIBundle, compatibleWith: nil)
	}
	static let MIBundle = Bundle(for: MIMessageInputView.classForCoder())
}
