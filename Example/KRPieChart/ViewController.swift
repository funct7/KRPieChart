//
//  ViewController.swift
//  KRPieChart
//
//  Created by Joshua Park on 08/08/2016.
//  Copyright (c) 2016 Joshua Park. All rights reserved.
//

import UIKit
import KRPieChart

class ViewController: UIViewController {

    @IBOutlet weak var viewBox: KRPieChart!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    @IBAction func fillAction(_ sender: AnyObject) {
        viewBox.innerRadius = 50.0
        viewBox.setSegments([0.35, 0.25, 0.2, 0.2], colors: [UIColor.red, UIColor.green, UIColor.blue, UIColor.gray])
        viewBox.animateWithDuration(1.0, style: .sequentialCCW) {
            print("Complete!")
        }
    }
    
    @IBAction func clearAction(_ sender: AnyObject) {
        viewBox.hideChart()
    }
}
