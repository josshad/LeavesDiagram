# LeavesDiagram

## Installation
### Swift PM
Add package dependency to the your xcode project or package file

Package.swift:
```swift
dependencies: [
    .package(url: "git@github.com:josshad/LeavesDiagram.git", "0.0.0"..."0.1.0")
 ]
```

Xcode project:
* Select project in Project Navigator
* Select your project in main window
* Go to `Package dependencies` tab
* Tap on `+` and enter `git@github.com:josshad/LeavesDiagram.git` into search fiel
* Make version or branch dependencies

### CocoaPods
To install LeavesDiagram using CocoaPods, please integrate it in your existing Podfile, or create a new Podfile:

```ruby
target 'MyApp' do
  pod 'LeavesDiagram'
end
```
Then run `pod install`.

### Manual
Add files from `Sources/LeavesDiagram` to your project

