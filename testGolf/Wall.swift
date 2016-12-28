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
        let existing = physicsBody
        let corrected = SKPhysicsBody(rectangleOf: frame.size)
        corrected.isDynamic = existing?.isDynamic ?? false
        corrected.restitution = existing?.restitution ?? 0.5
        corrected.friction = existing?.friction ?? 0
        corrected.categoryBitMask = Category.wall.rawValue
        corrected.collisionBitMask = Category.ball.rawValue
        corrected.contactTestBitMask = Category.none.rawValue
        return corrected
    }
}
