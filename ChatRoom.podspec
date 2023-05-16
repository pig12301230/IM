Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '12.0'
s.name = "ChatRoom"
s.summary = "Winstonnnnn."
s.requires_arc = true

# 2
s.version = "0.1.1"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Winnnn" => "xxx@gmail.com" }

# 5 - Replace this URL with your own GitHub page's URL (from the address bar)
s.homepage = "https://github.com/pig12301230/"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/pig12301230/IM.git", 
             :branch => "main",
             :tag => "#{s.version}" }

# 7
s.framework = "UIKit"
s.dependency 'Alamofire', '5.4.3'              # Restful API
s.dependency 'Starscream', '4.0.4'             # WebSocket
s.dependency 'Kingfisher', '5.9.0'             # download Image
s.dependency 'ReachabilitySwift', '5.0.0'      # check connection
s.dependency 'SwiftyJSON', '5.0.1'             # deal with JSON data
s.dependency 'RxSwift', '6.1.0'
s.dependency 'RxCocoa', '6.1.0'
s.dependency 'SnapKit', '5.0.1'                # layout
s.dependency 'SwiftTheme', '0.6.0'             # color style
s.dependency 'IQKeyboardManagerSwift', '6.0.4'
s.dependency 'lottie-ios', '3.2.1'
s.dependency 'RealmSwift', '10.33.0'
s.dependency 'libPhoneNumber-iOS', '0.9.15'
s.dependency 'SwiftLint', '0.43.1'
s.dependency 'Sentry'
s.dependency 'ZIPFoundation', '0.9.11'

# 8
s.source_files = "ChatRoom/**/*.{swift}"

# 9
s.resources = "ChatRoom/**/*.{png,jpeg,jpg,storyboard,xib,xcassets}"

# 10
s.swift_version = "4.2"

end