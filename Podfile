# Podfile for VroongFriends iOS
platform :ios, '17.0'
use_frameworks!
inhibit_all_warnings!

# CocoaPods optimization
install! 'cocoapods',
  :deterministic_uuids => false,
  :generate_multiple_pod_projects => true

target 'VroongFriends' do
  # Map SDKs (SPM 미지원)
  pod 'NMapsMap'  # 네이버 맵
  pod 'KakaoMapsSDK'  # 카카오 맵

  # SendBird Chat SDK
  # CocoaPods가 더 안정적인 경우가 있어 여기서 관리
  pod 'SendBirdSDK'

  # 결제 SDK (만약 필요한 경우)
  # pod 'iamport-ios'  # 아임포트 결제

  target 'VroongFriendsTests' do
    inherit! :search_paths
    # Test-specific pods if needed
  end
end

# Post install script for build settings
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # iOS 17 deployment target
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'

      # Enable module stability
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'

      # Suppress warnings for third-party code
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'

      # Optimize for build time
      if config.name == 'Debug'
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
        config.build_settings['SWIFT_COMPILATION_MODE'] = 'singlefile'
      end
    end
  end

  # Fix Xcode 15 warnings
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
      end
    end
  end
end