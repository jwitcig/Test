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
    
    var willBeginMotion: ()->Void = {}
    var didFinishMotion: ()->Void = {}
    
    var dismissBlock: ()->() = {}
    
    var isShown: Bool {
        return visibleConstraints.active
    }
    
    var inMotion = false
    
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
    
    var motionDuration: TimeInterval!
    
    var options: [InGameOptionView] = [] {
        didSet {
            oldValue.forEach { $0.removeFromSuperview() }
            options.forEach {
                mainStackView.insertArrangedSubview($0, at: mainStackView.arrangedSubviews.count-1)
            }
        }
    }
    
    static func create(motionDuration: TimeInterval) -> InGameMenuView {
        let menu = Bundle(for: GameViewController.self).loadNibNamed("InGameMenuView", owner: nil, options: nil)![0] as! InGameMenuView
        menu.motionDuration = motionDuration
        return menu
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
        willBeginMotion()
        
        visibleConstraints.active = false
        hiddenConstraints.active = true
        
        superview!.layoutIfNeeded()
        
        hiddenConstraints.active = false
        visibleConstraints.active = true
        
        
        UIView.animate(withDuration: TimeInterval(motionDuration), delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: .curveEaseInOut, animations: superview!.layoutIfNeeded, completion: {_ in             self.didFinishMotion()
        })
    }
    
    func dismiss() {
        willBeginMotion()

        visibleConstraints.active = false
        hiddenConstraints.active = true
    
        UIView.animate(withDuration: TimeInterval(motionDuration), animations: superview!.layoutIfNeeded) { _ in
            self.didFinishMotion()
        }
        dismissBlock()
    }
    
}
