# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'
source 'https://github.com/CocoaPods/Specs.git'
target 'ControlUsageLib' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ControlUsageLib
  pod 'AvoidCrash', '~> 2.5.2'
  #响应式函数框架
  pod 'RxSwift', '~>5.1.0'
  pod 'RxCocoa', '~>5.1.0'
  #约束
  pod 'SnapKit'
  #rxswift的数据源
  pod 'RxDataSources'
  #XML解析
  pod 'SWXMLHash', '~> 7.0.0'
  #ORM数据库
  pod 'WCDB.swift'
  #JSON序列化，反序列化
  pod 'HandyJSON', '~> 5.0.2'
  #压缩、解压文件
  pod 'SSZipArchive', '~> 2.4.3'
  # 调试用
  pod 'FLEX', :configurations => ['Debug']
end

deployment_target = '13.0'
post_install do |installer|
    installer.generated_projects.each do |project|
        project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = deployment_target
            end
        end
        project.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = deployment_target
        end
    end
end
