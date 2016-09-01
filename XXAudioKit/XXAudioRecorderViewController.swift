//
//  XXAudioRecorderViewController.swift
//

import UIKit
import AVFoundation

public protocol XXAudioRecorderViewControllerDelegate: NSObjectProtocol {
    func audioRecorderController(controller: XXAudioRecorderViewController, didFinishWithAudioAtPath filePath: String)
}

public class XXAudioRecorderViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    public weak var delegate: XXAudioRecorderViewControllerDelegate?;
    
    public var buttonTintColor: UIColor?
    public var timeTintColor: UIColor?
    public var waveColor: UIColor?
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet var waveViews: [XXAudioWaveView]!
    @IBOutlet var handleBtns: [UIButton]!
    
    enum XXAudioStatus: UInt {
        case PreRecording = 0, Recording, PauseRecording, CompleteRecording, PrePlayback, Playback, PausePlayback, CompletePlayback
    }
    var status: XXAudioStatus = .PreRecording {
        didSet {
            didChangedStatus()
        }
    }
    var audioFilePath: String?
    var audioPlayer: AVAudioPlayer?;
    var audioRecorder: AVAudioRecorder?;
    
    var meterUpdateDisplayLink: CADisplayLink?
    var timerUpdateDidplayLink: CADisplayLink?
    
    var tempAudioFilePath: String?
    
    convenience public init() {
        let podBundle = NSBundle(forClass: XXAudioRecorderViewController.self)
        let bundlePath = podBundle.pathForResource("XXAudioKit", ofType: "bundle");
        self.init(nibName: "XXAudioRecorderView", bundle: NSBundle(path: bundlePath!));
    }
    
    convenience public init(audioFilePath: String) {
        self.init();
        tempAudioFilePath = audioFilePath;
        self.audioFilePath = audioFilePath;
        status = .PrePlayback;
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
        status = .PreRecording;
    }
    
    @IBAction func middleBtnHandle(sender: UIButton) {
        
        switch status {
        case .PrePlayback, .PausePlayback:
            status = .Playback;
            
        case .Playback:
            status = .PausePlayback;
        
        case .PreRecording, .PauseRecording:
            status = .Recording;
            
        case .Recording:
            status = .PauseRecording;
        
        default:
            break;
        }
    }
    
    @IBAction func rightBtnHandle(sender: UIButton) {
        
        switch status {
        case .PauseRecording, .Recording:
            status = .CompleteRecording;
            
        case .PausePlayback, .Playback:
            status = .CompletePlayback;
            
        case .PreRecording:
            self.dismissViewControllerAnimated(true, completion: nil);
            
        default:
            if let audioFilePath = audioFilePath where tempAudioFilePath != audioFilePath {
                delegate?.audioRecorderController(self, didFinishWithAudioAtPath: audioFilePath);
            }
            
            self.dismissViewControllerAnimated(true, completion: nil);
            break;
        }
    }
    
    // MARK: - StatusChanged
    
    func delay(time: NSTimeInterval, block: () -> Void) {
        let time =  dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue(), block)
    }
    
    func didChangedStatus() {
        
        self.updateButtons();
        
        switch status {
        case .PreRecording:
            
            audioRecorder?.stop();
            audioRecorder = nil;
            
            let _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord)
            
            let audioFilePath = NSTemporaryDirectory() + "\(NSDate().timeIntervalSince1970).caf";
            let audioURL = NSURL(fileURLWithPath: audioFilePath, isDirectory: false)
            configRecorder(audioURL);
            self.audioFilePath = audioFilePath;
            
            startUpdatingTimer();
            delay(0.1) {
                self.stopUpdatingTimer();
            }
            
            startUpdatingMeter();
            
        case .Recording:
            
            if let audioRecorder = audioRecorder {
                audioRecorder.record();
                startUpdatingTimer();
//                startUpdatingMeter();
            } else {
                status = .CompleteRecording;
            }
            
        case .PauseRecording:
            
            audioRecorder?.pause();
            stopUpdatingTimer();
            
        case .CompleteRecording:
            
            audioRecorder?.stop();
            audioRecorder = nil;
            status = .PrePlayback;
            
        case .PrePlayback:
            
            audioPlayer?.stop();
            audioPlayer = nil;
            
            if let audioFilePath = audioFilePath {
                let _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient)
                
                if audioPlayer == nil {
                    let audioURL = NSURL(fileURLWithPath: audioFilePath, isDirectory: false)
                    configPlayback(audioURL);
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
    
    func configRecorder(url: NSURL) {
        let session: AVAudioSession = AVAudioSession.sharedInstance()
        session.requestRecordPermission { granted in
            if granted {
                let recordSettings: [String : AnyObject]  = [
                    AVFormatIDKey : NSNumber(unsignedInt: kAudioFormatLinearPCM),
                    AVSampleRateKey : 44100.0,
                    AVNumberOfChannelsKey : 2
                ]
                self.audioRecorder = try? AVAudioRecorder(URL: url, settings: recordSettings)
                guard let recorder = self.audioRecorder else {
                    return
                }
                recorder.delegate = self
                recorder.meteringEnabled = true
                recorder.prepareToRecord();
                
                let _ = try? session.setActive(true)
            } else {
                debugPrint("Recording permission has been denied")
            }
        }
    }
    
    func configPlayback(url: NSURL) {
        let session: AVAudioSession = AVAudioSession.sharedInstance()
        session.requestRecordPermission { granted in
            if granted {
                
                self.audioPlayer = try? AVAudioPlayer(contentsOfURL: url);
                self.audioPlayer?.delegate = self;
                self.audioPlayer?.meteringEnabled = true;
                self.audioPlayer?.prepareToPlay();
                
                let _ = try? session.setActive(true)
            } else {
                debugPrint("Recording permission has been denied")
            }
        }
    }
    
    func updateButtons() {
        let leftBtn = handleBtns[0];
        let middleBtn = handleBtns[1];
        let rightBtn = handleBtns[2];
        
        leftBtn.setTitle("删除", forState: .Normal);
        switch status {
        case .PreRecording:
            middleBtn.setTitle("录音", forState: .Normal);
            rightBtn.setTitle("关闭", forState: .Normal);
        case .Recording:
            middleBtn.setTitle("暂停", forState: .Normal);
            rightBtn.setTitle("停止", forState: .Normal);
        case .PauseRecording:
            middleBtn.setTitle("继续录音", forState: .Normal);
            rightBtn.setTitle("停止", forState: .Normal);
        case .CompleteRecording:
            middleBtn.setTitle("播放", forState: .Normal);
            rightBtn.setTitle("完成", forState: .Normal);
        case .PrePlayback:
            middleBtn.setTitle("播放", forState: .Normal);
            
            if tempAudioFilePath == audioFilePath {
                rightBtn.setTitle("关闭", forState: .Normal);
            } else {
                rightBtn.setTitle("完成", forState: .Normal);
            }
            
        case .Playback:
            middleBtn.setTitle("暂停", forState: .Normal);
            rightBtn.setTitle("停止", forState: .Normal);
        case .PausePlayback:
            middleBtn.setTitle("继续播放", forState: .Normal);
            rightBtn.setTitle("停止", forState: .Normal);
        case .CompletePlayback:
            middleBtn.setTitle("播放", forState: .Normal);
            rightBtn.setTitle("完成", forState: .Normal);
        }
        
        if [.CompletePlayback, .CompleteRecording, .PrePlayback].contains(status) &&  audioFilePath != nil {
            leftBtn.enabled = true;
        } else {
            leftBtn.enabled = false;
        }
    }
    
    // MARK: - Update Time
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
            
        case .Recording:
            if let audioRecorder = audioRecorder {
                timeCount = Int(audioRecorder.currentTime);
            }
            
        default:
            break;
        }
        
        timeLabel.text = "\(timeCount/3600 > 9 ? "" : 0)\(timeCount/3600):\(timeCount/60%60 > 9 ? "" : 0)\(timeCount/60%60):\(timeCount%60 > 9 ? "" : 0)\(timeCount%60)";
    }
    
    func startUpdatingTimer() {
        timerUpdateDidplayLink?.invalidate();
        timerUpdateDidplayLink = CADisplayLink(target: self, selector: #selector(XXAudioRecorderViewController.updateTimer));
        timerUpdateDidplayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes);
    }
    
    func stopUpdatingTimer() {
        timerUpdateDidplayLink?.invalidate();
        timerUpdateDidplayLink = nil;
    }

    // MARK: - Update Meters
    func updateMeters() {
        var normalizedValue: CGFloat = 0.0;
        
        if let audioRecorder = audioRecorder {
            audioRecorder.updateMeters();
            
            normalizedValue = pow(10.0, CGFloat(audioRecorder.averagePowerForChannel(0)) / 20.0)
        }
        
        if let audioPlayer = audioPlayer where audioPlayer.playing == true {
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
    
    // MARK: - AVAudioRecorderDelegate
    public func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        status = .CompleteRecording;
    }
    
    public func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {
        
    }
    
    public func audioRecorderBeginInterruption(recorder: AVAudioRecorder) {
        
    }
    
    public func audioRecorderEndInterruption(recorder: AVAudioRecorder) {
        
    }
    
    public func audioRecorderEndInterruption(recorder: AVAudioRecorder, withFlags flags: Int) {
        
    }
    
    public func audioRecorderEndInterruption(recorder: AVAudioRecorder, withOptions flags: Int) {
        
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
