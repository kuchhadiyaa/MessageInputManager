//
//  MIExifContainer.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import CoreLocation
import ImageIO

class MIExifContainer {
	
	// MARK: - Variables
	
	fileprivate let imageMetadata:NSMutableDictionary
	
	// MARK: - Life cycle methods
	
	init(with metaDataDictionary:NSMutableDictionary) {
		imageMetadata = metaDataDictionary
	}
	
}

// MARK: - GPS Support

extension MIExifContainer {

	var gpsDictionary:NSMutableDictionary {
		return dictionaryFor(key: kCGImagePropertyGPSDictionary as String)
	}
	func add(location:CLLocation) {
		let latitude = location.coordinate.latitude
		let longitude = location.coordinate.longitude
		
		let latitudeRef:String
		let longitudeRef:String
		
		if (latitude < 0.0) {
			latitudeRef = "S"
		} else {
			latitudeRef = "N"
		}
		
		if (longitude < 0.0) {
			longitudeRef = "W"
		} else {
			longitudeRef = "E"
		}
		let gpsDictionary = self.gpsDictionary
		
		gpsDictionary[kCGImagePropertyGPSTimeStamp as String] = getUTCFormated(date: location.timestamp)
		
		gpsDictionary[kCGImagePropertyGPSLatitudeRef as String] = latitudeRef
		gpsDictionary[kCGImagePropertyGPSLatitude as String] = NSNumber(value: latitude)

		gpsDictionary[kCGImagePropertyGPSLongitudeRef as String] = longitudeRef
		gpsDictionary[kCGImagePropertyGPSLongitude as String] = NSNumber(value: longitude)
		
		gpsDictionary[kCGImagePropertyGPSDOP as String] = NSNumber(value: location.horizontalAccuracy)
		gpsDictionary[kCGImagePropertyGPSAltitude as String] = NSNumber(value: location.altitude)
		
	}

}

// MARK: - Helper methods

extension MIExifContainer {
	
	func getMetadata() -> NSDictionary {
		return imageMetadata
	}
	
	func dictionaryFor(key:String) -> NSMutableDictionary{
		guard let dictionary = imageMetadata[key] as? NSMutableDictionary else {
			let dictionary = NSMutableDictionary()
			imageMetadata[key] = dictionary
			return dictionary
		}
		return dictionary
	}
	func getUTCFormated(date:Date) ->String {
		//TODO: Date formatter
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
		return dateFormatter.string(from: date)
	}
}
