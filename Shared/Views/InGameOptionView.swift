//
//  InGameOptionView.swift
//  MrPutt
//
//  Created by Developer on 1/7/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import UIKit

import Cartography

class InGameOptionView: UIView {
    
    @IBOutlet weak var optionNameLabel: UILabel!
    @IBOutlet weak var toggleSwitch: UISwitch!
    
    var optionName: String {
        get { return optionNameLabel.text ?? "" }
        set { optionNameLabel.text = newValue }
    }
    
    var enabled: Bool {
        get { return toggleSwitch.isOn }
        set { toggleSwitch.isOn = newValue }
    }
    
    var onChanged: (Void)->Void = { }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        translatesAutoresizingMaskIntoConstraints = false
        
        constrain(self) {
            $0.height == 44
        }
    }

}
