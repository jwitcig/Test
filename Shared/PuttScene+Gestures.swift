//
//  PuttScene+Gestures.swift
//  MrPutt
//
//  Created by Developer on 1/22/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import SpriteKit
import UIKit

import FirebaseAnalytics

extension PuttScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.count == 1 else { return }
        
        for touch in touches {
            
            let location = touch.location(in: ball.visual.parent!)
            
            if !adjustingShot {
                if location.distance(toPoint: self.ball.visual.position) <= 100 {
                    if self.ball.physics.body.velocity.magnitude < 5.0 {
                        self.beginShot()
                        
                        self.shotIndicator.showAngle()
                    }
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            
            guard adjustingShot else { return }
            
            if touchNode.parent == nil {
                addChild(touchNode)
            }
            touchNode.position = touch.location(in: ball.visual.node)
            
            let ballLocation = ball.visual.position(in: self)!
            shotIndicator.power = (touchLocation.distance(toPoint: ballLocation) / camera!.xScale - shotIndicator.ballIndicator.size.width / 2) / 60.0
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            
            guard adjustingShot else { return }
            adjustingShot = false

            let ballPosition = ball.visual.position(in: self)!
            
            let shotThreshold = shotIndicator.ballIndicator.size.width / 2
            
            guard ballPosition.distance(toPoint: touchLocation) > shotThreshold else { return }
            
            let angle = ballPosition.angle(toPoint: touchLocation) + .pi
            
            takeShot(at: angle, with: shotIndicator.power * 600)
            
            shotIndicator.shotTaken()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        adjustingShot = false
    }
    
    func handleZoom(recognizer: UIPinchGestureRecognizer) {
        guard let camera = camera else { return }
        
        if recognizer.state == .began {
            // align recognizer scale with existing camera scale
            recognizer.scale = 1 / camera.xScale
            
            let params: [String : NSObject] = [
                "hole_number": holeNumber as NSObject,
                "course": course.name as NSObject,
                ]
            FIRAnalytics.logEvent(withName: "ZoomGesture", parameters: params)
        }
        
        if (0.6...1.3).contains(recognizer.scale) {
            
            // if within allowable range, set camera scale
            camera.setScale(1 / recognizer.scale)
            
            // remove existing camera bounds
            [limiter.xBound, limiter.yBound].forEach {
                if let bound = $0, let index = camera.constraints?.index(of: bound) {
                    camera.constraints?.remove(at: index)
                }
            }
            
            // check what camera bounds can be set, set them
            passivelyEnableCameraBounds()
            
            camera.childNode(withName: "background")?.setScale(1 / camera.xScale / 0.8)
        }
    }
    
    func handlePan(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began {
            recognizer.setTranslation(.zero, in: recognizer.view)
            
            let params: [String : NSObject] = [
                "hole_number": holeNumber as NSObject,
                "course": course.name as NSObject,
                ]
            FIRAnalytics.logEvent(withName: "PanGesture", parameters: params)
            
        } else if recognizer.state == .changed {
            let translation = recognizer.translation(in: recognizer.view)
            
            let pan = SKAction.moveBy(x: -translation.x, y: translation.y, duration: 0)
            camera?.run(pan)
            
            // reset recognizer to current camera state
            recognizer.setTranslation(.zero, in: recognizer.view)
        }
    }
    
    func cancelShot(recognizer: UITapGestureRecognizer) {
        adjustingShot = false
        
        let ballPosition = ball.visual.position(in: hole.visual.parent!)!
        if ballPosition.distance(toPoint: hole.visual.position) <= 150 {
            flag.lower()
        }
        
        shotIndicator.shotCancelled()
        
        view?.removeGestureRecognizer(recognizer)
        
        let params: [String : NSObject] = [
            "hole_number": holeNumber as NSObject,
            "course": course.name as NSObject,
            ]
        FIRAnalytics.logEvent(withName: "ShotCancelled", parameters: params)
    }
}

extension PuttScene: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let manager = gestureManager
        
        if gestureRecognizer == manager.pan && otherGestureRecognizer == manager.zoom {
            return true
        }
        if gestureRecognizer == manager.zoom && otherGestureRecognizer == manager.pan {
            return true
        }
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == gestureManager.pan {
            
            let location = touch.location(in: self)
            let ballLocation = ball.visual.position(in: self)!
            
            if location.distance(toPoint: ballLocation) <= 100, !adjustingShot {
                return false
            }
        }
        return true
    }
}
