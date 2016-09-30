//
//  ViewController.swift
//  XXAudioKitExample
//
//  Created by 沈鹏 on 16/8/30.
//  Copyright © 2016年 沈鹏. All rights reserved.
//

import UIKit
import XXAudioKit

class ViewController: UIViewController {
    
    var audioPlay: UIButton?
    var audioRecorder: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func loadView() {
        super.loadView()
        
        audioPlay = UIButton(type: .Custom)
        audioPlay?.frame = CGRectMake(self.view.bounds.size.width/2-50, self.view.bounds.size.height/2-50, 100, 45)
        audioPlay?.setTitle("audioPlay", forState: .Normal)
        audioPlay?.setTitleColor(UIColor.blackColor(), forState: .Normal)
        audioPlay?.layer.cornerRadius = 5.0
        audioPlay?.layer.borderWidth = 1.0
        audioPlay?.layer.borderColor = UIColor.lightGrayColor().CGColor
        audioPlay?.addTarget(self, action:#selector(buttonClick(_:)) , forControlEvents: .TouchUpInside)
        audioPlay?.tag = 1
        self.view.addSubview(audioPlay!)
        
        audioRecorder = UIButton(type: .Custom)
        audioRecorder?.frame = CGRectMake(self.view.bounds.size.width/2-75, self.view.bounds.size.height/2+50, 150, 50)
        audioRecorder?.setTitle("audioRecorder", forState: .Normal)
        audioRecorder?.setTitleColor(UIColor.blackColor(), forState: .Normal)
        audioRecorder?.layer.cornerRadius = 5.0
        audioRecorder?.layer.borderWidth = 1.0
        audioRecorder?.layer.borderColor = UIColor.lightGrayColor().CGColor
        audioRecorder?.addTarget(self, action:#selector(buttonClick(_:)) , forControlEvents: .TouchUpInside)
        self.view.addSubview(audioRecorder!)
        
    }
    
    func buttonClick(sender: UIButton) {
        if sender.tag == 1 {
            let audioPlaybackVC = XXAudioPlaybackViewController()
            audioPlaybackVC.buttonTintColor = UIColor.orangeColor()
            audioPlaybackVC.waveColor = UIColor.orangeColor()
            audioPlaybackVC.presentInViewController(self, animated: true, completion: nil)
        }else {
            let audioRecorderVC = XXAudioRecorderViewController(audioFilePath: "")
            audioRecorderVC.buttonTintColor = UIColor.orangeColor()
            audioRecorderVC.waveColor = UIColor.orangeColor()
            audioRecorderVC.presentInViewController(self, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        
    }

}

