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
    static let fileName = "Ball"
    static let name = "ball"
    
    lazy var ballTrail: SKEmitterNode = {
        return self.childNode(withName: "//ballTrail")! as! SKEmitterNode
    }()
    
    var trailBirthrate: CGFloat = 100
 
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        physicsBody = adjustedPhysicsBody()
    }
    
    func adjustedPhysicsBody() -> SKPhysicsBody? {
        physicsBody?.usesPreciseCollisionDetection = true
        physicsBody?.categoryBitMask = Category.ball.rawValue
        physicsBody?.collisionBitMask = Category.wall.rawValue
        physicsBody?.contactTestBitMask = Category.hole.rawValue | Category.wall.rawValue
        physicsBody?.fieldBitMask = Category.ball.rawValue
        return physicsBody
    }
    
    /* Should be called once ball is added to scene */
    func updateTrailEmitter() {
        ballTrail.targetNode = scene
        ballTrail.particleScale *= 1.0
        ballTrail.particleScaleSpeed *= 1.0
    }
    
    func enableTrail() {
        ballTrail.particleBirthRate = trailBirthrate
    }
    
    func disableTrail() {
        trailBirthrate = ballTrail.particleBirthRate
        ballTrail.particleBirthRate = 0
    }
}
