Pod::Spec.new do |s|
  s.name             = 'PodDemo'
  s.version          = '0.1.0'
  s.summary          = 'A short description of PodDemo.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/wangzhizhou/PodDemo'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wangzhizhou' => 'wangzhizhou@bytedance.com' }
  s.source           = { :git => 'https://github.com/wangzhizhou/PodDemo.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.source_files = 'PodDemo/Classes/**/*'
  
  # spm dep
  # s.spm_dependency 'MacroDemo/MacroDemo'
  # prebuild dep
  s.dependency 'MacroDemo'
end
