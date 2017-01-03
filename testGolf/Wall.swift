//
//  Wall.swift
//  testGolf
//
//  Created by Developer on 12/26/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import SpriteKit
import UIKit

class Wall: SKSpriteNode {
    static let name = "wall"

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        physicsBody = adjustedPhysicsBody()
    }
    
    func adjustedPhysicsBody() -> SKPhysicsBody? {
        physicsBody?.isDynamic = false
        physicsBody?.restitution = 1
        physicsBody?.friction = 0
        physicsBody?.categoryBitMask = Category.wall.rawValue
        physicsBody?.collisionBitMask = Category.ball.rawValue
        physicsBody?.contactTestBitMask = Category.ball.rawValue
        return physicsBody
    }
}

class CornerWall: Wall {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        physicsBody = adjustedPhysicsBody()
    }
    
    override func adjustedPhysicsBody() -> SKPhysicsBody? {
        let center = CGPoint(x: -frame.width/2, y: -frame.width/2)
        
        let path = CGMutablePath()
        path.addArc(center: center, radius: frame.width*0.8, startAngle: 0, endAngle: .pi/2, clockwise: false)
    
        let corrected = SKPhysicsBody(polygonFrom: path)
        corrected.isDynamic = false
        corrected.restitution = 1
        corrected.friction = 0
        corrected.categoryBitMask = Category.wall.rawValue
        corrected.collisionBitMask = Category.ball.rawValue
        corrected.contactTestBitMask = Category.ball.rawValue
        return corrected
    }
}
