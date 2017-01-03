//
//  Hole.swift
//  testGolf
//
//  Created by Developer on 12/26/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import SpriteKit
import UIKit

class Hole: SKSpriteNode {
    static let name = "hole"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        physicsBody = adjustedPhysicsBody()
        
        let innerIndicator = childNode(withName: "indicator_inner_ring")
        let outterIndicator = childNode(withName: "indicator_outter_ring")
        
        let fadeOut = SKAction.fadeOut(withDuration: 1)
        let fadeIn = SKAction.fadeIn(withDuration: 1)
        fadeIn.duration = 2
        
        let clockwise = SKAction.rotate(byAngle: .pi, duration: 6)
        
        let fadeSequence = SKAction.sequence([fadeOut, fadeIn])
        
        let innerGroup = SKAction.group([fadeSequence, clockwise])
        let outterGroup = SKAction.group([fadeSequence, clockwise.reversed()])
        
        innerIndicator?.run(SKAction.repeatForever(innerGroup))
        outterIndicator?.run(SKAction.repeatForever(outterGroup))
    }
    
    func adjustedPhysicsBody() -> SKPhysicsBody? {
        physicsBody?.categoryBitMask = Category.hole.rawValue
        physicsBody?.collisionBitMask = Category.none.rawValue
        physicsBody?.contactTestBitMask = Category.ball.rawValue
        return physicsBody
    }
}
