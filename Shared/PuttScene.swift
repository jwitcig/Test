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

public extension SKRange {
    public var openInterval: Range<CGFloat> {
        return lowerLimit..<upperLimit
    }
    
    public var closedInterval: ClosedRange<CGFloat> {
        return lowerLimit...upperLimit
    }
}

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
    
    var teleporting = false
    
    var shots: [Shot] = []
    
    var course: CoursePack.Type!
    var hole: Int!

    var touchNode = SKNode()
    
    lazy var shotIndicator: ShotIndicator = {
        return ShotIndicator(orientToward: self.touchNode)
    }()
    
    var cameraLimiter: CGRect {
        return childNode(withName: "cameraBounds")!.frame
    }
    
    var ballFreedomRadius: CGFloat {
        return size.width * camera!.xScale * 0.4
    }
    
    var cameraXBound: SKConstraint?
    var cameraYBound: SKConstraint?
    
    var isCameraBounded: Bool {
        return cameraXBound != nil && cameraYBound != nil
    }
    
    var ballTracking: SKConstraint?
    var isBallTrackingEnabled: Bool {
        return ballTracking != nil
    }
    
    lazy var pan: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(PuttScene.handlePan(recognizer:)))
        pan.minimumNumberOfTouches = 2
        pan.delegate = self
        pan.cancelsTouchesInView = false
        return pan
    }()
    lazy var zoom: UIPinchGestureRecognizer = {
        let zoom = UIPinchGestureRecognizer(target: self, action: #selector(PuttScene.handleZoom(recognizer:)))
        zoom.delegate = self
        zoom.cancelsTouchesInView = false
        return zoom
    }()
    
    var scorecard: Scorecard?
    
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
        
        addSettingsListener(forKey: "Music")
        
        addChild(shotIndicator)
        
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
    
    func addSettingsListener(forKey key: String) {
        UserDefaults.standard.addObserver(self, forKeyPath: key, options: .new, context: &settingsContext)
    }
    
    func removeGrid() {
        childNode(withName: "grid")?.removeFromParent()
    }
    
    func setDebugOptions(on view: SKView) {
        view.showsFPS = true
        view.showsPhysics = true
        view.backgroundColor = .black
    }
    
    func setupPhysics() {
        // sends contact notifications to didBegin(contact:)
        physicsWorld.contactDelegate = self
        
        // positional audio target
        listener = ball
    }
    
    func setupCamera() {
        if camera == nil {
            camera = SKCameraNode()
            addChild(camera!)
        }
    }
    
    func addGestureRecognizers(in view: SKView) {
        [pan, zoom].forEach(view.addGestureRecognizer)
    }

    func handleZoom(recognizer: UIPinchGestureRecognizer) {
        guard let camera = camera else { return }
        
        if recognizer.state == .began {
            // align recognizer scale with existing camera scale
            recognizer.scale = 1 / camera.xScale
        }
        
        if (0.5...2).contains(recognizer.scale) {
            
            // if within allowable range, set camera scale
            camera.setScale(1 / recognizer.scale)
            
            // remove existing camera bounds
            [cameraXBound, cameraYBound].forEach {
                if let bound = $0, let index = camera.constraints?.index(of: bound) {
                    camera.constraints?.remove(at: index)
                }
            }
        
            // check what camera bounds can be set, set them
            passivelyEnableCameraBounds()

            // reapplies ball tracking constraint, needs to scale with scene
            if isBallTrackingEnabled {
                if let constraint = ballTracking, let index = camera.constraints?.index(of: constraint) {
                    camera.constraints?.remove(at: index)
                }
                
                let range = SKRange(value: 0, variance: ballFreedomRadius)
                ballTracking = SKConstraint.distance(range, to: ball)
                camera.constraints?.insert(ballTracking!, at: 0)
            }
        }
    }

    func handlePan(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began {
            recognizer.setTranslation(.zero, in: recognizer.view)
        } else if recognizer.state == .changed {
            let translation = recognizer.translation(in: recognizer.view)

            let pan = SKAction.moveBy(x: -translation.x, y: translation.y, duration: 0)
            camera?.run(pan)

            // reset recognizer to current camera state
            recognizer.setTranslation(.zero, in: recognizer.view)
        }
    }

    // MARK: Animations

    // MARK: Touch Handling

    var adjustingShot = false
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            
            let location = touch.location(in: ball.parent!)
            
            if let ballBody = ball.physicsBody {
                
                if !adjustingShot {
                    if location.distance(toPoint: ball.position) <= 100 {
                        if ballBody.velocity.magnitude < 5.0 {
                            beginShot()
                        }
                    }
                }
            }
        }
    }
    
    func cancelShot(recognizer: UITapGestureRecognizer) {
        adjustingShot = false
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        shotIndicator.run(fadeOut)
        
        view?.removeGestureRecognizer(recognizer)
    }
    
    func beginShot() {
        ball.disableTrail()

        let dim = SKAction.fadeAlpha(by: -0.3, duration: 0.5)
        dim.timingMode = .easeOut
        
        let enableTrail = SKAction.run(ball.enableTrail)
        let flash = SKAction.sequence([dim, dim.reversed(), enableTrail])
        ball.run(flash)
        
        // force ball to a halt
        ball.physicsBody?.velocity = .zero
        
        shotIndicator.position = convert(ball.position, from: ball.parent!)
        adjustingShot = true
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        shotIndicator.run(fadeIn)
        
        let cancel = UITapGestureRecognizer(target: self, action: #selector(PuttScene.cancelShot(recognizer:)))
        view?.addGestureRecognizer(cancel)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            
            guard adjustingShot else { return }
            
            if touchNode.parent == nil {
                addChild(touchNode)
            }
            touchNode.position = touch.location(in: ball)
            
            let ballLocation = convert(ball.position, from: ball.parent!)
            shotIndicator.power = touchLocation.distance(toPoint: ballLocation) / 300.0
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
            
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            shotIndicator.run(fadeOut)
        }
    }
   
    func takeShot(at angle: CGFloat, with power: CGFloat) {
        let stroke = CGVector(dx: cos(angle) * power,
                              dy: sin(angle) * power)
        
        let sound = SKAudioNode(fileNamed: "clubHit.wav")
        sound.autoplayLooped = false
        sound.isPositional = true
        sound.position = convert(ball.position, from: ball.parent!)
        
        // scale volume with shot power
        let setVolume = SKAction.changeVolume(to: Float(power / 100.0), duration: 0)

        let remove = SKAction.sequence([
            SKAction.wait(forDuration: 1),
            SKAction.removeFromParent(),
        ])
        sound.run(SKAction.group([setVolume, SKAction.play(), remove]))

        addChild(sound)
        
        ball.physicsBody?.applyImpulse(stroke)
        
        let shot = Shot(power: power,
                        angle: angle,
                     position: convert(ball.position, from: ball.parent!))
        // shot data tracked for sending
        shots.append(shot)
        
        // if no ball tracking, move camera toward ball
        if !isBallTrackingEnabled {
            let ballPosition = convert(ball.position, from: ball.parent!)
            
            let pan = SKAction.move(to: ballPosition, duration: 1)
            pan.timingMode = .easeIn
            camera?.run(pan, withKey: "trackingEnabler")
        }
    }
    
    // MARK: Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        // grabs ball velocity before physics calculations,
        // used in wall reflection
        ballPrePhysicsVelocity = ball.physicsBody?.velocity ?? .zero
    }
    
    override func didSimulatePhysics() {
        
        
    }
    
    override func didFinishUpdate() {
        // if there is a wall reflection pending, apply it
        if let reflection = reflectionVelocity {
            ball.physicsBody?.velocity = reflection
            reflectionVelocity = nil
        }
        
        if !isBallTrackingEnabled {
            passivelyEnableBallTracking()
        } else if isBallTrackingEnabled && !isCameraBounded {
            passivelyEnableCameraBounds()
        }
    }
    
    func passivelyEnableBallTracking() {
        let ballPosition = convert(ball.position, from: ball.parent!)
        
        // if ball is withing tracking range, start tracking
        guard let _ = camera?.action(forKey: "trackingEnabler"),
            camera!.position.distance(toPoint: ballPosition) < ballFreedomRadius else {
            return
        }
        let tracking = SKConstraint.distance(SKRange(value: 0, variance: ballFreedomRadius), to: ball)
        camera?.constraints?.insert(tracking, at: 0)
        camera?.removeAction(forKey: "trackingEnabler")
        
        ballTracking = tracking
    }
    
    func passivelyEnableCameraBounds() {
        let cameraSize = CGSize(width: size.width * camera!.xScale, height: size.height * camera!.yScale)
        
        var xRange: SKRange!
        var yRange: SKRange!
        
        if cameraLimiter.width < cameraSize.width {

        } else {
            xRange = SKRange(lowerLimit: cameraLimiter.minX + cameraSize.width/2,
                             upperLimit: cameraLimiter.maxX - cameraSize.width/2)
        }
        
        if cameraLimiter.height < cameraSize.height {

        } else {
            yRange = SKRange(lowerLimit: cameraLimiter.minY + cameraSize.height/2,
                             upperLimit: cameraLimiter.maxY - cameraSize.height/2)
        }
        
        if let range = xRange, range.closedInterval.contains(camera!.position.x), cameraXBound == nil {
            
            cameraXBound = SKConstraint.positionX(range)
            camera?.constraints?.insert(cameraXBound!, at: camera!.constraints!.count)
        }
        
        if let range = yRange, range.closedInterval.contains(camera!.position.y), cameraYBound == nil {
            
            cameraYBound = SKConstraint.positionY(range)
            camera?.constraints?.insert(cameraYBound!, at: camera!.constraints!.count)
        }
    }
}

