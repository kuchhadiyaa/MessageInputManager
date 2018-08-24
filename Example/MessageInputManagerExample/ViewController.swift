//
//  ViewController.swift
//  MessageInputManager
//
//  Created by kuchhadiyaa on 08/22/2018.
//  Copyright (c) 2018 kuchhadiyaa. All rights reserved.
//

import UIKit
import Photos
import MessageInputManager

class ViewController: UIViewController {

	// MARK: - Variables
	lazy var conversationDetailView:ConversationDetailView = {
		let conversationDetailView = view as! ConversationDetailView
		conversationDetailView.messageInputView.delegate = self
		return conversationDetailView
	}()

	// MARK: - Life cycle methods
	
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		conversationDetailView.becomeFirstResponder()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
}

// MARK: - Message input delegate methods
extension ViewController :MIMessageInputViewDelegate {
	func send(message: String?, selectedAssets assets: NSArray, liveOffAssetsIndexes indexes: NSArray) {
		DispatchQueue.global(qos: .userInitiated).async {[weak self] in
			//Process the data on background queue.
			let imageManager = PHImageManager.default()
			assets.enumerated().forEach { (index,asset) in
				if let asset = asset as? PHAsset {
					if asset.mediaType == .image {
						func processAssetAsNoralImage(){
							let imageRequestOptions = PHImageRequestOptions()
							imageRequestOptions.isSynchronous = true
							imageManager.requestImageData(for: asset, options: imageRequestOptions, resultHandler: { [weak self](data, type, orientation, info) in
								if let imageData = data {
									self?.process(imageData: imageData)
								}else{
									//handle error
								}
							})
						}
						//Process image asset. check if it's live photo or normal photo
						if #available(iOS 9.1, *),asset.mediaSubtypes == .photoLive {
							//Photo is live photo so check if user has turned off live photo or not. i
							//If live photo is off sent live photo else send normal photo.
							if indexes.contains(NSIndexPath(row: index, section: 0)) {
								//User has turned off live photo for this asset. process it normally
								processAssetAsNoralImage()
							}else{
								//It's live photo.
								imageManager.requestLivePhoto(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFill, options: nil, resultHandler: { [weak self](livePhoto, info) in
									if let livePhoto = livePhoto {
										self?.process(livePhoto: livePhoto)
									}else{
										//Handle error
									}
								})
							}
						}else{
							//Process normal photo
							processAssetAsNoralImage()
						}
					}else if asset.mediaType == .video {
						//Process video asset.
						imageManager.requestAVAsset(forVideo: asset, options: nil, resultHandler: { [weak self](videoAsset, mix, info) in
							if let videoAsset = videoAsset {
								self?.process(video: videoAsset)
							}else{
								//Handle errro
							}
						})
					}
				}else if let asset = asset as? MIAsset {
					func processImageAsNormal(){
						if let imageData = UIImageJPEGRepresentation(asset.image, 0.7) {
							self?.process(imageData: imageData)
						}else{
							//Handle error
						}
					}
					if asset.assetType == .photo {
						processImageAsNormal()
					}else if asset.assetType == .livePhoto {
						if indexes.contains(NSIndexPath(row: index, section: 0)) {
							//User has turned off live photo for this asset. process it normally
							processImageAsNormal()
						}else{
							//Process live photo url
						}
					}else if asset.assetType == .video{
						let videoAsset = AVAsset(url: asset.assetURL!)
						self?.process(video: videoAsset)
					}
				}
			}
		}
	}
	func process(imageData image:Data){
		DispatchQueue.main.async {
			//Process UI operation on main queue
		}
	}
	
	@available(iOS 9.1, *)
	func process(livePhoto photo:PHLivePhoto){
		DispatchQueue.main.async {
			//Process UI operation on main queue
		}

	}
	func process(video asset:AVAsset){
		DispatchQueue.main.async {
			//Process UI operation on main queue
		}
	}
}

