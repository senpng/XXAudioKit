//
//  XXAudioPlaybackViewController.swift
//

import UIKit
import AVFoundation

public class XXAudioPlaybackViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    /// The color of the button's title
    public var buttonTintColor: UIColor?
    /// The tintColor of the timeLabel
    public var timeTintColor: UIColor?
    /// The color of the waveViews
    public var waveColor: UIColor?
    
    /// The timeLabel is show play time
    @IBOutlet weak var timeLabel: UILabel!
    /// The custom view is show wave view animation
    @IBOutlet var waveViews: [XXAudioWaveView]!
    /// The Button is show play time
    @IBOutlet var handleBtns: [UIButton]!
    
    /**
     *  State of AudioPlay
     
     - PrePlayback:      Prepare
     - Playback:         Play
     - PausePlayback:    Pause
     - CompletePlayback: Complete
     */
    enum XXAudioPlaybackStatus: UInt {
        case PrePlayback, Playback, PausePlayback, CompletePlayback
    }
    
    /// Initialize the state of play button
    var status: XXAudioPlaybackStatus = .Playback {
        didSet {
            didChangedStatus()
        }
    }
    
    /// The data of audio playback
    var audioData: NSData?
    var audioPlayer: AVAudioPlayer?;
    
    var meterUpdateDisplayLink: CADisplayLink?
    var timerUpdateDidplayLink: CADisplayLink?
    
    convenience init() {
        let podBundle = NSBundle(forClass: XXAudioPlaybackViewController.self)
        let bundlePath = podBundle.pathForResource("XXAudioKit", ofType: "bundle");
        self.init(nibName: "XXAudioPlaybackView", bundle: NSBundle(path: bundlePath!));
    }
    
    convenience public init(audioData: NSData) {
        self.init();
        self.audioData = audioData
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().idleTimerDisabled = true;
        
        if let buttonTintColor = buttonTintColor {
            let _ = handleBtns.map { $0.tintColor = buttonTintColor }
        }
        
        if let timeTintColor = timeTintColor {
            timeLabel.tintColor = timeTintColor;
        }
        
        didChangedStatus();
    }
    
    
    public func presentInViewController(vc: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        self.modalPresentationStyle = .Custom;
        vc.presentViewController(self, animated: flag, completion: completion);
    }
    
    // MARK: - Handles
    @IBAction func leftBtnHandle(sender: UIButton) {
        
        switch status {
        case .PrePlayback, .PausePlayback:
            status = .Playback;
            
        case .Playback:
            status = .PausePlayback;
        
        default:
            break;
        }
    }
    
    @IBAction func rightBtnHandle(sender: UIButton) {
        
        switch status {
        case .PausePlayback, .Playback:
            status = .CompletePlayback;
        default:
            self.dismissViewControllerAnimated(true, completion: nil);
            break;
        }
    }
    
    // MARK: - StatusChanged
    
    func delay(time: NSTimeInterval, block: () -> Void) {
        let time =  dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue(), block)
    }
    
    /**
     *  Change the state of play
     */
    func didChangedStatus() {
        
        self.updateButtons();
        
        switch status {
        case .PrePlayback:
            /// stop
            audioPlayer?.stop();
            audioPlayer = nil;
            
            if let audioData = audioData {
                let _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient)
                
                if audioPlayer == nil {
                    configPlayback(audioData);
                }
            }
            
            self.startUpdatingTimer();
            delay(0.1) {
                self.stopUpdatingTimer();
            }
            
            stopUpdatingMeter();
            
        case .Playback:
            
            if let audioPlayer = audioPlayer {
                audioPlayer.play();
                startUpdatingTimer();
                startUpdatingMeter()
            } else {
                status = .CompletePlayback;
            }
            
        case .PausePlayback:
            
            audioPlayer?.pause();
            stopUpdatingTimer()
            
            stopUpdatingMeter();
            
        case .CompletePlayback:
            
            audioPlayer?.stop();
            audioPlayer = nil;
            status = .PrePlayback;
        }
    }
    
