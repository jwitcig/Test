//
//  WaitingForOpponentView.swift
//  MrPutt
//
//  Created by Developer on 1/15/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import UIKit

import Cartography

class WaitingForOpponentView: UIView {
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .clear

        let logo = WaitingForOpponentLogoView()
        logo.backgroundColor = .clear

        addSubview(logo)
        constrain(logo, self) {
            $0.width == $1.width * 0.8
            $0.width == $0.height * 1461/827.0
            $0.center == $1.center
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        LogoStyleKit.drawWaitingForOpponent(frame: rect, resizing: .stretch)
    }
}

class WaitingForOpponentLogoView: UIView {
    override func draw(_ rect: CGRect) {
        
        LogoStyleKit.drawCanvas2(frame: rect, resizing: .stretch)
    }
}
