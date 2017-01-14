//
//  ShotIndicator.swift
//  MrPutt
//
//  Created by Developer on 1/13/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import SpriteKit

extension UIColor {
    var r: CGFloat {
        return cgColor.components?[0] ?? 0
    }
    var g: CGFloat {
        return cgColor.components?[1] ?? 0
    }
    var b: CGFloat {
        return cgColor.components?[2] ?? 0
    }
}

class ShotIndicator: SKNode {

    var power: CGFloat = 0 {
        didSet {
            power = power < 0 ? 0 : power
            power = power > 1 ? 1 : power
            
            powerIndicator.setScale(power)
            
            let red = UIColor(red: 0.882, green: 0.071, blue: 0.071, alpha: 1)
            let yellow = UIColor(red: 1.0, green: 0.943, blue: 0.023, alpha: 1)
            let green = UIColor(red: 0.086, green: 0.839, blue: 0.324, alpha: 1)
        
            func color(forPower: CGFloat) -> UIColor {
                if power < 0.5 {
                    let step = power / 0.5
                    return UIColor(red: green.r + (yellow.r - green.r)*step,
                                 green: green.g + (yellow.g - green.g)*step,
                                  blue: green.b + (yellow.b - green.b)*step,
                                 alpha: 1)
                } else {
                    let step = (power - 0.5) / 0.5
                    return UIColor(red: yellow.r + (red.r - yellow.r)*step,
                                 green: yellow.g + (red.g - yellow.g)*step,
                                  blue: yellow.b + (red.b - yellow.b)*step,
                                 alpha: 1)
                }
            }
            
            powerIndicator.fillColor = color(forPower: power)
        }
    }
    
    lazy var angleIndicator: SKSpriteNode = {
        return SKSpriteNode(imageNamed: "shotIndicatorArrow")
    }()
    
    lazy var powerIndicator: SKShapeNode = {
        let node = SKShapeNode(circleOfRadius: 72/2)
        node.fillColor = .red
        node.strokeColor = .clear
        return node
    }()
    
    init(orientToward node: SKNode) {
        super.init()
        
        let orient = SKConstraint.orient(to: node, offset: SKRange(constantValue: -.pi/2))
        angleIndicator.constraints = [orient]
        
        addChild(angleIndicator)
        addChild(powerIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}