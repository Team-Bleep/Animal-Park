//
//  ViewController.swift
//  AnimalPark
//
//  Created by Mohammed Bajaman on 2022-02-04.
//

import UIKit
let dateLabelTest = UILabel()

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        refreshData.lastOpened = Int(Date().timeIntervalSinceReferenceDate)
        
        dateLabelTest.frame = CGRect(x: 15, y: 15, width: 300, height: 200)
        self.view.addSubview(dateLabelTest)
    }

    
}

struct refreshData {
    static var elapsedTime = 0
    static var lastOpened = 0
}
