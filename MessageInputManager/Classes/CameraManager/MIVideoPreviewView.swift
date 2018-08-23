//
//  VideoPreviewView.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import UIKit
import AVFoundation

///MIVideoPreviewView shows video preview from camera to display.
final class MIVideoPreviewView: UIView {

	//MARK: - Variables & Propertis
	var session:AVCaptureSession?{
		get{
			let previewLayer = layer as! AVCaptureVideoPreviewLayer
			return previewLayer.session
		}
		set(newSession){
			let previewLayer = layer as! AVCaptureVideoPreviewLayer
			previewLayer.session = newSession
		}
	}

	override class var layerClass : AnyClass {
		return AVCaptureVideoPreviewLayer.classForCoder()
	}


}
