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
    
    let boundingBox: CGRect
    
    var xBound: SKConstraint?
    var yBound: SKConstraint?

    var isActive: Bool {
        return xBound != nil && yBound != nil
    }
    
    private let freedomRadiusBlock: ()->CGFloat
    var freedomRadius: CGFloat {
        return freedomRadiusBlock()
    }
    
    var ballTracking: SKConstraint?
    var isBallTrackingEnabled: Bool {
        return ballTracking != nil
    }

    init(camera: SKCameraNode, boundingBox: CGRect, freedomRadius: @escaping ()->CGFloat) {
        self.camera = camera
        
        self.boundingBox = boundingBox
        
        self.freedomRadiusBlock = freedomRadius
    }
    
}
