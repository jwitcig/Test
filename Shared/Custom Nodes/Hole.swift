//
//  Hole.swift
//  testGolf
//
//  Created by Developer on 12/26/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import GameplayKit
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
        
        (childNode(withName: "gravity") as? SKFieldNode)?.region = SKRegion(radius: Float(size.width)/2.0)
    }
    
    func adjustedPhysicsBody() -> SKPhysicsBody? {
        bodyPiece.physicsBody?.categoryBitMask = Category.hole.rawValue
        bodyPiece.physicsBody?.collisionBitMask = Category.none.rawValue
        bodyPiece.physicsBody?.contactTestBitMask = Category.ball.rawValue
        return bodyPiece.physicsBody
    }
}

class HoleEntity: GKEntity {
    static let name = "hole"
    
    var visual: RenderComponent {
        return component(ofType: RenderComponent.self)!
    }
    
    var physics: PhysicsComponent {
        return component(ofType: PhysicsComponent.self)!
    }
    
    lazy var bodyPiece: SKSpriteNode = {
        return self.visual.node.childNode(withName: "bodyPiece")! as! SKSpriteNode
    }()
    
    init(node: Hole) {
        super.init()
        
        node.physicsBody = nil
        
        let visual = RenderComponent(node: node)
        addComponent(visual)

        let body = bodyPiece.physicsBody!
        bodyPiece.physicsBody = adjust(body: body)

        let physics = PhysicsComponent(body: body)
        addComponent(physics)
        
        let gravity = node.childNode(withName: "gravity") as? SKFieldNode
        gravity?.region = SKRegion(radius: Float(node.size.width)/2.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func adjust(body: SKPhysicsBody) -> SKPhysicsBody {
        body.categoryBitMask = Category.hole.rawValue
        body.collisionBitMask = Category.none.rawValue
        body.contactTestBitMask = Category.ball.rawValue
        return body
    }
}
