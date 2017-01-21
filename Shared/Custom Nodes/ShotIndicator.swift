//
//  ShotIndicator.swift
//  MrPutt
//
//  Created by Developer on 1/13/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import SpriteKit

import JWSwiftTools

extension UIColor {
    var r: CGFloat {
        return cgColor.components?[safe: 0] ?? 0
    }
    var g: CGFloat {
        return cgColor.components?[safe: 1] ?? 0
    }
    var b: CGFloat {
        return cgColor.components?[safe: 2] ?? 0
    }
}

class ShotIndicator: SKNode {
    
    let motionDuration: TimeInterval = 0.2

    var power: CGFloat = 0 {
        didSet {
            power = power < 0 ? 0 : power
            power = power > 1 ? 1 : power
            
            powerIndicator.setScale(power)
            
            let red = UIColor(red: 0.882, green: 0.071, blue: 0.071, alpha: 1)
            let yellow = UIColor(red: 1.0, green: 0.943, blue: 0.023, alpha: 1)
            let green = UIColor(red: 0.086, green: 0.839, blue: 0.324, alpha: 1)
            
            func color(forPower: CGFloat) -> UIColor {
                return UIColor(red: yellow.r + (red.r - yellow.r)*power,
                             green: yellow.g + (red.g - yellow.g)*power,
                              blue: yellow.b + (red.b - yellow.b)*power,
                             alpha: 1)
            }
            
            powerIndicator.fillColor = color(forPower: power)
        }
    }
    
    lazy var ballIndicator: SKSpriteNode = {
        return SKSpriteNode(imageNamed: "shotIndicatorCircle")
    }()
    
    lazy var angleIndicator: SKSpriteNode = {
        return SKSpriteNode(imageNamed: "shotIndicatorArrow")
    }()
    
    lazy var powerIndicator: SKShapeNode = {
        let node = SKShapeNode(circleOfRadius: 72/2)
        node.fillColor = .red
        node.strokeColor = .clear
        return node
    }()
    
    init(orientToward node: SKNode, withOffset offset: SKRange) {
        super.init()
        
        let orient = SKConstraint.orient(to: node, offset: offset)
        angleIndicator.constraints = [orient]
        
        addChild(angleIndicator)
        addChild(ballIndicator)
        addChild(powerIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func ballStopped() {
        let fadeIn = SKAction.fadeIn(withDuration: motionDuration)
        ballIndicator.run(fadeIn)
    }
    
    func showAngle() {
        let fadeIn = SKAction.fadeIn(withDuration: motionDuration)
        angleIndicator.run(fadeIn)
    }
    
    func shotTaken() {
        let fadeOut = SKAction.fadeOut(withDuration: motionDuration)
        ballIndicator.run(fadeOut)
        angleIndicator.run(fadeOut)
        power = 0
    }
    
    func shotCancelled() {
        let fadeOut = SKAction.fadeOut(withDuration: motionDuration)
        angleIndicator.run(fadeOut)
        power = 0
    }
    
}
