//
//  Ball.swift
//  testGolf
//
//  Created by Developer on 12/26/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import SpriteKit
import UIKit

class TextureRenderer: SKNode {
    
    static let componentSize = CGSize(width: 20, height: 20)
    
    var node: SKNode!
    
    lazy var components: [TextureComponent] = {
        var components: [TextureComponent] = []
        for location in 0..<9 {
            let component = TextureComponent(location: location, in: self)
            
            let point = TextureRenderer.position(forLocation: location)
            
            
            component.position = CGPoint(x: point.x*1/self.node.xScale, y: point.y*1/self.node.yScale)
            
            component.position = CGPoint(x: component.position.x-self.position.x, y: component.position.y-self.position.y)

            components.append(component)
        }
        return components
    }()
    
    var center: CGPoint {
        return convert(components.filter{ $0.location == 4 }.first!.position, to: node)
    }
    
    var expired: [TextureComponent] {
        let center = convert(self.center, to: node)
        
        var expiredLocations: [Int] = []
        if center.x > TextureRenderer.componentSize.width / 2 {
            expiredLocations.append(contentsOf: [2, 5, 8])
        } else if center.x < -TextureRenderer.componentSize.width / 2 {
            expiredLocations.append(contentsOf: [0, 3, 6])
        }
        
        if center.y > TextureRenderer.componentSize.height / 2 {
            expiredLocations.append(contentsOf: [0, 1, 2])
        } else if center.y < -TextureRenderer.componentSize.height / 2 {
            expiredLocations.append(contentsOf: [6, 7, 8])
        }
        
        return components.filter{ expiredLocations.contains($0.location) }
    }
    
    func replace() {
        
        guard (components.filter{ $0.location == 4 }).count == 1 else {
            return
        }
        
        let expired = self.expired.filter { $0.isExpired.0 || $0.isExpired.1 }
    
        for component in expired {
            
 
            
            let newGuy = TextureComponent(location: newLocation, in: self)
            let point = TextureRenderer.position(forLocation: newLocation)

            newGuy.position = CGPoint(x: point.x*1/self.node.xScale, y: point.y*1/self.node.yScale)
            
            newGuy.position = CGPoint(x: component.position.x-self.position.x, y: component.position.y-self.position.y)

            
            
            let lower = newGuy.location < component.location ? newGuy.location
            : component.location
            let higher = newGuy.location > component.location ? newGuy.location
                : component.location

            
            let toBump = components.filter { $0.location > lower && $0.location < higher }
            for bump in toBump {
                bump.location += newGuy.location < component.location ? 1 : -1
            }
            
            components.append(newGuy)
            addChild(newGuy)
        }
        
        for component in expired {
            components.remove(at: components.index(of: component)!)
            
            component.removeFromParent()
        }
    }
    
    static func position(forLocation location: Int) -> CGPoint {
        if location == 0 {
            return CGPoint(x: -componentSize.width, y: componentSize.height)
        } else if location == 1 {
            return CGPoint(x: -0, y: componentSize.height)
        } else if location == 2 {
            return CGPoint(x: componentSize.width, y: componentSize.height)
        } else if location == 3 {
            return CGPoint(x: -componentSize.width, y: 0)
        } else if location == 4 {
            return CGPoint(x: 0, y: 0)
        } else if location == 5 {
            return CGPoint(x: componentSize.width, y: 0)
        } else if location == 6 {
            return CGPoint(x: -componentSize.width, y: -componentSize.height)
        } else if location == 7 {
            return CGPoint(x: 0, y: -componentSize.height)
        } else if location == 8 {
            return CGPoint(x: componentSize.width, y: -componentSize.height)
        }
        return .zero
    }
    
}

class TextureComponent: SKSpriteNode {
    var location: Int
    
    let renderer: TextureRenderer
    
    init(location: Int, in renderer: TextureRenderer) {
        self.location = location
        self.renderer = renderer

        let texture = SKTexture(imageNamed: "golfTexture.jpg")
        super.init(texture: texture, color: .clear, size: CGSize(width: 20, height: 20))
        
        setScale(1/renderer.node.xScale)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isExpired: (Bool, Bool) {
        var expiredX = false
        var expiredY = false
        
        let size = CGSize(width: self.size.width*1/self.xScale,
                         height: self.size.height*1/self.yScale)
        
        let position = parent!.convert(self.position, to: renderer.node)
        
        if [0, 1, 2].contains(location) {
            if position.y > size.height * (1.5) {
                expiredY = true
            }
        } else if [6, 7, 8].contains(location) {
            if position.y < -size.height * (1.5) {
                expiredY = true
            }
        }
        
        if [2, 5, 8].contains(location) {
            if position.x < size.width * (1.5) {
                expiredX = true
            }
        } else if [0, 3, 6].contains(location) {
            if position.x > size.width * (1.5) {
                expiredX = true
            }
        }
        return (expiredX, expiredY)
    }
}

class Ball: SKSpriteNode {
    static let fileName = "Ball"
    static let name = "ball"
    
    lazy var ballTrail: SKEmitterNode = {
        return self.childNode(withName: "//ballTrail")! as! SKEmitterNode
    }()
    
    var trailBirthrate: CGFloat = 100
    
    let textureRenderer = TextureRenderer()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        physicsBody = adjustedPhysicsBody()
        
        addChild(textureRenderer)
        textureRenderer.node = self
        textureRenderer.components.forEach(textureRenderer.addChild)
        
    }
    
    func adjustedPhysicsBody() -> SKPhysicsBody? {
        physicsBody?.usesPreciseCollisionDetection = true
        physicsBody?.categoryBitMask = Category.ball.rawValue
        physicsBody?.collisionBitMask = Category.wall.rawValue
        physicsBody?.contactTestBitMask = Category.hole.rawValue | Category.wall.rawValue
        return physicsBody
    }
    
    /* Should be called once ball is added to scene */
    func updateTrailEmitter() {
        ballTrail.targetNode = scene
        ballTrail.particleScale *= 0.15
        ballTrail.particleScaleSpeed *= 0.15
    }
    
    func enableTrail() {
        ballTrail.particleBirthRate = trailBirthrate
    }
    
    func disableTrail() {
        trailBirthrate = ballTrail.particleBirthRate
        ballTrail.particleBirthRate = 0
    }
    
}
