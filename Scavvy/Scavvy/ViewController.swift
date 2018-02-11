//
//  ViewController.swift
//  Scavvy
//
//  Created by Mia Fryling on 2/10/18.
//  Copyright © 2018 Mia Fryling. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var highScore: UITextField!
    @IBOutlet weak var modeButton: UIButton!
    
    var GameViewController:GameViewController? = nil
    
    var food = true
    var faces = false
    var objects = false
    
    @IBAction func mode(_ sender: Any) {
        let userDefaults = UserDefaults.standard
        if food {
            modeButton.setTitle("Faces", for: .normal)
            food = false
            faces = true
            objects = false
            userDefaults.setValue("Faces", forKey: "mode")
            userDefaults.synchronize()

        } else if faces {
            modeButton.setTitle("Objects", for: .normal)
            food = false
            faces = false
            objects = true
            userDefaults.setValue("Objects", forKey: "mode")
            userDefaults.synchronize()

        } else if objects {
            modeButton.setTitle("Food", for: .normal)
            food = true
            faces = false
            objects = false
            userDefaults.setValue("Food", forKey: "mode")
            userDefaults.synchronize()

        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modeButton.layer.cornerRadius = 5
        modeButton.clipsToBounds = true
        
        let userDefaults = UserDefaults.standard
        let hs = userDefaults.value(forKey: "highscore")
        if (hs != nil) {
            highScore.text = "\(hs!)"
        } else {
            highScore.text = "0"
        }
        
        userDefaults.setValue("Faces", forKey: "mode")
        userDefaults.synchronize()
    }
    
    

}



