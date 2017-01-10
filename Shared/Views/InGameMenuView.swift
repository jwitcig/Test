//
//  InGameMenuView.swift
//  MrPutt
//
//  Created by Developer on 1/7/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import UIKit

import Cartography

class InGameMenuView: UIView {

    @IBOutlet weak var mainStackView: UIStackView!
    
    var dismissBlock: ()->() = {}
    
    var isShown: Bool {
        return visibleConstraints.active
    }
    
    lazy var hiddenConstraints: ConstraintGroup = {
        return constrain(self, self.superview!) {
            $0.bottom == $1.top - 40
        }
    }()
    lazy var visibleConstraints: ConstraintGroup = {
        return constrain(self, self.superview!) {
            $0.center == $1.center
        }
    }()
    
    var animationDuration: CGFloat = 0.5
    
    var options: [InGameOptionView] = [] {
        didSet {
            oldValue.forEach { $0.removeFromSuperview() }
            options.forEach {
                mainStackView.insertArrangedSubview($0, at: mainStackView.arrangedSubviews.count-1)
            }
        }
    }
    
    static func create() -> InGameMenuView {
        return Bundle(for: GameViewController.self).loadNibNamed("InGameMenuView", owner: nil, options: nil)![0] as! InGameMenuView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    @IBAction func savePressed(sender: Any) {
        options.forEach {
            UserDefaults.standard.setValue($0.enabled, forKey: $0.optionName)
        }
        UserDefaults.standard.synchronize()
        dismiss()
    }
    
    @IBAction func cancelPressed(sender: Any) {
        dismiss()
    }
    
    func show() {
        visibleConstraints.active = false
        hiddenConstraints.active = true
        
        superview!.layoutIfNeeded()
        
        hiddenConstraints.active = false
        visibleConstraints.active = true
        
        UIView.animate(withDuration: TimeInterval(animationDuration), animations: superview!.layoutIfNeeded)
    }
    
    func dismiss() {
        visibleConstraints.active = false
        hiddenConstraints.active = true

        UIView.animate(withDuration: TimeInterval(animationDuration), animations: superview!.layoutIfNeeded) { _ in
            self.removeFromSuperview()
        }
        dismissBlock()
    }
    
}
