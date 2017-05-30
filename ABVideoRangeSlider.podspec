#
# Be sure to run `pod lib lint ABVideoRangeSlider.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ABVideoRangeSlider'
  s.version          = '0.1.6'
  s.summary          = 'A simple range slider for trimming videos.'
  s.description      = 'Range slider that displays thumbnails for trimming videos in iOS. Includes a Progress Indicator.'
  s.homepage         = 'https://github.com/AppsBoulevard/ABVideoRangeSlider'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Oscar J. Irun' => 'oscarjiv91@gmail.com' }
  s.source           = { :git => 'https://github.com/obaskanderi/ABVideoRangeSlider.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'ABVideoRangeSlider/Classes/**/*', 'ABVideoRangeSlider/Assets/*'
  s.resource_bundles = {
    'ABVideoRangeSlider' => ['ABVideoRangeSlider/Assets/*.png']
  }
end
