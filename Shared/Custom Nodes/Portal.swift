//
//  Hill.swift
//  MrPutt
//
//  Created by Developer on 1/3/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import SpriteKit
import UIKit

class Portal: SKSpriteNode {
    static let name = "portal"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        physicsBody = adjustedPhysicsBody()
    }
    
    func adjustedPhysicsBody() -> SKPhysicsBody? {
        physicsBody?.categoryBitMask = Category.portal.rawValue
        physicsBody?.collisionBitMask = Category.none.rawValue
        physicsBody?.contactTestBitMask = Category.ball.rawValue
        return physicsBody
    }
}
