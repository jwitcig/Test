//
//  HoleSetup.swift
//  MrPutt
//
//  Created by Developer on 1/1/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import Foundation
import SpriteKit

enum Course: Int {
    case Blaze, Timber, Whiteout
}

class HoleSetup {
    
    static func setup(_ scene: SKScene, forHole hole: Int, inCourse course: Course) {
        
        let background = scene.childNode(withName: "background") as? SKSpriteNode
        background?.texture = SKTexture(imageNamed: "wall canvas")
        
        switch course {
        case .Blaze:
            
            switch hole {
            default:
                break
            }
            
        case .Timber:
            
            switch hole {
            default:
                break
            }

        case .Whiteout:
            
            switch hole {
            default:
                break
            }
            
        }
    }
    
}
