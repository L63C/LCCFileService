#
# Be sure to run `pod lib lint LCCFileService.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
# pod repo push l63Specs LCCFileService.podspec --use-libraries --allow-warnings



Pod::Spec.new do |s|
  s.name             = 'LCCFileService'
  s.version          = '0.1.0'
  s.summary          = '一款可扩展的，具有队列控制的，文件上传，下载，存储等服务.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
- 支持断点续传
- 支持断点下载
- 大文件分片上传
- 最大同时上传，下载队列可控
- 上传，下载，进度多种方式监听
                       DESC

  s.homepage         = 'https://github.com/L63C/LCCFileService'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lu63chuan@163.com' => 'lu63chuan@163.com' }
  s.source           = { :git => 'https://github.com/L63C/LCCFileService.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'LCCFileService/Classes/**/*'
  
  # s.resource_bundles = {
  #   'LCCFileService' => ['LCCFileService/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
   s.dependency 'WCDB'
   s.dependency 'AWSS3'
end
