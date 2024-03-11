# Uncomment the next line to define a global platform for your project
platform :ios, '10.1'

target 'WayBackMachine' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for WayBackMachine
  pod 'Alamofire', '~> 4.9'
  pod 'MBProgressHUD', '1.1.0'
  pod 'FRHyperLabel'
  pod 'UITextView+Placeholder', '~> 1.2'

end

target 'WM' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for WM
  pod 'Alamofire', '~> 4.9'
  pod 'MBProgressHUD', '1.1.0'
  pod 'FRHyperLabel'
  pod 'UITextView+Placeholder', '~> 1.2'
  pod 'IQKeyboardManagerSwift'

#  target 'WMTests' do
#    inherit! :search_paths
#    # Pods for testing
#  end
#
#  target 'WMUITests' do
#    inherit! :search_paths
#    # Pods for testing
#  end

end

# fixes compiler error with older iOS version by updating min deployment in all pods
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "12.0"
    end
  end
end
