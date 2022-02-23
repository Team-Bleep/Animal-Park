//
//  ViewController.swift
//  AnimalPark
//
//  Created by Mohammed Bajaman on 2022-02-04.
//

import UIKit
let dateLabelTest = UILabel()
let defaults = UserDefaults.standard
import GLKit

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
        setupGL()
        
        // Check if first time opening app, initializes currency saver
        if UserDefaults.standard.object(forKey: "firstLaunch") == nil {
            UserDefaults.standard.set(0, forKey: DefaultKeys.currency)
            UserDefaults.standard.set(false, forKey: "firstLaunch")
        }
        
        // For interactivity with animals; use gesture recognizer?
        // Maybe draw a UI object on top of where the animal is rendered?
       
    }
    
    override func glkView(_ view: GLKView, drawIn drawBackdrop: CGRect) {
        glesRenderer.loadBackdrop()
        glesRenderer.draw() //??? what is CGRect T_T
        
        if (spawned0) {
            glesRenderer.loadAnimal()
            glesRenderer.drawAnml()
        }
        
        if (spawned1) {
            glesRenderer.loadAnimal2()
            glesRenderer.drawAnml()
        }
    }
}

struct refreshData {
    static var elapsedTime = 0
    static var lastOpened = 0
}

struct DefaultKeys {
    static let currency = "currency"
}
