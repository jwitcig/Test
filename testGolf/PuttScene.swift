//
//  PuttScene.swift
//  testGolf
//
//  Created by Developer on 12/19/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import AVFoundation
import SpriteKit

import JWSwiftTools

class PuttScene: SKScene {
    
    lazy var ball: Ball = {
        return self.childNode(withName: "//\(Ball.name)") as! Ball
    }()
    
    lazy var powerSlider: SKNode = {
        return self.childNode(withName: "powerSlider")!
    }()
    
    var holeComplete = false
    
    // MARK: Scene Lifecycle
    
    override func didMove(to view: SKView) {
        view.showsFPS = true
        view.showsPhysics = true
        view.backgroundColor = .black
        
        // sends contact notifications to didBegin(contact:)
        physicsWorld.contactDelegate = self
        
        let camera = SKCameraNode()
        camera.setScale(0.6)
        addChild(camera)
        self.camera = camera
        
        startBackgroundAnimations()
        
        ball.updateTrailEmitter()
    }
    
    // MARK: Animations
    
    func startBackgroundAnimations() {
        let ambientNoise = SKAudioNode(fileNamed: "ambience")
        ambientNoise.autoplayLooped = true
        addChild(ambientNoise)
        
        let moveSlow = SKAction.move(by: CGVector(dx: -2000, dy: 0), duration: 200)
        childNode(withName: "clouds")?.run(moveSlow)
        childNode(withName: "birds")?.run(moveSlow)
    }
    
    // MARK: Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            
            if ball.physicsBody?.velocity == .zero {
                if powerSlider.parent == nil {
                    // if powerSlider isn't in the scene, add it
                    addChild(powerSlider)
                }
                
                // move power slider to ball's position
                powerSlider.position = ball.parent!.convert(ball.position, to: powerSlider.parent!)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            
            let ballPosition = ball.parent!.convert(ball.position, to: self)
            
            // rotate slider to the angle of your touch
            powerSlider.zRotation = ballPosition.angle(toPoint: touchLocation) - .pi / 2
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            let ballPosition = ball.parent!.convert(ball.position, to: self)

            let power = ballPosition.distance(toPoint: touchLocation)
            let angle = powerSlider.zRotation + .pi / 2
            
            takeShot(at: angle, with: power)
        }
    }
    
    func takeShot(at angle: CGFloat, with power: CGFloat) {
        let stroke = CGVector(dx: cos(angle) * power,
                              dy: sin(angle) * power)
        
        let sound = SKAction.playSoundFileNamed("clubHit.wav", waitForCompletion: false)
        let physics = SKAction.applyImpulse(stroke, duration: 1)
        let afterStroke = SKAction.run {
            self.powerSlider.removeFromParent()
        }
        
        ball.run(physics)
        run(sound)
        run(afterStroke)
    }
    
    // MARK: Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        // runs every frame
    }
}

// MARK: Contact Delegate

extension PuttScene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {
        let bodies = [contact.bodyA, contact.bodyB]
        
        func node(withName name: String) -> SKNode? {
            return bodies.filter{$0.node?.name==name}.first?.node
        }
        
        if let ball = node(withName: Ball.name), let hole = node(withName: Hole.name) {
            // if one node was the ball and another was the hole
            
            guard !holeComplete else { return }
            // if hole isn't already completed

            if let drop = SKAction(named: "Drop") {
                let holePosition = hole.parent!.convert(hole.position, to: ball.parent!)
                
                let insideHole = SKAction.move(to: holePosition, duration: drop.duration/3)
                insideHole.timingMode = .easeOut
                let stopTrail = SKAction.run {
                    self.ball.disableTrail()
                }
                let group = SKAction.group([drop, insideHole, stopTrail])
                
                // stop ball's existing motion
                ball.physicsBody?.velocity = .zero
                
                ball.run(group)
            }
            holeComplete = true
        }
    }
}
