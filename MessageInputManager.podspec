#

Pod::Spec.new do |s|
	#Summary
  	s.name             = 'MessageInputManager'
  	s.summary          = 'iMessage style chat message input controller. '
  	s.description      = 'MessageInputManager provides Chat input view which allows users to input text message, and media message similar to Apple iMessage app. It Allows users to select images from user\' Camera Roll album and allows to Capture photo using native camera inline.'

	#Version and deployment info
	s.version                  = '1.0.0'
	s.ios.deployment_target    = '9.0'
    s.swift_version            = '4.0'
	s.platform     		       = :ios, "9.0"

	#Source and Licence
  	s.homepage         = 'https://github.com/kuchhadiyaa/MessageInputManager'
  	s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  	s.license          = { :type => 'MIT', :file => 'LICENSE' }
  	s.author           = { 'Akshay Kuchhadiya' => 'akshay@atominc.in' }
  	s.source           = { :git => 'https://github.com/kuchhadiyaa/MessageInputManager.git', :tag => s.version }
	s.source_files = 'MessageInputManager/Classes/**/*'

	#Social media links
  	s.social_media_url = 'https://www.twitter.com/anonymous_akkii'

	s.resource_bundles = {
	 'MessageInputManager' => ['MessageInputManager/Assets/**/*.*']
	}

	#Framework dependancy
  # s.public_header_files = 'Pod/Classes/**/*.h'
	s.frameworks = 'UIKit','Photos'
  # s.dependency 'AFNetworking', '~> 2.3'
end
