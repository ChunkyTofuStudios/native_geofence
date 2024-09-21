#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint geofencing.podspec' to validate before publishing.
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
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
