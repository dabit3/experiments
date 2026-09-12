require 'xcodeproj'

root = File.expand_path('..', __dir__)
project = Xcodeproj::Project.new(File.join(root, 'SnowglobeExpress.xcodeproj'))
app = project.new_target(:application, 'SnowglobeExpress', :ios, '17.0')
tests = project.new_target(:unit_test_bundle, 'SnowglobeExpressTests', :ios, '17.0')
tests.add_dependency(app)

sources = project.main_group.new_group('SnowglobeExpress', 'SnowglobeExpress')
Dir.glob(File.join(root, 'SnowglobeExpress', '*.swift')).sort.each do |path|
  app.source_build_phase.add_file_reference(sources.new_file(File.basename(path)))
end
['Assets.xcassets', 'delivery.wav'].each do |name|
  app.resources_build_phase.add_file_reference(sources.new_file(name))
end
test_group = project.main_group.new_group('SnowglobeExpressTests', 'SnowglobeExpressTests')
Dir.glob(File.join(root, 'SnowglobeExpressTests', '*.swift')).sort.each do |path|
  tests.source_build_phase.add_file_reference(test_group.new_file(File.basename(path)))
end

[app, tests].each do |target|
  target.build_configurations.each do |config|
    config.build_settings.merge!({
      'SWIFT_VERSION' => '5.0',
      'CODE_SIGNING_ALLOWED' => 'NO',
      'GENERATE_INFOPLIST_FILE' => 'YES',
      'TARGETED_DEVICE_FAMILY' => '1,2',
      'IPHONEOS_DEPLOYMENT_TARGET' => '17.0',
      'PRODUCT_BUNDLE_IDENTIFIER' => "com.nader.snowglobeexpress#{target == tests ? '.tests' : ''}",
      'SWIFT_EMIT_LOC_STRINGS' => 'YES'
    })
  end
end
app.build_configurations.each do |config|
  config.build_settings.merge!({
    'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon',
    'INFOPLIST_KEY_CFBundleDisplayName' => 'Snowglobe Express',
    'INFOPLIST_FILE' => 'SnowglobeExpress/Info.plist',
    'INFOPLIST_KEY_UIApplicationSceneManifest_Generation' => 'YES',
    'INFOPLIST_KEY_UISupportedInterfaceOrientations' => 'UIInterfaceOrientationPortrait',
    'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad' => 'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight',
    'MARKETING_VERSION' => '1.0',
    'CURRENT_PROJECT_VERSION' => '1'
  })
end
tests.build_configurations.each do |config|
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/SnowglobeExpress.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/SnowglobeExpress'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
end
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.set_launch_target(app)
scheme.add_test_target(tests)
scheme.save_as(project.path, 'SnowglobeExpress', true)
project.save
puts "Generated #{project.path}"
