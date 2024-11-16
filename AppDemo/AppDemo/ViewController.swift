//
//  ViewController.swift
//  AppDemo
//
//  Created by wangzhizhou on 2024/10/19.
//

import UIKit
import PodDemo
import MacroDemo

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // usage macro in app main project
        let a = 5
        let b = 6
        let (result, code) = #stringify(a + b)
        print("app run macro: #stringify(a+b): \(result) \(code)")
        
        // call pod method which inner use swift macro
        TestSwiftMacroUsage.testFunc()
    }
}

