//
//  Hill.swift
//  MrPutt
//
//  Created by Developer on 1/3/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import SpriteKit
import UIKit

class Hill: SKFieldNode {
    static let name = "hill"
    
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
