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
    private var glesRenderer: Renderer!
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        refreshData.lastOpened = Int(Date().timeIntervalSinceReferenceDate)
        
        dateLabelTest.frame = CGRect(x: 15, y: 15, width: 300, height: 200)
        self.view.addSubview(dateLabelTest)
        setupGL()
        
        // Check if first time opening app, initializes currency saver
        if UserDefaults.standard.object(forKey: "firstLaunch") == nil {
            UserDefaults.standard.set(0, forKey: DefaultKeys.currency)
            UserDefaults.standard.set(false, forKey: "firstLaunch")
        }
       
    }
    
    override func glkView(_ view: GLKView, drawIn drawBackdrop: CGRect) {
        glesRenderer.loadBackdrop()
        glesRenderer.draw(drawBackdrop) //??? what is CGRect T_T
        glesRenderer.loadAnimal()
        glesRenderer.drawAnml(drawBackdrop)
        glesRenderer.loadAnimal2()
        glesRenderer.drawAnml(drawBackdrop)
    }

}

struct refreshData {
    static var elapsedTime = 0
    static var lastOpened = 0
}

struct DefaultKeys {
    static let currency = "currency"
}
