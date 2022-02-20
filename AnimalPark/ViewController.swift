//
//  ViewController.swift
//  AnimalPark
//
//  Created by Mohammed Bajaman on 2022-02-04.
//

import UIKit
let dateLabelTest = UILabel()
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
            glesRenderer.loadBackdrop()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        refreshData.lastOpened = Int(Date().timeIntervalSinceReferenceDate)
        
        dateLabelTest.frame = CGRect(x: 15, y: 15, width: 300, height: 200)
        self.view.addSubview(dateLabelTest)
        setupGL()
    }
    
    override func glkView(_ view: GLKView, drawIn drawBackdrop: CGRect) {
        glesRenderer.draw(drawBackdrop) //??? what is CGRect T_T
    }

}

struct refreshData {
    static var elapsedTime = 0
    static var lastOpened = 0
}
