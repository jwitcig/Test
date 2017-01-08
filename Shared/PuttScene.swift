//
//  PuttScene.swift
//  testGolf
//
//  Created by Developer on 12/19/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import AVFoundation
import GameplayKit
import SpriteKit

import Game
import JWSwiftTools

private var settingsContext = 0

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
    
    var teleporting = false
    
    var shots: [Shot] = []
    
    var course: CoursePack.Type!
    var hole: Int!
    
    // MARK: Scene Lifecycle

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &settingsContext {
            if let newValue = change?[.newKey] {
                if keyPath == Options.gameMusic.rawValue {
                     audioEngine.mainMixerNode.outputVolume = (newValue as? NSNumber)?.floatValue ?? 1.0
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    override func didMove(to view: SKView) {
        setDebugOptions(on: view)
    
        scaleMode = .resizeFill
        
        removeGrid()
        
        addGestureRecognizers(in: view)
        
        setupPhysics()
        
        setupCamera()
    
        ball.updateTrailEmitter()
        
//        animateTilesIntoScene()
        
        UserDefaults.standard.addObserver(self, forKeyPath: "Music", options: .new, context: &settingsContext)
        
//        let light = ball.childNode(withName: "light") as! SKLightNode
//        
//        let random = GKRandomDistribution(lowestValue: 0, highestValue: 1)
//        
//        let quantity = 2
//        
//        if let snow = childNode(withName: "//snow") as? SKEmitterNode {
//            snow.targetNode = self
//        }
//        
//        var colorizers: [((CGFloat, CGFloat, CGFloat), String, SKAction)] = []
//        
//        for i in 0..<quantity {
//            let r = CGFloat(random.nextUniform())
//            let g = CGFloat(random.nextUniform())
//            let b = CGFloat(random.nextUniform())
//            
//            let duration: CGFloat = 0.3
//        
//            let previous = i > 0 ? colorizers[i-1].0 : (1, 1, 1)
//            let action: (SKNode, CGFloat)->Void = { node, timestep in
//                let tR = previous.0 + (r - previous.0) * (timestep/duration)
//                let tG = previous.1 + (g - previous.1) * (timestep/duration)
//                let tB = previous.2 + (b - previous.2) * (timestep/duration)
//                
//                light.lightColor = UIColor(red: tR,
//                                         green: tG,
//                                          blue: tB,
//                                         alpha: 1)
//            }
//            
//            let colorizer = SKAction.customAction(withDuration: TimeInterval(duration), actionBlock: action)
//        
//            colorizers.append(((r, g, b), "\(i)", colorizer))
//        }
        
//        let colorizeRed = SKAction.customAction(withDuration: 0.5) { node, timestep in
//            light.lightColor = UIColor(red: 1.0 * (timestep/0.5), green: 0, blue: 0, alpha: 1)
//        }
//        
//        let colorizeBlue = SKAction.customAction(withDuration: 0.5) { node, timestep in
//            light.lightColor = UIColor(red: 0, green: 0, blue: 1.0 * (timestep/0.5), alpha: 1)
//        }
        
//        let flash = SKAction.sequence(colorizers.map{$0.2})
//        light.run(SKAction.repeatForever(flash))
//        light.removeFromParent()
    }
    
    func removeGrid() {
        childNode(withName: "grid")?.removeFromParent()
    }
    
    func setDebugOptions(on view: SKView) {
        view.showsFPS = true
        view.showsPhysics = false
        view.backgroundColor = .black
    }
    
    func setupPhysics() {
        // sends contact notifications to didBegin(contact:)
        physicsWorld.contactDelegate = self
        
        listener = ball
    }
    
    func setupCamera() {
        if self.camera == nil {
            self.camera = SKCameraNode()
            addChild(self.camera!)
        }
    }
    
    func addGestureRecognizers(in view: SKView) {
        let _ = UIPanGestureRecognizer(target: self, action: #selector(PuttScene.handlePan(recognizer:)))
        
        let zoom = UIPinchGestureRecognizer(target: self, action: #selector(PuttScene.handleZoom(recognizer:)))
        view.addGestureRecognizer(zoom)
    }
    
    func animateTilesIntoScene() {
        guard let view = view else { return }
        
        let scaledWidth = Int(view.frame.width * 0.7)
        let scaledHeight = Int(view.frame.height * 0.7)
        
        let generator = RandomPointGenerator(x: (low: -scaledWidth, high: scaledWidth),
                                             y: (low: -scaledHeight, high: scaledHeight),
                                        source: GKRandomSource())
        
        let randomDuration = GKRandomDistribution(lowestValue: 2, highestValue: 2)
        enumerateChildNodes(withName: "SKReferenceNode") { node, stop in
            guard let nodeParent = node.parent else { return }
            
            let finalPosition = node.position
            
            let newPosition = CGPoint(x: finalPosition.x, y: generator.newPoint().y)
            
            node.position = self.convert(newPosition, to: nodeParent)
            node.alpha = 0
            
            let duration = TimeInterval(randomDuration.nextInt())
            
            let fadeIn = SKAction.fadeIn(withDuration: duration)
            let move = SKAction.move(to: finalPosition, duration: duration)
            
            let actions = SKAction.group([fadeIn, move])
            node.run(actions)
        }
    }
    
    func handleZoom(recognizer: UIPinchGestureRecognizer) {
        guard let camera = camera else { return }
        
        if recognizer.state == .began {
            recognizer.scale = 1 / camera.xScale
        }
        
        if recognizer.scale > 0.5 && recognizer.scale < 2 {
            camera.setScale(1 / recognizer.scale)
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

    // MARK: Touch Handling

    var adjustingShot = false
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            
            if let ballBody = ball.physicsBody {
                if ballBody.velocity.magnitude < CGFloat(5) {
                
                    let dim = SKAction.fadeAlpha(by: -0.3, duration: 0.5)
                    dim.timingMode = .easeOut

                    ball.disableTrail()
                    let enableTrail = SKAction.run(ball.enableTrail)
                    let flash = SKAction.sequence([dim, dim.reversed(), enableTrail])
                    ball.run(flash)
                    
                    ballBody.velocity = .zero
                    
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
            let angle = ballPosition.angle(toPoint: touchLocation)
            
            adjustingShot = false
            takeShot(at: angle, with: power)
        }
    }
 
    func takeShot(at angle: CGFloat, with power: CGFloat) {
        let stroke = CGVector(dx: cos(angle) * power,
                              dy: sin(angle) * power)
        
        let sound = SKAudioNode(fileNamed: "clubHit.wav")
        sound.autoplayLooped = false
        sound.position = convert(ball.position, from: ball.parent!)
        let setVolume = SKAction.changeVolume(to: Float(power / 100.0), duration: 0)

        let removal = SKAction.sequence([
            SKAction.wait(forDuration: 1),
            SKAction.removeFromParent()
        ])
        
//        addChild(sound)
        
        sound.run(SKAction.group([setVolume, SKAction.play(), removal]))
        ball.physicsBody?.applyImpulse(stroke)
        
        shots.append(Shot(power: power, angle: angle, position: convert(ball.position, from: ball.parent!)))
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
            wall.run(Action.with(name: .wallHit))
            
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
                
                game.finish()
            }
            holeComplete = true
        }
        
        if let ball = node(withName: Ball.name), let portal = node(withName: Portal.name) {
            guard !teleporting else { teleporting = false; return }
            
            if let destination = portal.parent?.parent?.parent?.userData?["destination"] as? String {
                
                enumerateChildNodes(withName: "//portal") { node, stop in

                    if node.parent?.parent?.parent?.userData?["name"] as? String == destination {
                        let move = SKAction.move(to: node.parent!.convert(node.position, to: ball.parent!), duration: 0)
                        ball.run(move)
                        
                        let sound = SKAction.playSoundFileNamed("portalTransfer.mp3", waitForCompletion: false)
                        self.run(sound)
                        
                        self.teleporting = true
                    }
                }
            }
        
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
  
//        let r =d−2(d⋅n)n
//        let reflected = entrance − 2(entrance ⋅ normal)normal
        
//        r=d−(2d⋅n)‖n‖n
        
        let normalized = CGVector(dx: normal.dx/normal.magnitude, dy: normal.dy/normal.magnitude)
        
        let dot = entrance.dx*normalized.dx + entrance.dy*normalized.dy
        let directed = CGVector(dx: dot*normalized.dx, dy: dot*normalized.dy)
        let scaled = CGVector(dx: 2*directed.dx, dy: 2*directed.dy)
        
        let r = CGVector(dx: entrance.dx-scaled.dx, dy: entrance.dy-scaled.dy)
        
        return r
    }
}
