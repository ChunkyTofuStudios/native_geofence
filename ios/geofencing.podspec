#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint geofencing.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'geofencing'
  s.version          = '0.0.1'
  s.summary          = 'CloudAlerts flutter Geofencing plugin.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://cloudalert.e'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'CloudAlert B.V.' => 'supportl@cloudalert.eu' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
