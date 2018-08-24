//
//  SFCamera.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import Foundation
import AVFoundation
import UIKit

/// Class that manages all the camera related operations.
final class MICameraManager {
	
	//MARK: - Variables

	fileprivate var captureSession:AVCaptureSession = AVCaptureSession()
	fileprivate var captureDeviceBack:AVCaptureDevice?
	fileprivate var captureDeviceFront:AVCaptureDevice?
	fileprivate var captureDeviceCurretlyActive:AVCaptureDevice?
	fileprivate var captureDeviceInputCurrentlyActive:AVCaptureDeviceInput?
	fileprivate var videoOutput:AVCaptureVideoDataOutput?
	
	fileprivate var deviceStillOutput:AVCaptureStillImageOutput?
	fileprivate var photoCaptureProcessor:Any!
	fileprivate var floatCurrentZoomLevel:Float = 1
	fileprivate var floatMaxZoomLevel:Float = 1
	fileprivate let pinchVelocityDividerFactor:Float = 40.0
	
	fileprivate let operationQueueCameraConfiguration = OperationQueue()
	
	fileprivate weak var delegate:MICameraManagerDelgate?
	
	// MARK: - Lifecycle methods
	
	convenience init(delegate delegateObject:MICameraManagerDelgate) {
		self.init()
		delegate = delegateObject
	}
	
	init() {
		operationQueueCameraConfiguration.qualityOfService = .userInteractive
		operationQueueCameraConfiguration.maxConcurrentOperationCount = 1
		operationQueueCameraConfiguration.addOperation {
			self.configureCamera()
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Initializer methods
	
	/// Initialises camera capture session and UI. checks for access permission to camera and other elements. if access is not granted will show message of access required.
	fileprivate func configureCamera(){
		var authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
		switch authorizationStatus {
		case .notDetermined:
			AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { [weak self](granted:Bool) -> Void in
				authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
				self?.notifyDelegateOfAuthorization()
				if granted {
					self?.configureSession()
					self?.captureSession.startRunning()
				}
			})
		case .authorized:
			configureSession()
			notifyDelegateOfAuthorization()
			captureSession.startRunning()
		case .denied, .restricted:
			notifyDelegateOfAuthorization()
		}
	}
	
	/// Configure camera session for various settings according to device hardware. updates UI according to harware.
	fileprivate func configureSession(){
		guard captureDeviceCurretlyActive == nil else {
			return
		}
		addObservers()
		initializeCaptureDevices()
		
		captureSession.beginConfiguration()
		captureSession.sessionPreset = AVCaptureSession.Preset.photo
		do {
			if let captureDeviceBack = captureDeviceBack {
				captureDeviceInputCurrentlyActive = try AVCaptureDeviceInput(device: captureDeviceBack)
				if captureSession.canAddInput(captureDeviceInputCurrentlyActive!) {
					captureSession.addInput(captureDeviceInputCurrentlyActive!)
					captureDeviceCurretlyActive = captureDeviceBack
				}
			}else if let captureDeviceFront = captureDeviceFront {
				captureDeviceInputCurrentlyActive = try AVCaptureDeviceInput(device: captureDeviceFront)
				if captureSession.canAddInput(captureDeviceInputCurrentlyActive!) {
					captureSession.addInput(captureDeviceInputCurrentlyActive!)
					captureDeviceCurretlyActive = captureDeviceFront
				}
			}
		}catch{
			print(error)
		}
		// New API to capture photos from iOS 10.0
		if #available(iOS 10.0, *) {
			let photoProcessor = MIPhotoCaptureProcessor()
			photoProcessor.configureSession(captureSession)
			photoCaptureProcessor = photoProcessor
		} else {
			// Fallback on earlier versions
			deviceStillOutput = AVCaptureStillImageOutput()
			deviceStillOutput?.outputSettings = [
				AVVideoCodecKey  : AVVideoCodecJPEG,
			]
			if captureSession.canAddOutput(deviceStillOutput!) {
				captureSession.addOutput(deviceStillOutput!)
			}
		}
		
		videoOutput = AVCaptureVideoDataOutput()
		if captureSession.canAddOutput(videoOutput!) {
			captureSession.addOutput(videoOutput!)
		}
		captureSession.commitConfiguration()
		//Update zoom factor for currently active device.
		updateZoomFactorForActiveDevice()
	}
	
