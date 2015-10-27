//
//  SettingsViewController.swift
//  Breakout
//
//  Created by 孔去愚 on 15/10/26.
//  Copyright © 2015年 孔去愚. All rights reserved.
//

import UIKit

struct settings {
    static let Speed = "SPEED"
    static let NumberOfRows = "NumberOfRows"
    static let NumberOfSpecialBricks = "NumberOfSpecialBricks"
    static let maximumRowNumber:Double = 10
}

class SettingsViewController: UIViewController {

    let defaults = NSUserDefaults.standardUserDefaults()
    var speed: Float {
        set {
            defaults.setObject(newValue, forKey: settings.Speed)
        }
        get {
            return defaults.objectForKey(settings.Speed) as? Float ?? 0.3
        }
    }
    var rowNumber: Double {
        set {
            defaults.setObject(newValue, forKey: settings.NumberOfRows)
            numberOfRows?.text = "\(Int(newValue))"
        }
        get {
            return defaults.objectForKey(settings.NumberOfRows) as? Double ?? 1
        }
    }
    
    var specialBrickNumber: Double {
        set {
            defaults.setObject(newValue, forKey: settings.NumberOfSpecialBricks)
            numberOfSpecialBricks?.text = "\(Int(newValue))"
        }
        get {
            return defaults.objectForKey(settings.NumberOfSpecialBricks) as? Double ?? 0
        }
    }

    @IBOutlet weak var speedValue: UISlider! {
        didSet {
            speedValue.maximumValue = 0.6
            speedValue.minimumValue = 0.1
            speedValue.value = Float(speed)
        }
    }
    
    @IBOutlet weak var numberOfRows: UITextField! {
        didSet {
            numberOfRows.text = "\(defaults.objectForKey(settings.NumberOfRows) as? Int ?? 1)"
        }
    }
    @IBOutlet weak var numberOfSpecialBricks: UITextField! {
        didSet {
            numberOfSpecialBricks.text = "\(defaults.objectForKey(settings.NumberOfSpecialBricks) as? Int ?? 0)"
        }
    }
    @IBOutlet weak var changeNumberOfSpecialBricks: UIStepper! {
        didSet {
            changeNumberOfSpecialBricks.maximumValue = rowNumber * 5.0
            changeNumberOfSpecialBricks.minimumValue = 0
            changeNumberOfSpecialBricks.continuous = false
            if specialBrickNumber > changeNumberOfSpecialBricks.maximumValue {
                specialBrickNumber = changeNumberOfSpecialBricks.maximumValue
            }
            changeNumberOfSpecialBricks.value = specialBrickNumber
        }
    }
    @IBOutlet weak var changeNumberOfRows: UIStepper! {
        didSet {
            changeNumberOfRows.maximumValue = settings.maximumRowNumber
            changeNumberOfRows.minimumValue = 1
            changeNumberOfRows.continuous = false
            changeNumberOfRows.value = rowNumber
//            changeNumberOfRows?.addTarget(SettingsViewController.self, action: "change:", forControlEvents: .ValueChanged)
        }
    }

    @IBAction func changeSpeed(sender: UISlider) {
        speed = sender.value
    }
    
    @IBAction func changeRows(sender: UIStepper) {
        rowNumber = sender.value
        changeNumberOfSpecialBricks.maximumValue = sender.value * 5
        if specialBrickNumber > changeNumberOfSpecialBricks.maximumValue {
            specialBrickNumber = changeNumberOfSpecialBricks.maximumValue
        }
    }
   
    @IBAction func changeSpecialBricks(sender: UIStepper) {
        specialBrickNumber = sender.value
    }
//    func change(sender: UIStepper) {
//        print("asd")
//    }
}
