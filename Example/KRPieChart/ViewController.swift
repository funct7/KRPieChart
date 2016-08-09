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

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    @IBAction func fillAction(sender: AnyObject) {
        viewBox.clockwise = false
        viewBox.innerRadius = 50.0
        viewBox.setSegments([0.35, 0.25, 0.2, 0.2], colors: [UIColor.redColor(), UIColor.greenColor(), UIColor.blueColor(), UIColor.grayColor()])
        viewBox.animateWithDuration(1.0, style: .SequentialCCW) {
            print("Complete!")
        }
    }
}
