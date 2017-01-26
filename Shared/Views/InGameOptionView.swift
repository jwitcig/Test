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
    
    static func create() -> InGameOptionView {
        let option = Bundle(for: InGameOptionView.self).loadNibNamed("InGameOptionView", owner: nil, options: nil)![0] as! InGameOptionView
        
        option.toggleSwitch.addTarget(option, action: #selector(InGameOptionView.settingChanged(toggle:)), for: .valueChanged)
        return option
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        translatesAutoresizingMaskIntoConstraints = false
        
        constrain(self) {
            $0.height == 44
        }
    }
    
    func settingChanged(toggle: UISwitch) {
        AudioPlayer.main.play("toggle")

        let settings = UserDefaults.standard
        settings.setValue(toggle.isOn, forKey: optionName)
        settings.synchronize()
    }
    
    func updateUI() {
        enabled = UserDefaults.standard.value(forKey: optionName) as? Bool ?? true
    }

}
