//
//  MIExifContainer.swift
//  MessageInputManager
//
//  Created by Akshay Kuchhadiya on 22/08/18.
//

import CoreLocation
import ImageIO

/// Class representing exif dictionary wrapper.
class MIExifContainer {
	
	// MARK: - Variables
	
	/// All metadata container.
	fileprivate let imageMetadata:NSMutableDictionary
	
	// MARK: - Life cycle methods
	
	/// Initialize with metadata
	///
	/// - Parameter metaDataDictionary: Metadata
	init(with metaDataDictionary:NSMutableDictionary) {
		imageMetadata = metaDataDictionary
	}
	
}

// MARK: - GPS Support

extension MIExifContainer {

	/// Returns GPS metadata dictionary
	var gpsDictionary:NSMutableDictionary {
		return dictionaryFor(key: kCGImagePropertyGPSDictionary as String)
	}
	
	/// Add GPS metadata dictionary. this will replace existing if any with new dictionary and location data.
	///
	/// - Parameter location: Location
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
	
	/// Return metadata
	///
	/// - Returns: Dictionary of metadata
	func getMetadata() -> NSDictionary {
		return imageMetadata
	}
	
	/// Return metadata dictionary for given metadata key. if for given key metadata is not exist this will create one and return empty dictionary.
	///
	/// - Parameter key: Key for which metadata dictionary required.
	/// - Returns: Metadata for given key.
	func dictionaryFor(key:String) -> NSMutableDictionary{
		guard let dictionary = imageMetadata[key] as? NSMutableDictionary else {
			let dictionary = NSMutableDictionary()
			imageMetadata[key] = dictionary
			return dictionary
		}
		return dictionary
	}
	
	/// Converts given data into UTC format string.
	///
	/// - Parameter date: Date to be converted
	/// - Returns: String from date in UTC format.
	func getUTCFormated(date:Date) ->String {
		dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
		return dateFormatter.string(from: date)
	}
}

fileprivate let dateFormatter = DateFormatter()
