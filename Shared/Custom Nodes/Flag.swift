//
//  Flag.swift
//  MrPutt
//
//  Created by Developer on 1/14/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import SpriteKit

class Flag: SKSpriteNode {
    static let name = "flag"
    
    static let bobActionName = "bob"
    
    var isWiggling = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func raise() {
        if let raise = SKAction(named: "RaiseFlag") {
            isWiggling = false
            
            removeAction(forKey: Flag.bobActionName)
            
            let stabilize = SKAction.rotate(toAngle: 0, duration: 0.2)
            stabilize.timingMode = .easeInEaseOut
            
            let sequence = SKAction.sequence([stabilize, raise])
            run(sequence)
        }
    }
    
    func lower() {
        if let raise = SKAction(named: "RaiseFlag") {
            let lower = SKAction.move(to: .zero, duration: raise.duration)
            let wiggle = SKAction.run(self.wiggle)
            let sequence = SKAction.sequence([lower, wiggle])
            run(sequence)
            isWiggling = true
        }
    }
    
    func wiggle() {
        if let bob = SKAction(named: "FlagBobbing") {
            run(SKAction.repeatForever(bob), withKey: Flag.bobActionName)
            isWiggling = true
        }
    }
}
