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
    
    lazy var bodyPiece: SKSpriteNode = {
        return self.childNode(withName: "bodyPiece")! as! SKSpriteNode
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        physicsBody = nil
        
        bodyPiece.physicsBody = adjustedPhysicsBody()
    }
    
    func adjustedPhysicsBody() -> SKPhysicsBody? {
        bodyPiece.physicsBody?.categoryBitMask = Category.hole.rawValue
        bodyPiece.physicsBody?.collisionBitMask = Category.none.rawValue
        bodyPiece.physicsBody?.contactTestBitMask = Category.ball.rawValue
        return bodyPiece.physicsBody
    }
}
