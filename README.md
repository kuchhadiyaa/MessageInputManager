# MessageInputManager

[![CI Status](https://img.shields.io/travis/kuchhadiyaa/MessageInputManager.svg?style=flat)](https://travis-ci.org/kuchhadiyaa/MessageInputManager)
[![Version](https://img.shields.io/cocoapods/v/MessageInputManager.svg?style=flat)](https://cocoapods.org/pods/MessageInputManager)
[![License](https://img.shields.io/cocoapods/l/MessageInputManager.svg?style=flat)](https://cocoapods.org/pods/MessageInputManager)
[![Platform](https://img.shields.io/cocoapods/p/MessageInputManager.svg?style=flat)](https://cocoapods.org/pods/MessageInputManager)

MessageInputManager is drop in copy of iMessage message input. MessageInputManager allows users to enter text message as well as media messages. It allows to capture photo directly from the place and allows to capture photo or select photo using UIImagePickerController.


## Requirements

- iOS 9.0+
- Xcode 9.4+ (Did not tested on older versions.)
- Swift 4.0+

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Screenshots

<img width="50%" height="50%" src="https://raw.githubusercontent.com/kuchhadiyaa/MessageInputManager/master/Screenshots/SS1.PNG" /><img width="50%" height="50%" src="https://raw.githubusercontent.com/kuchhadiyaa/MessageInputManager/master/Screenshots/SS2.PNG" />

## Installation

MessageInputManager is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'MessageInputManager'
```

## Usage

Use it as input accessory view to ```UIView``` which handles chat details or where user input is required

To make ```UIView``` first responder, Subclass ```UIView``` and return true from ```canBecomeFirstResponder```.

Then Return ```MIMessageInputView``` as input accessory view.

```Swift4
class ConversationDetailView: UIView {

	// MARK: - Variables
	let messageInputView:MIMessageInputView = MIMessageInputView()
	
	// MARK: - Life cycle methods
	
	override var canBecomeFirstResponder: Bool{
		return true
	}
	override var inputAccessoryView: UIView?{
		return messageInputView
	}

}
```

```UIViewController``` can also become first responder and ```MIMessageInputView``` can be returned as accessory view.

Set delegate to ```MIMessageInputView``` where you want to receive call when user press send with all the details.

## Author

Akshay Kuchhadiya, akshay@atominc.in

## License

MessageInputManager is available under the MIT license. See the LICENSE file for more info.