	fileprivate func initializeCaptureDevices() {
		if #available(iOS 10.0, *) {
			func enableLowLightBoostIfAvailableForDevice(_ device:AVCaptureDevice){
				if device.isLowLightBoostSupported {
					do {
						try device.lockForConfiguration()
						device.automaticallyEnablesLowLightBoostWhenAvailable = true
						device.unlockForConfiguration()
					} catch  {
						print(error)
					}
				}
			}
			if #available(iOS 10.2, *) {
				if let dualCamera = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDualCamera, for: AVMediaType.video, position: .back) {
					captureDeviceBack =  dualCamera
					enableLowLightBoostIfAvailableForDevice(dualCamera)
				}
				
			}else{
				if let dualCamera =  AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDuoCamera, for: AVMediaType.video, position: .back){
					captureDeviceBack =  dualCamera
					enableLowLightBoostIfAvailableForDevice(dualCamera)
				}
			}
			if captureDeviceBack == nil {
				//Device does not have dual camera ask for normal wideangle camera.
				if let wideAngelCamera =  AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .back){
					captureDeviceBack =  wideAngelCamera
				}
			}
			captureDeviceFront = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
			
		}else{
			// Fallback on earlier versions
			let devicesAvailable = AVCaptureDevice.devices(for: AVMediaType.video)
			for captureDevice in devicesAvailable {
				if captureDevice.position == .back {
					captureDeviceBack = captureDevice
				}else if captureDevice.position == .front {
					captureDeviceFront = captureDevice
				}
			}
		}
	}
	/// Configures preview view to display video output.
	///
	/// - Parameter viewPreviewView: Object of video preview view.
	func configurePreview(view viewPreviewView:MIVideoPreviewView) {
		
		operationQueueCameraConfiguration.addOperation { [unowned self] in
			DispatchQueue.main.async {
				viewPreviewView.session = self.captureSession
				let previewLayer = viewPreviewView.layer as! AVCaptureVideoPreviewLayer
				previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
			}
		}
	}
	
	/// This method will add observers for session interuption and subject area change.
	fileprivate func addObservers() {
		NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted(_:)), name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded(_:)), name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange(_:)), name: .AVCaptureDeviceSubjectAreaDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(captureSessionRuntimeError(_:)), name: .AVCaptureSessionRuntimeError, object: nil)
	}
	
	// MARK: - Camera configuration change methods
	
	/// Sets orientation for video output.
	///
	/// - Parameter connection: Connection to video output.
	func videoPreviewLayerOrientationUpdate(connection:AVCaptureConnection){
		let orientation = UIDevice.current.orientation
		switch (orientation) {
		case .portrait:
			connection.videoOrientation = .portrait
			break;
		case .portraitUpsideDown:
			connection.videoOrientation = .portraitUpsideDown
			break;
		case .landscapeLeft:
			connection.videoOrientation = .landscapeRight
			break;
		case .landscapeRight:
			connection.videoOrientation = .landscapeLeft
			break;
		default:
			connection.videoOrientation = .portrait
			break;
		}
	}
	
	/// Checks that device has multiple camera to switch between. if yes then returns true else false
	///
	/// - Returns: Returns boolean result.
	func canSwitchCamera() -> Bool {
		if captureDeviceFront != nil && captureDeviceBack != nil {
			return true
		}
		return false
	}
	
	/// Switch between multiple video capture devices. This should be called after checking canSwitchCamera.
	func switchCamera() {
		guard canSwitchCamera() else {
			return
		}
		captureSession.beginConfiguration()
		captureSession.removeInput(captureDeviceInputCurrentlyActive!)
		
		switch (captureDeviceCurretlyActive!.position){
		case .front:
			captureDeviceCurretlyActive = captureDeviceBack
		case .back:
			captureDeviceCurretlyActive = captureDeviceFront
			
		default:
			break
		}
		do{
			captureDeviceInputCurrentlyActive = try AVCaptureDeviceInput(device: captureDeviceCurretlyActive!)
			if captureSession.canAddInput(captureDeviceInputCurrentlyActive!) {
				captureSession.addInput(captureDeviceInputCurrentlyActive!)
				updateZoomFactorForActiveDevice()
			}
		}catch{
			print(error)
		}
		captureSession.commitConfiguration()
	}
	
	/// Updates Flash button visiblity for given capture device. if device has flash then button will be visible else hidden.
	///
	/// - Parameter captureDevice: Device for which flash availablity to check.
	func currentCaptureDeviceHasFlash() -> Bool{
		guard let captureDeviceCurretlyActive = self.captureDeviceCurretlyActive else {return false}
		return captureDeviceCurretlyActive.hasFlash
	}
	
	/// Returns currently active device's flash mode. if any device is not active then returns off.
	///
	/// - Returns: Flash mode.
	func currentCaptureDeviceFlashMode() -> AVCaptureDevice.FlashMode {
		guard let captureDeviceCurretlyActive = self.captureDeviceCurretlyActive else {return .off}
		return captureDeviceCurretlyActive.flashMode
	}
	
	/// Updates flash settings for capture device. it will change various flash modes like auto. on. off.
	///
	/// - Parameters:
	///   - captureDevice: Capture device whose settings to update.
	///   - mode: Current mode to change.
	/// - Returns: Returns value of update result. if settings success then true else false.
	func updateFlashSettingsForCurrentDevice(flashMode mode:AVCaptureDevice.FlashMode) -> Bool{
		guard let captureDeviceCurretlyActive = self.captureDeviceCurretlyActive else {return false}
		if captureDeviceCurretlyActive.hasFlash && captureDeviceCurretlyActive.isFlashModeSupported(mode) {
			do {
				try captureDeviceCurretlyActive.lockForConfiguration()
				captureDeviceCurretlyActive.flashMode = mode
				captureDeviceCurretlyActive.unlockForConfiguration()
				return true
			}catch{
				
			}
		}
		return false
	}
	
	/// Updates pinch gesture maximum value according to currently active device.
	func updateZoomFactorForActiveDevice(){
		guard let maxValue = captureDeviceCurretlyActive?.activeFormat.videoMaxZoomFactor else {
			floatMaxZoomLevel = 1
			return
		}
		floatMaxZoomLevel = min(Float(maxValue),5.0)
	}
	
	/// Focuses to given point on currently active capture device..
	///
	/// - Parameters:
	///   - focusMode: New focus mode
	///   - exposureMode: New exposure mode
	///   - point: point to focus
	///   - monitorSubjectAreaChange: Should monitor subject area change
	func focus(with focusMode:AVCaptureDevice.FocusMode, exposureMode:AVCaptureDevice.ExposureMode, at point:CGPoint, monitorSubjectAreaChange:Bool){
		guard let captureDeviceCurretlyActive = self.captureDeviceCurretlyActive else {return}
		do {
			try captureDeviceCurretlyActive.lockForConfiguration()
			if captureDeviceCurretlyActive.isFocusPointOfInterestSupported && captureDeviceCurretlyActive.isFocusModeSupported(focusMode) {
				captureDeviceCurretlyActive.focusPointOfInterest = point
				captureDeviceCurretlyActive.focusMode = focusMode
			}
			if captureDeviceCurretlyActive.isExposurePointOfInterestSupported && captureDeviceCurretlyActive.isExposureModeSupported(exposureMode) {
				captureDeviceCurretlyActive.exposureMode = exposureMode
				captureDeviceCurretlyActive.exposurePointOfInterest = point
			}
			captureDeviceCurretlyActive.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
			captureDeviceCurretlyActive.unlockForConfiguration()
		}catch{
			print(error)
		}
	}
	
	/// Zoom currently active device. this will check level and maximum zoom device can perform.
	///
	/// - Parameter level: New zoom level.
	func zoomTo(level:Float){
		guard let captureDeviceCurretlyActive = self.captureDeviceCurretlyActive else {return}
		floatCurrentZoomLevel = floatCurrentZoomLevel + atan2f(level, pinchVelocityDividerFactor)
		do {
			try captureDeviceCurretlyActive.lockForConfiguration()
			let floatZoomValue = max(1.0, min(floatCurrentZoomLevel, floatMaxZoomLevel));
			
			captureDeviceCurretlyActive.ramp(toVideoZoomFactor: CGFloat(floatZoomValue), withRate: 7)
			captureDeviceCurretlyActive.unlockForConfiguration()
		}catch{
			print(error.localizedDescription)
		}
	}
	
	func isCaptureDeviceActive() -> Bool{
		if captureDeviceCurretlyActive != nil && captureDeviceCurretlyActive!.isConnected {
			return true
		}
		return false
	}
	func startCameraSession(){
		operationQueueCameraConfiguration.addOperation { [weak self] in
			self?.captureSession.startRunning()
		}
	}
	// MARK: - Capture photo
	/// This method will capture image for currently active capture device.
	///
	/// - Parameter completionHandler: Called once capture finished. if any error then nil.
	func capturePhoto(completionHandler:@escaping (UIImage?,NSMutableDictionary?,Error?)->Void) {
		guard isCaptureDeviceActive() else {
			let error = NSError(domain: "photoConvert", code: 999, userInfo: [NSLocalizedDescriptionKey:"Unable to Capture image. Capture device not available."])
			completionHandler(nil,nil,error)
			return
		}
		if #available(iOS 10.0, *) {
			let photoProcessor = photoCaptureProcessor as! MIPhotoCaptureProcessor
			let captureSettings = AVCapturePhotoSettings()
			
			captureSettings.flashMode = currentCaptureDeviceFlashMode()
			captureSettings.isHighResolutionPhotoEnabled = true
			
			photoProcessor.capturePhoto(with: captureSettings,orientation: AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue)!, completionHandler: { (imageData,metadata, error) in
				DispatchQueue.main.async {
					guard error == nil else{
						completionHandler(nil,nil,error!)
						return
					}
					if let imageCaptured = UIImage(data: imageData!) {
						completionHandler(imageCaptured,metadata,nil)
					}else{
						let error = NSError(domain: "photoConvert", code: 999, userInfo: [NSLocalizedDescriptionKey:"Unable to Capture image. Please try again."])
						completionHandler(nil,nil,error)
					}
				}
			})
		} else {
			if let connection = deviceStillOutput?.connection(with: AVMediaType.video) {
				connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue)!
				
				self.deviceStillOutput!.captureStillImageAsynchronously(from: connection) {
					(imageDataSampleBuffer, error) -> Void in
					DispatchQueue.main.async {
						guard error == nil else {
							completionHandler(nil,nil,error! as NSError)
							return
						}
						guard let imageDataSampleBuffer = imageDataSampleBuffer,let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer),let imageCaptured = UIImage(data: imageData) else {
							let errorObj = NSError(domain: "photoConvert", code: 999, userInfo: [NSLocalizedDescriptionKey:"Unable to Convert captured data to image. Please try again."])
							completionHandler(nil,nil,errorObj)
							return
						}
						let metaData = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate)
						let mutableMetadata = NSMutableDictionary(dictionary: metaData!)
						mutableMetadata.removeObject(forKey: "Orientation")
						completionHandler(imageCaptured,mutableMetadata,nil)
					}
				}
				return
			}
			let error = NSError(domain: "photoConvert", code: 999, userInfo: [NSLocalizedDescriptionKey:"Unable to Capture image. Please try again."])
			completionHandler(nil,nil,error)
		}
	}
	
	//MARK: - Notificatoin observers
	
	@objc func sessionWasInterrupted(_ notification:Notification){
		guard captureSession.isInterrupted else {return}
		var message:String = "The camera session is interrupted due to unknown reason."
		
		guard let userInfo = notification.userInfo,let reasonCode = userInfo[AVCaptureSessionInterruptionReasonKey] as? Int, let reason = AVCaptureSession.InterruptionReason(rawValue: reasonCode) else {
			notifyInterruption(with: message)
			return
		}
		
		switch reason {
		case .audioDeviceInUseByAnotherClient,.videoDeviceInUseByAnotherClient:
			message = "The iPhone camera is being used by another application. Application will resume camera when it has access to camera."
		case .videoDeviceNotAvailableInBackground:
			//			message = "The camera is not available while applications running in the background."
			//No need to report this interuption as it will not be visible to user as app is in background.
			return
		case .videoDeviceNotAvailableWithMultipleForegroundApps:
			message = "The camera is not available while multiple applications running in the foreground."
		case .videoDeviceNotAvailableDueToSystemPressure:
			message = "The camera is not available due to system pressure."
		}
		notifyInterruption(with: message)
	}
	
	@objc func sessionInterruptionEnded(_ notification:Notification){
		guard !captureSession.isInterrupted else {return}
		notifyInterruptionEnd()
	}
	@objc func captureSessionRuntimeError(_ notification:Notification){
		let message:String
		if let error = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError {
			message = error.localizedDescription
		}else{
			message = "The camera capture session is not available due to a runtime error."
		}
		notifyInterruption(with: message)
	}
	
	@objc func subjectAreaDidChange(_ notification:Notification){
		let devicePoint = CGPoint(x: 0.5, y: 0.5)
		focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
	}
}

// MARK: - Delegate notifiers

extension MICameraManager {
	
	fileprivate func notifyDelegateOfAuthorization(){
		let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
		operationQueueCameraConfiguration.addOperation {
			DispatchQueue.main.async {[weak self] in
				self?.delegate?.cameraPermissionDidChange(status: authorizationStatus)
			}
		}
	}

	fileprivate func notifyInterruption(with message:String){
		operationQueueCameraConfiguration.addOperation {
			DispatchQueue.main.async { [weak self] in
				self?.delegate?.cameraSessionInterrupted(message: message)
			}
		}
	}
	
	fileprivate func notifyInterruptionEnd(){
		operationQueueCameraConfiguration.addOperation {
			DispatchQueue.main.async { [weak self] in
				self?.delegate?.cameraSessionInterruptionEnded()
			}
		}
	}
}

protocol MICameraManagerDelgate:NSObjectProtocol {
	func cameraPermissionDidChange(status:AVAuthorizationStatus)
	func cameraSessionInterrupted(message:String)
	func cameraSessionInterruptionEnded()
}
