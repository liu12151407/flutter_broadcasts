#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_broadcasts.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_broadcasts'
  s.version          = '0.4.0'
  s.summary          = 'A plugin for sending and receiving broadcasts with Android intents and iOS notifications.'
  s.description      = <<-DESC
A plugin for sending and receiving broadcasts with Android intents and iOS notifications.
                       DESC
  s.homepage         = 'https://github.com/kevlatus/flutter_broadcasts'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'kevlatus' => 'https://github.com/kevlatus' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
