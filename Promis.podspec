#
# Be sure to run `pod lib lint Promis.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Promis'
  s.version          = ENV['LIB_VERSION']
  s.summary          = 'The easiest Future and Promises framework in Swift. No magic. No boilerplate.'
  s.description      = <<-DESC
The easiest Future and Promises framework in Swift. No magic. No boilerplate.
- Fully unit-tested and documented 💯
- Thread-safe 🚦
- Clean interface 👼
- Support for chaining ⛓
- Support for cancellation 🙅‍♂️
- Queue-based block execution if needed 🚆
- Result type provided via generics 🚀
- Keeping the magic to the minimum, leaving the code in a readable state without going off of a tangent with fancy and unnecessary design decisions ಠ_ಠ
                       DESC

  s.homepage         = 'https://github.com/albertodebortoli/Promis'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alberto De Bortoli' => 'albertodebortoli.com' }
  s.source           = { :git => 'https://github.com/albertodebortoli/Promis.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/albertodebo'

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  s.source_files = 'Framework/Sources/**/*.swift'
  s.frameworks = 'Foundation'

  s.test_spec 'UnitTests' do |test_spec|
    test_spec.source_files = 'Tests/Sources/**/*.swift'
  end
end
