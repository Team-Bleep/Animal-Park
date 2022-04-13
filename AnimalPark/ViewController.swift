//
//  ViewController.swift
//  AnimalPark
//
//  Created by Mohammed Bajaman on 2022-02-04.
//

import UIKit
import GLKit
import SwiftUI
import AudioToolbox

let playerScoreLabel = UILabel()
let dateLabelTest = UILabel()
let foodLeftText = UILabel()
let foodRefillButton = UIButton()
let foodCostText = UILabel()
let defaults = UserDefaults.standard

extension ViewController: GLKViewControllerDelegate {
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        glesRenderer.update();
    }
}

class ViewController: GLKViewController {

    private var context: EAGLContext?
    public var glesRenderer: Renderer!
    private var rect: CGRect!

    @IBOutlet weak var tutorialButt: UIButton!
    @IBOutlet weak var tutorialImage: UIImageView!
    
    private func setupGL() {
        context = EAGLContext(api: .openGLES3)
        EAGLContext.setCurrent(context)
        if let view = self.view as? GLKView, let context = context {
            view.context = context
            delegate = self as GLKViewControllerDelegate
            glesRenderer = Renderer()
            glesRenderer.setup(view)
            glesRenderer.loadBackdrop()
            
           // Sending vertex data to Vertex Array
         //Replacing with other vertex data
        }
    }
    
    public func createAnimals(numAnim: Int) {
        glesRenderer.loadAnimal(Int32(numAnim))
        ScoreHandler.setScore(numAnim: numAnim)
    }
    
    public func despawnAnimals(){
        glesRenderer.despawnAnimals();
        print("hello there");
    }
    
    override func viewDidLoad() {
        
        // add the new font from the font folder that was loaded into info.plist
        guard let animalPawsFont = UIFont(name: "AnimalPaws", size: UIFont.labelFontSize) else {
            fatalError("""
                Failed to load the "AnimalPaws" font.
                Make sure the font file is included in the project and the font name
                is spelled correctly.
            """)
        }
        
        super.viewDidLoad()
        setupGL()
        // Do any additional setup after loading the view.
        refreshData.lastOpened = Int(Date().timeIntervalSinceReferenceDate)
        
        // Tutorial Setup
        tutorialButt.setImage(UIImage(systemName: "info.circle.fill"), for: .normal)
        tutorialImage.isHidden = true;
        
        
        // Animal Coins Label
        dateLabelTest.frame = CGRect(x: 25, y: 0, width: 300, height: 100)
        dateLabelTest.textColor = UIColor.black
        dateLabelTest.font = UIFontMetrics.default.scaledFont(for: animalPawsFont).withSize(30)
        self.view.addSubview(dateLabelTest)
        
        // Score Label
        playerScoreLabel.frame = CGRect(x: 25, y: 50, width: 300, height: 100)
        playerScoreLabel.textColor = UIColor.black
        playerScoreLabel.font = UIFontMetrics.default.scaledFont(for: animalPawsFont).withSize(20)
        self.view.addSubview(playerScoreLabel)
        
        foodLeftText.frame = CGRect(x: 5, y: UIScreen.main.bounds.height-80, width: 300, height: 50)
        foodLeftText.textColor = UIColor.black
        foodLeftText.font = UIFontMetrics.default.scaledFont(for: animalPawsFont).withSize(20)
        self.view.addSubview(foodLeftText)
        
        foodCostText.frame = CGRect(x: 5, y: UIScreen.main.bounds.height-45, width: 300, height: 20)
        foodCostText.textColor = UIColor.black
        foodCostText.font = UIFontMetrics.default.scaledFont(for: animalPawsFont).withSize(16)
        foodCostText.text = "Refill Cost: " + String(FoodHandler.FoodCost) + " Animal Coins";
        self.view.addSubview(foodCostText)
        
        foodRefillButton.backgroundColor = .gray;
        foodRefillButton.layer.borderColor = UIColor.black.cgColor;
        foodRefillButton.layer.borderWidth = 2;
        foodRefillButton.setTitle("Refill Food", for: .normal);
        foodRefillButton.titleLabel?.font = animalPawsFont.withSize(24);
        foodRefillButton.frame = CGRect(x: UIScreen.main.bounds.width - 135, y: UIScreen.main.bounds.height-70, width: 130, height:50);
        foodRefillButton.addTarget(self, action: #selector(refillFoodClicked(sender:)), for: .touchUpInside);
        self.view.addSubview(foodRefillButton);
        
        // Check if first time opening app, initializes currency saver
        if UserDefaults.standard.object(forKey: "firstLaunch") == nil {
            UserDefaults.standard.set(0, forKey: DefaultKeys.currency)
            UserDefaults.standard.set(false, forKey: "firstLaunch")
            UserDefaults.standard.set(0, forKey: DefaultKeys.score)
        }

        MusicPlayer.Instance.startBgMusic()
        
        /// to print all possible font names and find fontname specified for font
        //for family in UIFont.familyNames.sorted() {
        //    let names = UIFont.fontNames(forFamilyName: family)
        //    print("Family: \(family) Font names: \(names)")
        //}
    }
    
    @IBAction func toggleTutorial() {
        tutorialImage.isHidden = !tutorialImage.isHidden
    }
    
    @objc func refillFoodClicked(sender:UIButton!) {
        FoodHandler.fillFood();
        print("Food Added");
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glesRenderer.draw(rect);
    }

}

struct refreshData {
    static var elapsedTime = 0
    static var lastOpened = 0
    static var currentFood = 0
}

struct DefaultKeys {
    static let currency = "currency"
    static let food = "food"
    static let score = "score"
}
