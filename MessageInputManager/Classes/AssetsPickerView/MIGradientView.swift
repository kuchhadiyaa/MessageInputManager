//
//  MIGradientView.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import UIKit

/// Gradient view for backdrop to video type of assets
class MIGradientView: UIView {
	
	// MARK: - Life cycle methods
	
	override class var layerClass:Swift.AnyClass {
		//Return Gradient layer as UIVies default layer.
		return CAGradientLayer.classForCoder()
	}
}
