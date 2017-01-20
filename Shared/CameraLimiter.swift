//
//  CameraLimiter.swift
//  MrPutt
//
//  Created by Developer on 1/20/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import SpriteKit

class CameraLimiter {

    let camera: SKCameraNode
    
    private let freedomRadiusBlock: ()->CGFloat
    var freedomRadius: CGFloat {
        return freedomRadiusBlock()
    }
    
    var xBound: SKConstraint?
    var yBound: SKConstraint?
    
    var isActive: Bool {
        return xBound != nil && yBound != nil
    }
    
    init(camera: SKCameraNode, freedomRadius: @escaping ()->CGFloat) {
        self.camera = camera
        
        self.freedomRadiusBlock = freedomRadius
    }
    
}
