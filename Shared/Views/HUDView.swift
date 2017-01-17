//
//  HUDView.swift
//  MrPutt
//
//  Created by Developer on 1/17/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import UIKit

import JWSwiftTools

class HUDView: UIView {
    @IBOutlet weak var strokeLabel: UILabel!
    @IBOutlet weak var parLabel: UILabel!
    
    var strokes: Int = 0 {
        didSet {
            strokeLabel.text = strokes.string!
        }
    }
    
    static func create(par: Int) -> HUDView {
        let hud = Bundle(for: HUDView.self).loadNibNamed("HUDView", owner: nil, options: nil)![0] as! HUDView
        hud.parLabel.text = par.string!
        return hud
    }
}