// MARK: Contact Delegate

var ballPrePhysicsVelocity: CGVector = .zero

var reflectionVelocity: CGVector? = nil

var lastFrameContact: SKPhysicsBody?

extension PuttScene: SKPhysicsContactDelegate {
   
    func didBegin(_ contact: SKPhysicsContact) {
        let bodies = [contact.bodyA, contact.bodyB]
        
        func node(withName name: String) -> SKNode? {
            return bodies.filter{$0.node?.name==name}.first?.node
        }
        
        if let _ = node(withName: Ball.name) as? Ball,
            let wall = node(withName: Wall.nodeName) as? Wall {
            
            ballHitWall(wall, contact: contact)
        }
        
        if let _ = node(withName: Ball.name) as? Ball, let hole = node(withName: Hole.name) as? Hole {
           ballHitHole(hole, contact: contact)
        }
        
        if let _ = node(withName: Ball.name), let portal = node(withName: Portal.name) as? Portal {
            ballHitPortal(portal, contact: contact)
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        let bodies = [contact.bodyA, contact.bodyB]
        
        func node(withName name: String) -> SKNode? {
            return bodies.filter{$0.node?.name==name}.first?.node
        }
        
        if let _ = node(withName: Ball.name), let _ = node(withName: Wall.nodeName) {
            
        }
    }
    
    func reflect(velocity entrance: CGVector, for contact: SKPhysicsContact, with body: SKPhysicsBody) -> CGVector {
        return reflect(vector: entrance, across: contact.contactNormal, at: contact.contactPoint, offOf: body)
    }
    
    func reflect(vector entrance: CGVector, across normal: CGVector, at point: CGPoint, offOf body: SKPhysicsBody) -> CGVector {
  
//        let r =d−2(d⋅n)n
//        let reflected = entrance − 2(entrance ⋅ normal)normal
//        r = d−(2d⋅n)‖n‖n
        
        let normalized = normal.normalized
        
        let dot = entrance • normalized
        let directed = CGVector(dx: dot*normalized.dx, dy: dot*normalized.dy)
        let scaled = CGVector(dx: 2*directed.dx, dy: 2*directed.dy)
        
        let r = CGVector(dx: entrance.dx-scaled.dx, dy: entrance.dy-scaled.dy)
        
        return r
    }
    
    func ballHitWall(_ wall: Wall, contact: SKPhysicsContact) {
        wall.run(Action.with(name: .wallHit))
        
        reflectionVelocity = reflect(velocity: ballPrePhysicsVelocity,
                                          for: contact,
                                         with: wall.physicsBody!)
    }
    
    func ballHitHole(_ hole: Hole, contact: SKPhysicsContact) {
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
    
    func ballHitPortal(_ portal: Portal, contact: SKPhysicsContact) {
        guard !teleporting else { teleporting = false; return }
        
        if let destination = portal.parent?.parent?.parent?.userData?["destination"] as? String {
            
            enumerateChildNodes(withName: "//portal") { node, stop in
                let userData = node.parent?.parent?.parent?.userData
                if userData?["name"] as? String == destination {
                    let move = SKAction.move(to: node.parent!.convert(node.position, to: self.ball.parent!), duration: 0)
                    
                    let velocityXMultipler = userData?["velocityXMultiplier"] as? CGFloat ?? 1
                    let velocityYMultipler = userData?["velocityYMultiplier"] as? CGFloat ?? 1
                    
                    self.ball.physicsBody?.velocity.dx *= velocityXMultipler
                    self.ball.physicsBody?.velocity.dy *= velocityYMultipler
                    self.ball.run(move)
                    
                    let sound = SKAction.playSoundFileNamed("portalTransfer.mp3", waitForCompletion: false)
                    self.run(sound)
                    
                    self.teleporting = true
                }
            }
        }
    }
    
    func showScorecard(hole: Int, names: (String, String), player1Strokes: [Int], player2Strokes: [Int], pars: [Int], donePressed: @escaping ()->Void) {
        
        let scorecard = SKScene(fileNamed: "Scorecard")! as! Scorecard
        self.scorecard = scorecard
        scorecard.update(hole: hole, names: names, player1Strokes: player1Strokes, player2Strokes: player2Strokes, pars: pars)
        scorecard.donePressed = donePressed
        scorecard.zPosition = 100
        
        
    
        let duration: TimeInterval = 0.8
        scorecard.children.forEach {
            let scale = camera!.xScale
            $0.setScale(scale)
            
            let x = ($0.position.x * scale) + camera!.position.x
            let y = ($0.position.y * scale) + camera!.position.y
            let destination: CGPoint = self.convert(CGPoint(x: x, y: y), to: scorecard)

            $0.position = CGPoint(x: $0.position.x-size.width*(0.75)*scale, y: $0.position.y*scale)
            
            
            let slide = SKAction.move(to: destination, duration: duration)
            slide.timingMode = .easeOut
            
            $0.run(slide)
        }
        
        let delay = SKAction.wait(forDuration: duration)
        let show = SKAction.run(scorecard.showHoleInfo)
        
        let sequence = SKAction.sequence([delay, show])
        scorecard.infoPanel.run(sequence)
        
        addChild(scorecard)
        
        let touch = UITapGestureRecognizer(target: self, action: #selector(PuttScene.sceneClosePressed(recognizer:)))
        view?.addGestureRecognizer(touch)
    }
    
    func sceneClosePressed(recognizer: UITapGestureRecognizer) {
        guard let scorecard = scorecard else { return  }
        let viewLocation = recognizer.location(in: view!)
        let sceneLocation = convertPoint(fromView: viewLocation)
        
        let location = convert(sceneLocation, to: scorecard)
        
        if scorecard.button.contains(location) {
            scorecard.donePressed()
        }
    }
}

extension PuttScene: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    
        if gestureRecognizer == pan && otherGestureRecognizer == zoom {
            return true
        }
        if gestureRecognizer == zoom && otherGestureRecognizer == pan {
            return true
        }
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if gestureRecognizer == pan || gestureRecognizer == zoom {
            if adjustingShot {
                return false
            }
        }
        
        return true
    }
}
