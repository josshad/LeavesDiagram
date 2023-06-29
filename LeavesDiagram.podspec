Pod::Spec.new do |s|
  s.name             = 'LeavesDiagram'
  s.version          = '0.2'
  s.summary          = 'Custom pie chart diagram'
  s.swift_versions   = '5.0'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Animated pie diagram component
                       DESC

  s.homepage         = 'https://github.com/josshad/LeavesDiagram'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Danila Gusev' => 'josshad@gmail.com' }
  s.source           = { :git => 'https://github.com/josshad/LeavesDiagram.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/**/*'
end
