#

Pod::Spec.new do |s|
	#Summary
  s.name             = 'MessageInputManager'
  s.summary          = 'iMessage style chat message input controller. '
  s.description      =

	#Version and deployment info
	s.version          = '1.0.0'
  spec.swift_version = '4.0'
	spec.ios.deployment_target  = '9.0'
	
	#Source and Licence
  s.homepage         = 'https://github.com/kuchhadiyaa/MessageInputManager'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Akshay Kuchhadiya' => 'akshay@atominc.in' }
  s.source           = { :git => 'https://github.com/kuchhadiyaa/MessageInputManager.git', :tag => s.version.to_s }
	s.source_files = 'MessageInputManager/Classes/**/*'
	
	#Social media links
  s.social_media_url = 'https://twitter.com/anonymous_akkii'
  s.social_media_url = ''
  
  # s.resource_bundles = {
  #   'MessageInputManager' => ['MessageInputManager/Assets/*.png']
  # }

	#Framework dependancy
  # s.public_header_files = 'Pod/Classes/**/*.h'
	s.frameworks = 'UIKit','Photos'
  # s.dependency 'AFNetworking', '~> 2.3'
end