//    func configPlayback(url: NSURL) {
//        let session: AVAudioSession = AVAudioSession.sharedInstance()
//        session.requestRecordPermission { granted in
//            if granted {
//                let _ = try? session.setActive(true)
//                
//                self.audioPlayer = try? AVAudioPlayer(contentsOfURL: url);
//                self.audioPlayer?.delegate = self;
//                self.audioPlayer?.meteringEnabled = true;
//                self.audioPlayer?.prepareToPlay();
//            } else {
//                debugPrint("Recording permission has been denied")
//            }
//        }
//    }
    
    /**
     *   Set audio player's parameters and agent
     
     - parameter audioData: audioPlay's data
     */
    func configPlayback(audioData: NSData) {
        let session: AVAudioSession = AVAudioSession.sharedInstance()
        session.requestRecordPermission { granted in
            if granted {
                let _ = try? session.setActive(true)
                
                self.audioPlayer = try? AVAudioPlayer(data: audioData);
                self.audioPlayer?.delegate = self;
                self.audioPlayer?.meteringEnabled = true;
                self.audioPlayer?.prepareToPlay();
            } else {
                debugPrint("Recording permission has been denied")
            }
        }
    }
    
    /**
     *  According to the state of play set button's title
     */
    func updateButtons() {
        let leftBtn = handleBtns[0];
        let rightBtn = handleBtns[1];
        
        switch status {
        case .PrePlayback:
            leftBtn.setTitle("播放", forState: .Normal);
            rightBtn.setTitle("关闭", forState: .Normal);
        case .Playback:
            leftBtn.setTitle("暂停", forState: .Normal);
            rightBtn.setTitle("停止", forState: .Normal);
        case .PausePlayback:
            leftBtn.setTitle("继续播放", forState: .Normal);
            rightBtn.setTitle("停止", forState: .Normal);
        case .CompletePlayback:
            leftBtn.setTitle("播放", forState: .Normal);
            rightBtn.setTitle("关闭", forState: .Normal);
        }
    }
    
    // MARK: - Update Time
    
    /**
     *  Update the playing time
     */
    func updateTimer() {
        
        var timeCount = 0;
        
        switch status {
        case .CompletePlayback, .PrePlayback:
            if let audioPlay = audioPlayer {
                timeCount = Int(audioPlay.duration);
            }
            
        case .Playback:
            if let audioPlay = audioPlayer {
                timeCount = Int(audioPlay.duration - audioPlay.currentTime);
            }
            
        default:
            break;
        }
        
        timeLabel.text = "\(timeCount/3600 > 9 ? "" : 0)\(timeCount/3600):\(timeCount/60%60 > 9 ? "" : 0)\(timeCount/60%60):\(timeCount%60 > 9 ? "" : 0)\(timeCount%60)";
    }
    
    /**
     *  Open CADisplayLink timer
     */
    func startUpdatingTimer() {
        timerUpdateDidplayLink?.invalidate();
        timerUpdateDidplayLink = CADisplayLink(target: self, selector: #selector(XXAudioRecorderViewController.updateTimer));
        timerUpdateDidplayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes);
    }
    /**
     *  Stop CADisplayLink timer
     */
    func stopUpdatingTimer() {
        timerUpdateDidplayLink?.invalidate();
        timerUpdateDidplayLink = nil;
    }

    // MARK: - Update Meters
    func updateMeters() {
        var normalizedValue: CGFloat = 0.0;
        
        if let audioPlayer = audioPlayer where audioPlayer.playing == true {
            /* call to refresh meter values */
            audioPlayer.updateMeters();
            normalizedValue = pow(10.0, CGFloat(audioPlayer.averagePowerForChannel(0)) / 20.0)
        }
        
        let _ = waveViews.map { waveView in
            if let waveColor = waveColor {
                waveView.waveColor = waveColor;
            }
            waveView.updateWithLevel(normalizedValue);
        }
    }
    
    func startUpdatingMeter() {
        meterUpdateDisplayLink?.invalidate();
        meterUpdateDisplayLink = CADisplayLink(target: self, selector: #selector(XXAudioRecorderViewController.updateMeters));
        meterUpdateDisplayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes);
    }
    
    func stopUpdatingMeter() {
        meterUpdateDisplayLink?.invalidate();
        meterUpdateDisplayLink = nil;
    }
    
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
}
