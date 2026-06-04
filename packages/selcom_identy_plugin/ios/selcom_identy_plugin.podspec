# #
# # To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# # Run `pod lib lint selcom_identy_plugin.podspec` to validate before publishing.
# #
# Pod::Spec.new do |s|
#   s.name             = 'selcom_identy_plugin'
#   s.version          = '0.0.1'
#   s.summary          = 'A new Flutter plugin project.'
#   s.description      = <<-DESC
# A new Flutter plugin project.
#                        DESC
#   s.homepage         = 'http://example.com'
#   s.license          = { :file => '../LICENSE' }
#   s.author           = { 'Your Company' => 'email@example.com' }
#   s.source           = { :path => '.' }
#   s.source_files = 'Classes/**/*'
#   s.dependency 'Flutter'
#   s.platform = :ios, '12.0'

#   # Flutter.framework does not contain a i386 slice.
#   s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
#   s.swift_version = '5.0'

#   # If your plugin requires a privacy manifest, for example if it uses any
#   # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
#   # plugin's privacy impact, and then uncomment this line. For more information,
#   # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
#   # s.resource_bundles = {'selcom_identy_plugin_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
# end

# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint selcom_identy_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'selcom_identy_plugin'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  # s.source           = { 
  #   :git => 'https://github.com/your_repository.git', # replace with your actual repo
  #   :tag => s.version.to_s,
  #   :sources => ['cocoapods-identy-finger']
  # }
  s.source           = { :path => 'https://github.com/CocoaPods/Specs.git' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Identy', '6.3.0'      # Add Identy dependency
  s.dependency 'CryptoSwift'            # Add CryptoSwift dependency
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain an i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'selcom_identy_plugin_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
