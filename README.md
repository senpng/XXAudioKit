# XXAudioKit

XXAudioKit is a simple class for audio playing and the audio recording apps.

![XXAudioKit](XXAudioKit.gif)

## Usage

### Creat a new XXAudioPlaybackViewController
```
swift    
// Initialize
let audioPlaybackVC = XXAudioPlaybackViewController()

// Configuration properties
audioPlaybackVC.buttonTintColor = UIColor.orangeColor()
audioPlaybackVC.waveColor = UIColor.orangeColor()

// present in current viewController
audioPlaybackVC.presentInViewController(self, animated: true, completion: nil)
```
#### The XXAudioRecorderViewController delelgate
```
// MARK: - AVAudioPlayerDelegate
    public func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        status = .CompletePlayback;
    }
    
    public func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        
    }
    
    public func audioPlayerBeginInterruption(player: AVAudioPlayer) {
        
    }
    
    public func audioPlayerEndInterruption(player: AVAudioPlayer) {
        
    }
    
    public func audioPlayerEndInterruption(player: AVAudioPlayer, withFlags flags: Int) {
        
    }
    
    public func audioPlayerEndInterruption(player: AVAudioPlayer, withOptions flags: Int) {
        
    }

```

### Creat a new XXAudioRecorderViewController


```
swift    
// Initialize
let audioRecorderVC = XXAudioRecorderViewController(audioFilePath: "")

// Configuration properties
audioRecorderVC.buttonTintColor = UIColor.orangeColor()
audioRecorderVC.waveColor = UIColor.orangeColor()

// present in current viewController
audioRecorderVC.presentInViewController(self, animated: true, completion: nil)
```
#### The XXAudioRecorderViewController delegate

``` 
// MARK: - AVAudioPlayerDelegate
    public func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        status = .CompletePlayback;
    }
    
    public func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        
    }
    
    public func audioPlayerBeginInterruption(player: AVAudioPlayer) {
        
    }
    
    public func audioPlayerEndInterruption(player: AVAudioPlayer) {
        
    }
    
    public func audioPlayerEndInterruption(player: AVAudioPlayer, withFlags flags: Int) {
        
    }
    
    public func audioPlayerEndInterruption(player: AVAudioPlayer, withOptions flags: Int) {
        
    }
```

##Installation
###CocoaPods
To use XXAudioKit as a pod package just add the following in your Podfile file.

```
source 'https://github.com/CocoaPods/Specs.git'
    platform :ios, '8.0'

    target 'Your Target Name' do
        use_frameworks!
        // ...
        pod 'XXAudioKit', :git => 'git@github.com:xxopensource/XXAudioKit.git'
        // ...
    end
```

## Contribution

- If you found a **bug**, open an **issue**
- If you have a **feature request**, open an **issue**
- If you want to **contribute**, submit a **pull request**
