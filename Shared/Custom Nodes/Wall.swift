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
    static let nodeName = "wall"

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.name = Wall.nodeName
        
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
