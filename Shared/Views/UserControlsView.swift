//
//  UserControlsView.swift
//  MrPutt
//
//  Created by Developer on 1/13/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import UIKit

import Cartography

class UserControlsView: UIImageView {

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
    
    static func create(motionDuration: TimeInterval) -> UserControlsView {
        let menu = Bundle(for: GameViewController.self).loadNibNamed("UserControlsView", owner: nil, options: nil)![0] as! UserControlsView
        menu.motionDuration = motionDuration
        return menu
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
