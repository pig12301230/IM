#for fix: CocoaPods CDN repo update failure
source 'https://github.com/CocoaPods/Specs.git'

project 'ChatRoom.xcodeproj'
platform :ios, '13.0'
use_frameworks!

def network
  pod 'Alamofire', '5.4.3'              # Restful API
  pod 'Starscream', '4.0.4'             # WebSocket
  pod 'Kingfisher', '5.9.0'             # download Image
  pod 'ReachabilitySwift', '5.0.0'      # check connection
  pod 'SwiftyJSON', '5.0.1'             # deal with JSON data
end

def rx
  pod 'RxSwift', '6.1.0'
  pod 'RxCocoa', '6.1.0'
end

def layout
  pod 'SnapKit', '5.0.1'                # layout
  pod 'SwiftTheme', '0.6.0'             # color style
end

def keyboard
  pod 'IQKeyboardManagerSwift', '6.0.4'
end

def animation
  pod 'lottie-ios', '3.2.1'
end

def database
  pod 'RealmSwift', '10.33.0'
end

def phone
  pod 'libPhoneNumber-iOS', '0.9.15'
end
  
def lint
  pod 'SwiftLint', '0.43.1', :configurations => ['chat_DEV']
end

def sentry
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '7.27.0'
end

def file
  pod 'ZIPFoundation', '0.9.11', :configurations => ['chat_DEV', 'chat_UAT']
end

def common_library
  network
  rx
  layout
  keyboard
  animation
  database
  phone
  lint
  sentry
  file
end

target "GuChat" do
  common_library
end

target "MeeChat" do
  common_library
end

target "365Chat" do
  common_library
end

target "WinstonTest" do
  common_library
end

target "ChatRoomTests" do
  file
end


post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '5.0'
            config.build_settings['DYLIB_COMPATIBILITY_VERSION'] = ''
            config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
        end
    end
end

