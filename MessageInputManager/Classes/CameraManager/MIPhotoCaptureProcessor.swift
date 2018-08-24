//
//  MIPhotoCaptureProcessor.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import Foundation
import AVFoundation

@available(iOS 10.0, *)
// MARK: - MIPhotoCaptureProcessor
///MIPhotoCaptureProcessor class manages all the operations related to photo capture api.
final class MIPhotoCaptureProcessor:NSObject{
    
    // MARK: - Variables
    typealias PhotoCaptureCompletionHandler = ((Data?,NSMutableDictionary?,Error?) -> Void)
    fileprivate var captureCompletionHanlder:PhotoCaptureCompletionHandler?
    fileprivate let photoOutput = AVCapturePhotoOutput()
    
    // MARK: - Initializer methods
    override init() {
        super.init()
        photoOutput.isHighResolutionCaptureEnabled = true
    }
	
    // MARK: - Photo capture methods
    
    /// This method will capture photo using current session. Provide settings for photo and orientation and Handler will be invoked when operation finishes with photo or error.
    ///
    /// - Parameters:
    ///   - captureSettings: Photo capture settings
    ///   - orientation: Orientation of photo
    ///   - completionHandler: Handler will be invoked at capture end.
    func capturePhoto(with captureSettings:AVCapturePhotoSettings,orientation:AVCaptureVideoOrientation,completionHandler:@escaping PhotoCaptureCompletionHandler) {
		photoOutput.connection(with: AVMediaType.video)?.videoOrientation = orientation
        captureCompletionHanlder = completionHandler
        photoOutput.capturePhoto(with: captureSettings, delegate: self)
    }
    
    // MARK: - Helper
    
    /// Configure session to be used by CapturePhotoOutput. without calling this method capturePhoto will result in error.
    ///
    /// - Parameter session: Session to be configured 
    func configureSession(_ session:AVCaptureSession) {
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
    }
}


// MARK: - AVCapturePhotoCaptureDelegate methods
@available(iOS 10.0, *)
extension MIPhotoCaptureProcessor:AVCapturePhotoCaptureDelegate {
	
	func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        guard error == nil else {
            captureCompletionHanlder?(nil,nil,error)
            return
        }
        guard let photoSampleBuffer = photoSampleBuffer,let photoData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
            let photoCaptureError = NSError(domain: "photoCapture", code: 999, userInfo: [NSLocalizedDescriptionKey:"Unable to Capture image. Please try again."])
            captureCompletionHanlder?(nil,nil,photoCaptureError)
            return
        }
		
		let metaData = CMCopyDictionaryOfAttachments(nil, photoSampleBuffer, kCMAttachmentMode_ShouldPropagate)
		let mutableMetadata = NSMutableDictionary(dictionary: metaData!)
		mutableMetadata.removeObject(forKey: "Orientation")

		captureCompletionHanlder?(photoData,mutableMetadata,nil)
    }
}
