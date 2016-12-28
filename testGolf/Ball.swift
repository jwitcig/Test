//
//  Ball.swift
//  testGolf
//
//  Created by Developer on 12/26/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import SpriteKit
import UIKit

class Ball: SKSpriteNode {
    static let name = "ball"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        physicsBody = adjustedPhysicsBody()
    }
    
    func adjustedPhysicsBody() -> SKPhysicsBody? {
        physicsBody?.categoryBitMask = Category.ball.rawValue
        physicsBody?.collisionBitMask = Category.wall.rawValue
        physicsBody?.contactTestBitMask = Category.hole.rawValue
        return physicsBody
    }
    
    /* Should be called once ball is added to scene */
    func updateTrailEmitter() {
        guard let ballTrail = childNode(withName: "//ballTrail") as? SKEmitterNode else { return }
        ballTrail.targetNode = scene
        ballTrail.particleScale *= xScale
        ballTrail.particleScaleSpeed *= xScale
    }
    
    func disableTrail() {
        guard let ballTrail = childNode(withName: "//ballTrail") as? SKEmitterNode else { return }
        ballTrail.particleBirthRate = 0
    }
}
