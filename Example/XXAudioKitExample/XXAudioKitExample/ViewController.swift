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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        
        
        let audioRecorderVC = XXAudioRecorderViewController(audioFilePath: "")
        audioRecorderVC.buttonTintColor = UIColor.orangeColor();
        audioRecorderVC.waveColor = UIColor.orangeColor();
        audioRecorderVC.presentInViewController(self, animated: true, completion: nil);
    }


}

