//
//  PuttScene+Camera.swift
//  MrPutt
//
//  Created by Developer on 1/22/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import Foundation
import SpriteKit

extension PuttScene {
    
    func setupCamera() {
        camera?.zPosition = -10
        
        let background = SKSpriteNode(imageNamed: course.name.lowercased()+"Background")
        background.name = "background"
        background.size = CGSize(width: 800, height: 1600)
        camera?.addChild(background)
    }
    
    func passivelyEnableBallTracking() {
        let ballPosition = ball.visual.position(in: self)!
        
        // if ball is withing tracking range, start tracking
        guard let _ = camera?.action(forKey: "trackingEnabler"),
            camera!.position.distance(toPoint: ballPosition) <= limiter.freedomRadius else {
                return
        }
        let tracking = SKConstraint.distance(SKRange(upperLimit: limiter.freedomRadius), to: ball.visual.node)
        if let _ = camera?.constraints {
            camera?.constraints?.insert(tracking, at: 0)
        } else {
            camera?.constraints = [tracking]
        }
        camera?.removeAction(forKey: "trackingEnabler")
        
        limiter.ballTracking = tracking
    }
    
    func passivelyEnableCameraBounds() {
        let cameraSize = CGSize(width: size.width * camera!.xScale,
                                height: size.height * camera!.yScale)
        
        let cameraLimiter = limiter.boundingBox
        
        var lowerX = cameraLimiter.minX - cameraLimiter.width/2 + cameraSize.width/2
        var upperX = cameraLimiter.maxX - cameraLimiter.width/2 - cameraSize.width/2
        
        if lowerX > upperX {
            lowerX = 0
            upperX = 0
        }
        
        var lowerY = cameraLimiter.minY - cameraLimiter.size.height/2 + cameraSize.height/2
        var upperY = cameraLimiter.maxY - cameraLimiter.size.height/2 - cameraSize.height/2
        
        if lowerY > upperY {
            lowerY = 0
            upperY = 0
        }
        
        let xRange = SKRange(lowerLimit: lowerX, upperLimit: upperX)
        let yRange = SKRange(lowerLimit: lowerY, upperLimit: upperY)
        
        limiter.xBound = SKConstraint.positionX(xRange)
        limiter.yBound = SKConstraint.positionY(yRange)
        
        var constraints = camera?.constraints ?? []
        constraints.append(limiter.xBound!)
        constraints.append(limiter.yBound!)
        camera?.constraints = constraints
    }
}
