//
//  PuttScene.swift
//  testGolf
//
//  Created by Developer on 12/19/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import AVFoundation
import SpriteKit

import Game
import JWSwiftTools

class PuttScene: SKScene {
    
    lazy var ball: Ball = {
        return self.childNode(withName: "//\(Ball.name)")! as! Ball
    }()
    
    lazy var mat: SKNode = {
        return self.childNode(withName: "//\(Mat.name)")! as! Mat
    }()
    
    var game: Putt!
    
    var holeComplete = false
    
    var opponentsSession: PuttSession?
    
    var shotPath: SKShapeNode? = nil
    var shotIntersectionNode: SKShapeNode? = nil
    
    // MARK: Scene Lifecycle
    
    override func didMove(to view: SKView) {
        view.showsFPS = true
        view.showsPhysics = true
        view.backgroundColor = .black
        
        // sends contact notifications to didBegin(contact:)
        physicsWorld.contactDelegate = self
        
        let camera = SKCameraNode()
        addChild(camera)
        self.camera = camera
        
        startBackgroundAnimations()
        
        ball.updateTrailEmitter()
        
        let _ = UIPanGestureRecognizer(target: self, action: #selector(PuttScene.handlePan(recognizer:)))
        
        let zoom = UIPinchGestureRecognizer(target: self, action: #selector(PuttScene.handleZoom(recognizer:)))
        view.addGestureRecognizer(zoom)
    }
    
    func handleZoom(recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .began, let camera = camera {
            recognizer.scale = 1 / camera.xScale
        }
        
        if recognizer.scale > 0.5 && recognizer.scale < 2 {
            camera?.setScale(1 / recognizer.scale)
        }
    }

    func handlePan(recognizer: UIPanGestureRecognizer) {
        
        if recognizer.state == .began {
            recognizer.setTranslation(.zero, in: recognizer.view)
            
        } else if recognizer.state == .changed {
            
            var translation = recognizer.translation(in: recognizer.view)
            translation = CGPoint(x: -translation.x, y: translation.y)
            
            scene?.position = CGPoint(x: scene!.position.x-translation.x, y: scene!.position.y-translation.y)

            recognizer.setTranslation(.zero, in: recognizer.view)
            
        } else if (recognizer.state == .ended) {
        
        }
    }

    // MARK: Animations

    func startBackgroundAnimations() {
        let ambientNoise = SKAudioNode(fileNamed: "ambience")
        ambientNoise.autoplayLooped = true
        addChild(ambientNoise)
        
        let moveSlow = SKAction.move(by: CGVector(dx: -20, dy: 0), duration: 2)
        let repeatMove = SKAction.repeatForever(moveSlow)
        childNode(withName: "clouds")?.run(repeatMove)
        childNode(withName: "birds")?.run(repeatMove)
    }

    // MARK: Touch Handling

    var adjustingShot = false
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            
            if let ballBody = ball.physicsBody {
                if ballBody.velocity.magnitude < CGFloat(5) {
                    ballBody.velocity = .zero
                    if ball.shotIndicator.parent == nil {
                        // if shotIndicator isn't in the scene, add it
                        ball.addChild(ball.shotIndicator)
                    }
                    adjustingShot = true
                }
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            
            guard adjustingShot else { return }
            
            let ballPosition = ball.parent!.convert(ball.position, to: self)
            
            // rotate slider to the angle of your touch

            ball.shotIndicator.zRotation = ballPosition.angle(toPoint: touchLocation) - .pi / 2
            
            let angle = ballPosition.angle(toPoint: touchLocation)
            let path = CGMutablePath()
            path.move(to: ballPosition)
            path.addLine(to: CGPoint(x: ballPosition.x+300*cos(angle), y: ballPosition.y+300*sin(angle)))
//            let rayEnd = CGPoint(x: ballPosition.x+300*cos(angle), y: ballPosition.y+300*sin(angle))
            
            if let shotPath = shotPath {
                shotPath.path = path
            } else {
                shotPath = shotPath ?? SKShapeNode(path: path)
                shotPath?.lineWidth = 2
                shotPath?.strokeColor = .black
            }

            if shotPath?.parent == nil {
                addChild(shotPath!)
            }
            
            let end = CGPoint(x: ballPosition.x+300*cos(angle), y: ballPosition.y+300*sin(angle))
            
            

            if let shotIntersectionNode = shotIntersectionNode {
                shotIntersectionNode.path = path
            } else {
                shotIntersectionNode = shotPath ?? SKShapeNode(path: path)
                shotIntersectionNode?.lineWidth = 2
                shotIntersectionNode?.strokeColor = .black
            }
            
            if shotIntersectionNode?.parent == nil {
                addChild(shotIntersectionNode!)
            }
            physicsWorld.enumerateBodies(alongRayStart: ballPosition, end: end) { body, point, normal, stop in

                if let node = body.node, node.name == Wall.name {
                    let reflectedPath = CGMutablePath()
                    reflectedPath.move(to: point)
                    
                    let reflected = self.reflect(vector: CGVector(dx: end.x-ballPosition.x, dy: end.y-ballPosition.y), forNormal: normal, at: point, offOf: body)
                    
                    reflectedPath.addLine(to: CGPoint(x: point.x+reflected.dx/5.0, y: point.y+reflected.dy/5.0))
                    
                    self.shotIntersectionNode?.path = reflectedPath
                    
                    stop.pointee = true
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            
            guard adjustingShot else { return }

            let ballPosition = ball.parent!.convert(ball.position, to: self)

            let power = ballPosition.distance(toPoint: touchLocation)
            let angle = ball.shotIndicator.zRotation + .pi / 2
            
            adjustingShot = false
            takeShot(at: angle, with: power)
        }
    }
 
    func takeShot(at angle: CGFloat, with power: CGFloat) {
        let stroke = CGVector(dx: cos(angle) * power,
                              dy: sin(angle) * power)
        
        let sound = SKAction.playSoundFileNamed("clubHit.wav", waitForCompletion: false)
        
        ball.physicsBody?.applyImpulse(stroke)
        run(sound)
        ball.shotIndicator.removeFromParent()
    }
    
    // MARK: Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        ballPrePhysicsVelocity = ball.physicsBody?.velocity ?? .zero
    }
    
    override func didFinishUpdate() {
        if let reflection = reflectionVelocity {
            ball.physicsBody?.velocity = reflection
            reflectionVelocity = nil
        }
    }
}

// MARK: Contact Delegate

var ballPrePhysicsVelocity: CGVector = .zero

var reflectionVelocity: CGVector? = nil

extension PuttScene: SKPhysicsContactDelegate {
   
    func didBegin(_ contact: SKPhysicsContact) {
        let bodies = [contact.bodyA, contact.bodyB]
        
        func node(withName name: String) -> SKNode? {
            return bodies.filter{$0.node?.name==name}.first?.node
        }
        
        if let _ = node(withName: Ball.name), let wall = node(withName: Wall.name) {
            let wallSound = SKAction.playSoundFileNamed("click4.wav", waitForCompletion: false)
            wall.run(wallSound)
            
            reflectionVelocity = reflect(velocity: ballPrePhysicsVelocity,
                                              for: contact,
                                             with: wall.physicsBody!)
        } else {
            reflectionVelocity = nil
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
    
    func didEnd(_ contact: SKPhysicsContact) {
        let bodies = [contact.bodyA, contact.bodyB]
        
        func node(withName name: String) -> SKNode? {
            return bodies.filter{$0.node?.name==name}.first?.node
        }
        
        if let _ = node(withName: Ball.name), let _ = node(withName: Wall.name) {
            
        }
    }
    
    func reflect(velocity entrance: CGVector, for contact: SKPhysicsContact, with body: SKPhysicsBody) -> CGVector {
        
        let ballPosition = convert(ball.position, from: ball.parent!)
        let xRayTest = CGPoint(x: ballPosition.x-contact.contactNormal.dx*5000,
                               y: ballPosition.y+contact.contactNormal.dy*5000)
        let yRayTest = CGPoint(x: ballPosition.x+contact.contactNormal.dx*5000,
                               y: ballPosition.y-contact.contactNormal.dy*5000)
        
        var exit = entrance
        physicsWorld.enumerateBodies(alongRayStart: ballPosition, end: xRayTest) { testBody, _, _, stop in
            
            if testBody == body {
                exit = CGVector(dx: -entrance.dx, dy: entrance.dy)
                stop.pointee = true
            }
        }
        
        physicsWorld.enumerateBodies(alongRayStart: ballPosition, end: yRayTest) { testBody, _, _, stop in
        
            if testBody == body {
                exit = CGVector(dx: entrance.dx, dy: -entrance.dy)
                stop.pointee = true
            }
        }
        
//        if physicsWorld.body(alongRayStart: contact.contactPoint, end: xRayTest) == body {
//            return CGVector(dx: -entrance.dx, dy: entrance.dy)
//        }
//        if physicsWorld.body(alongRayStart: contact.contactPoint, end: yRayTest) == body {
//            return CGVector(dx: entrance.dx, dy: -entrance.dy)
//        }
        return exit
    }
    
    func reflect(vector entrance: CGVector, forNormal normal: CGVector, at point: CGPoint, offOf body: SKPhysicsBody) -> CGVector {
        
        let xRayTest = CGPoint(x: point.x-normal.dx*20, y: point.y+normal.dy*20)
        let yRayTest = CGPoint(x: point.x+normal.dx*20, y: point.y-normal.dy*20)
        
        let xRayStart = CGPoint(x: xRayTest.x-entrance.dx, y: xRayTest.y-entrance.dy)
        let yRayStart = CGPoint(x: yRayTest.x-entrance.dx, y: yRayTest.y-entrance.dy)
        
        
//        let r =d−2(d⋅n)n
//        let reflected = entrance − 2(entrance ⋅ normal)normal
        
//        r=d−(2d⋅n)‖n‖n
        
        let normalized = CGVector(dx: normal.dx/normal.magnitude, dy: normal.dy/normal.magnitude)
        
        let dot = entrance.dx*normalized.dx + entrance.dy*normalized.dy
        let directed = CGVector(dx: dot*normalized.dx, dy: dot*normalized.dy)
        let scaled = CGVector(dx: 2*directed.dx, dy: 2*directed.dy)
        
        let r = CGVector(dx: entrance.dx-scaled.dx, dy: entrance.dy-scaled.dy)
        
        return r
        
        
        
        if physicsWorld.body(alongRayStart: xRayStart, end: xRayTest) != body {
            return CGVector(dx: -entrance.dx, dy: entrance.dy)
        }
        if physicsWorld.body(alongRayStart: yRayStart, end: yRayTest) != body {
            return CGVector(dx: entrance.dx, dy: -entrance.dy)
        }
        return entrance
    }
}
