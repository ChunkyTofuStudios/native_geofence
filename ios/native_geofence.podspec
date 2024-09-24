#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint native_geofence.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'native_geofence'
  s.version          = '1.0.0'
  s.summary          = 'iOS implementation for the Flutter native_geofence plugin.'
  s.description      = <<-DESC
Battery efficient Flutter Geofencing that uses native iOS and Android APIs.
                       DESC
  s.homepage         = 'https://chunkytofustudios.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Chunky Tofu Studios' => 'supportl@chunkytofustudios.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'hello_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
