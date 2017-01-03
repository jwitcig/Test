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
//        let corrected = SKPhysicsBody(rectangleOf: frame.size)
        
        let rect = CGRect(origin: CGPoint(x: -frame.width*anchorPoint.x, y: -frame.height*anchorPoint.y), size: frame.size)
        
        var transform = CGAffineTransform.identity
        
        let path = CGPath(rect: rect, transform: &transform)
                
        let corrected = SKPhysicsBody(polygonFrom: path)
        
        corrected.isDynamic = existing?.isDynamic ?? false
        corrected.restitution = existing?.restitution ?? 0.5
        corrected.friction = existing?.friction ?? 0
        corrected.categoryBitMask = Category.wall.rawValue
        corrected.collisionBitMask = Category.ball.rawValue
        corrected.contactTestBitMask = Category.ball.rawValue
        return corrected
    }
}
