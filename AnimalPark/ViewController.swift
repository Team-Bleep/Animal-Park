//
//  ViewController.swift
//  AnimalPark
//
//  Created by Mohammed Bajaman on 2022-02-04.
//

import UIKit
import GLKit
import SwiftUI

let dateLabelTest = UILabel()
let foodLeftText = UILabel()
let foodRefillButton = UIButton()
let foodCostText = UILabel()
let defaults = UserDefaults.standard
var numOfAnimalTextures: Int = 0


extension ViewController: GLKViewControllerDelegate {
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        glesRenderer.update();
    }
}

class ViewController: GLKViewController {

    private var context: EAGLContext?
    public var glesRenderer: Renderer!
    private var rect: CGRect!
    
    private var spawned0 = false
    private var spawned1 = false
    
    private func setupGL() {
        context = EAGLContext(api: .openGLES3)
        EAGLContext.setCurrent(context)
        if let view = self.view as? GLKView, let context = context {
            view.context = context
            delegate = self as GLKViewControllerDelegate
            glesRenderer = Renderer()
            glesRenderer.setup(view)
           // Sending vertex data to Vertex Array
         //Replacing with other vertex data
        }
    }
    
    public func createAnimals() {
        if (!spawned0) {
            spawned0 = true
        } else if (!spawned1) {
                spawned1 = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        refreshData.lastOpened = Int(Date().timeIntervalSinceReferenceDate)
        
        dateLabelTest.frame = CGRect(x: 25, y: 0, width: 300, height: 100)
        dateLabelTest.textColor = UIColor.white
        self.view.addSubview(dateLabelTest)
        
        foodLeftText.frame = CGRect(x: 5, y: UIScreen.main.bounds.height-60, width: 300, height: 50)
        foodLeftText.textColor = UIColor.white
        self.view.addSubview(foodLeftText)
        
        foodCostText.frame = CGRect(x: 5, y: UIScreen.main.bounds.height-25, width: 300, height: 20)
        foodCostText.textColor = UIColor.white
        foodCostText.font = foodCostText.font.withSize(14)
        foodCostText.text = "Refill Cost: " + String(FoodHandler.FoodCost) + " Animal Coins";
        self.view.addSubview(foodCostText)
        
        foodRefillButton.backgroundColor = .gray;
        foodRefillButton.layer.borderColor = UIColor.black.cgColor;
        foodRefillButton.layer.borderWidth = 2;
        foodRefillButton.setTitle("Refill Food", for: .normal);
        foodRefillButton.frame = CGRect(x: UIScreen.main.bounds.width - 135, y: UIScreen.main.bounds.height-55, width: 130, height:50);
        foodRefillButton.addTarget(self, action: #selector(refillFoodClicked(sender:)), for: .touchUpInside);
        self.view.addSubview(foodRefillButton);
        
        setupGL()
        
        // Check if first time opening app, initializes currency saver
        if UserDefaults.standard.object(forKey: "firstLaunch") == nil {
            UserDefaults.standard.set(0, forKey: DefaultKeys.currency)
            UserDefaults.standard.set(false, forKey: "firstLaunch")
        }
        
        numOfAnimalTextures = getNumberOfAnimalTextures()
        setRandomAnimalTexture();
    }
    
    func setRandomAnimalTexture(){
        if (numOfAnimalTextures <= 0){
            print("ERROR: Animal images could not be found. Please make sure the file path is correct and that there are images in the Textures/Animals folder.");
            return;
        }
        let hi = Int.random(in: 0..<numOfAnimalTextures);
        
        glesRenderer.setRandomAnimalTexture();
    }
    
    func getNumberOfAnimalTextures() -> Int {
        var path = #file
        path.removeLast(31);
        path += "Textures/Animals";
        
        do {
            let content = try FileManager.default.contentsOfDirectory(atPath: path);
            return content.count;
        } catch {
            print("ERROR: Unable to get animal textures from this file path: " + path);
            return -1;
        }
    }
    
    @objc func refillFoodClicked(sender:UIButton!) {
        FoodHandler.fillFood();
        print("Food Added");
    }
    
    override func glkView(_ view: GLKView, drawIn drawBackdrop: CGRect) {
        rect = drawBackdrop
        glesRenderer.loadBackdrop()
        glesRenderer.draw(rect) //??? what is CGRect T_T
        if (spawned0) {
            glesRenderer.loadAnimal()
            glesRenderer.drawAnml(drawBackdrop)
        }
        
        if(spawned1) {
            glesRenderer.loadAnimal2()
            glesRenderer.drawAnml(drawBackdrop)
        }
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
}
