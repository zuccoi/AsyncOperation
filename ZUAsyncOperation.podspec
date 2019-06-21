Pod::Spec.new do |spec|
  spec.name = "ZUAsyncOperation"
  spec.version = "1.1"
  spec.summary = "Generic subclass of Operation to get result asynchronously."
  spec.description = <<-DESC
  AsyncOperation is a generic subclass of Operation to get Swift.Result asynchronously.
                   DESC
  spec.homepage = "https://github.com/zuccoi/AsyncOperation"
  spec.license = { :type => "MIT", :file => "LICENSE" }
  spec.author = "zuccoi"
  spec.social_media_url = "https://twitter.com/zuccoi"
  spec.ios.deployment_target = "11.0.1"
  # spec.osx.deployment_target = "10.7"
  # spec.watchos.deployment_target = "2.0"
  # spec.tvos.deployment_target = "9.0"
  spec.source_files = "AsyncOperation/AsyncOperation/Source/*.{swift}"
  spec.source = {
	  :git => "https://github.com/zuccoi/AsyncOperation.git",
	  :tag => "#{spec.version}",
  }
  spec.swift_version = "5.0"
end
