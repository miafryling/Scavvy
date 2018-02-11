//
//  ViewController.swift
//  Scavvy
//
//  Created by Mia Fryling on 2/10/18.
//  Copyright © 2018 Mia Fryling. All rights reserved.
//
import Foundation
import UIKit
import CoreML
import Vision
import AVFoundation
var highScore = 0

class GameViewController: UIViewController, FrameExtractorDelegate {

    let objectsModel = MobileNet().model
    let objectsList: [String] = ["Pen", "Mug", "Screen"]
    
    let sentimentModel = CNNEmotions().model
    let sentimentList: [String] = ["Sad", "Happy", "Angry", "Neutral", "Surprised", "Fear", "Disgust"]
    
    let foodModel = food().model
    let foodList: [String] = ["Apple Pie", "Baby Back Ribs", "Baklava", "Beef Carpaccio", "Beef Tartare", "Beet Salad", "Beignets", "Bibimbap", "Bread Pudding", "Breakfast Burrito", "Bruschetta", "Caesar Salad", "Cannoli", "Caprese Salad", "Carrot Cake", "Ceviche", "Cheesecake", "Cheese Plate", "Chicken Curry", "Chicken Quesadilla", "Chicken Wings", "Chocolate Cake", "Chocolate Mousse", "Churros", "Clam Chowder", "Club Sandwich", "Crab Cakes", "Creme Brulee", "Croque Madame", "Cup Cakes", "Deviled Eggs", "Donuts", "Dumplings", "Edamame", "Eggs Benedict", "Escargots", "Falafel", "Filet Mignon", "Fish And Chips", "Foie Gras", "French Fries", "French Onion Soup", "French Toast", "Fried Calamari", "Fried Rice", "Frozen Yogurt", "Garlic Bread", "Gnocchi", "Greek Salad", "Grilled Cheese Sandwich", "Grilled Salmon", "Guacamole", "Gyoza", "Hamburger", "Hot And Sour Soup", "Hot Dog", "Huevos Rancheros", "Hummus", "Ice Cream", "Lasagna", "Lobster Bisque", "Lobster Roll Sandwich", "Macaroni And Cheese", "Macarons", "Miso Soup", "Mussels", "Nachos", "Omelette", "Onion Rings", "Oysters", "Pad Thai", "Paella", "Pancakes", "Panna Cotta", "Peking Duck", "Pho", "Pizza", "Pork Chop", "Poutine", "Prime Rib", "Pulled Pork Sandwich", "Ramen", "Ravioli", "Red Velvet Cake", "Risotto", "Samosa", "Sashimi", "Scallops", "Seaweed Salad", "Shrimp And Grits", "Spaghetti Bolognese", "Spaghetti Carbonara", "Spring Rolls", "Steak", "Strawberry Shortcake", "Sushi", "Tacos", "Takoyaki", "Tiramisu", "Tuna Tartare", "Waffles"]
    

    
    var frameExtractor: FrameExtractor!
    
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var iSee: UILabel!
    @IBOutlet weak var countdown: UILabel!
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var guessingLabel: UILabel!
    
    @IBOutlet weak var mainScreenButton: UIButton!
    @IBOutlet weak var restartButton: UIButton!
    
    var settingImage = false
    
    var guessing = ""
    var score = 0
    var counter = 3
    var timeRemaining = 29
    var gameOver = false
    
    var timer1 = Timer()
    var timer2 = Timer()

    var gameMode = "incorrect"
    var gameModel:MLModel = food().model
    var list:[String] = []
    
    var currentImage: CIImage? {
        didSet {
            if let image = currentImage{
                self.detectScene(image: image)
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
        mainScreenButton.layer.cornerRadius = 5
        mainScreenButton.clipsToBounds = true
        restartButton.layer.cornerRadius = 5
        restartButton.clipsToBounds = true
        
        let userDefaults = UserDefaults.standard
        gameMode = "\(userDefaults.value(forKey: "mode")!)"
        
        setModel()
        
        chooseRandom()
        startInitialCounter()
    }
    
    func setModel() {
        if (gameMode == "Food") {
            gameModel = foodModel
            list = foodList
        } else if (gameMode == "Faces"){
            gameModel = sentimentModel
            list = sentimentList
        } else if (gameMode == "Objects"){
            gameModel = objectsModel
            list = objectsList
        } else if (gameMode == "incorrect"){
            print("something went wrong")
        }
    }
    
    func startInitialCounter() {
        timer1 = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateInitialCounter), userInfo: nil, repeats: true)
    }


    @objc func updateInitialCounter() {
        if counter > 0 {
            countdown.text = "\(counter)"
            counter -= 1
        } else if (counter == 0) {
            timer1.invalidate()
            countdown.isHidden = true
            startTimer()
        }
    }
    
    func chooseRandom()  {
        let length = list.count
        guessing = list[Int(arc4random_uniform(UInt32(length)))]
        guessingLabel.text = guessing
    }
    
    func startTimer() {
        timer2 = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        if timeRemaining > 0 {
            timeLabel.text = "\(timeRemaining)"
            timeRemaining -= 1
        } else if (timeRemaining == 0) {
            timer2.invalidate()
            guessing = ""
            guessingLabel.text = guessing
            timeLabel.text = "\(timeRemaining)"
            iSee.text = "GAME OVER"
            gameOver = true
            restartButton.isHidden = false
            mainScreenButton.isHidden = false
            newScore()
        }
    }
    
    
    func captured(image: UIImage) {
        self.previewImage.image = image
        if let cgImage = image.cgImage, !settingImage {
            settingImage = true
            DispatchQueue.global(qos: .userInteractive).async {[unowned self] in
                self.currentImage = CIImage(cgImage: cgImage)
            }
        }
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func detectScene(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: gameModel) else {
            fatalError()
        }

        let request = VNCoreMLRequest(model: model) { [unowned self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                let _ = results.first else {
                    self.settingImage = false
                    return
            }
            if !(self.gameOver) {
                DispatchQueue.main.async { [unowned self] in
                    if let first = results.first {
                        if Int(first.confidence * 100) > 1 {
                            self.iSee.text = "I see \(first.identifier)"
                            self.settingImage = false
                            if (first.identifier.uppercased().range(of: self.guessing.uppercased()) != nil) {
                                self.score += 1
                                self.scoreLabel.text = "\(self.score)"
                                self.chooseRandom()
                                self.timeRemaining = 30
                                self.timer2.invalidate()
                                self.startTimer()
                            }
                        }
                    }
                }
            }
        }
        let handler = VNImageRequestHandler(ciImage: image)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }
    }
    
    func newScore() {
        let userDefaults = UserDefaults.standard
        if userDefaults.value(forKey: "highscore") != nil {
            if (score > highScore) {
                let userDefaults = UserDefaults.standard
                userDefaults.setValue(score, forKey: "highscore")
                userDefaults.synchronize()
            }
        }
    }
    
    
    @IBAction func restartGame(_ sender: Any) {
        mainScreenButton.isHidden = true
        restartButton.isHidden = true
        timeLabel.text = "30"
        countdown.text = "3"
        score = 0
        scoreLabel.text = "\(score)"
        settingImage = false
        guessing = ""
        counter = 3
        timeRemaining = 29
        gameOver = false
        chooseRandom()
        countdown.isHidden = false
        timer1.invalidate()
        timer2.invalidate()
        startInitialCounter()
    }
    
}


