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

import FirebaseAnalytics
import PocketSVG
import SWXMLHash

class PuttScene: SKScene {
    
    lazy var entityManager: EntityManager = {
        return EntityManager(world: self)
    }()
    
    var startTime: Date!
    
    lazy var ball: BallEntity = {
        let scene = SKScene(fileNamed: "Ball")!
        let node = scene.childNode(withName: "//\(Ball.name)")! as! Ball
        node.removeFromParent()
        return BallEntity(node: node, physics: node.physicsBody!)
    }()
    
    lazy var shotIndicator: ShotIndicator = {
        return ShotIndicator(orientToward: self.touchNode, withOffset: SKRange(constantValue: .pi/2))
    }()
    
    lazy var hole: HoleEntity = {
        let node = self.childNode(withName: "//\(Hole.name)")! as! Hole
        node.removeFromParent()
        return HoleEntity(node: node)
    }()
    
    lazy var flag: Flag = {
        return self.childNode(withName: "//\(Flag.name)")! as! Flag
    }()
    
    var game: Putt!
    
    var holeComplete = false
    
    var opponentsSession: PuttSession?
    
    var teleporting = false
    
    var shots: [Shot] = [] {
        didSet {
            hud.strokes = shots.count
            
            if shots.count > par {
                UIView.animate(withDuration: 0.5) {
                    self.hud.strokeLabel.textColor = .red
                }
            }
        }
    }
    
    var course: CoursePack.Type!
    var holeNumber: Int!
    
    lazy var par: Int = {
        return HoleInfo.par(forHole: self.holeNumber, in: self.course)
    }()
    
    let audio = AudioManager()
    
    lazy var gestureManager: GestureManager = {
        return GestureManager(delegate: self as UIGestureRecognizerDelegate)
    }()
    
    var touchNode = SKNode()
    
    var hud: HUDView!
    
    var limiter: CameraLimiter!
    
    var scorecard: Scorecard?
    
    // MARK: Scene Lifecycle

    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        
        let holeData = HoleData(holeNumber: holeNumber, course: course)
        configure(for: holeData, in: view)
        
        initiate(with: holeData)
        initiateAnimations(with: holeData)
        
        drawHole(for: holeData)

        passivelyEnableCameraBounds()
        
        let params: [String : NSObject] = [
            "course": course.name as NSObject,
            "hole": course.holeCount as NSObject,
        ]
        FIRAnalytics.logEvent(withName: "RoundStart", parameters: params)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &UserSettings.context {
            
            if let newValue = change?[.newKey] {
                if keyPath == Options.gameMusic.rawValue {
                    
                    if let isMusicOn = newValue as? Bool {
                        if isMusicOn {
                            audio.backgroundMusic?.resume()
                        } else {
                            audio.backgroundMusic?.pause()
                        }
                    }
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func updateShotIndicatorPosition() {
        if let shotIndicatorParent = shotIndicator.visual.parent, let ballParent = ball.visual.parent {
            shotIndicator.visual.position = ballParent.convert(ball.visual.position, to: shotIndicatorParent)
        }
    }
    
    func beginShot() {
        let ballPosition = ball.visual.position(in: hole.visual.parent!)!
        
        let distanceToHole = ballPosition.distance(toPoint: hole.visual.position)
        if distanceToHole <= 150 {
            flag.raise()
            
            let fadeDown = SKAction.fadeAlpha(to: 0.6, duration: 0.4)
            shotIndicator.visual.node.run(fadeDown)
            
            let params = [
                "hole_number": holeNumber as NSObject,
                "course": course.name as NSObject,
                kFIRParameterValue: distanceToHole as NSObject,
            ]
            FIRAnalytics.logEvent(withName: "ShotNearHole", parameters: params)
        }
        
        if UserSettings.current.isEffectsEnabled {
            let selection = SKAction.playSoundFileNamed("ballSelect.mp3", waitForCompletion: false)
            ball.visual.node.run(selection)
        }
        
        ball.disableTrail()

        let dim = SKAction.fadeAlpha(by: -0.3, duration: 0.5)
        dim.timingMode = .easeOut
        
        let enableTrail = SKAction.run(ball.enableTrail)
        let flash = SKAction.sequence([dim, dim.reversed(), enableTrail])
        ball.visual.node.run(flash)
        
        // force ball to a halt
        ball.physics.body.velocity = .zero
        
        shotIndicator.visual.position = convert(ball.visual.position, from: ball.visual.parent!)
        adjustingShot = true
        
        let cancel = UITapGestureRecognizer(target: self, action: #selector(PuttScene.cancelShot(recognizer:)))
        view?.addGestureRecognizer(cancel)
        
        // if no ball tracking, move camera toward ball
        if !limiter.isBallTrackingEnabled {
            let ballPosition = ball.visual.position(in: self)!
            
            if ballPosition.distance(toPoint: camera!.position) > limiter.freedomRadius {
                let pan = SKAction.move(to: ballPosition, duration: 1)
                pan.timingMode = .easeInEaseOut
                camera?.run(pan, withKey: "trackingEnabler")
            }
        }
    }
    
    var adjustingShot = false

    var lastShotTime: Date!
   
    func takeShot(at angle: CGFloat, with power: CGFloat) {
        let shot = Shot(power: power,
                        angle: angle,
                     position: ball.visual.position(in: self)!)
        // shot data tracked for sending
        shots.append(shot)

        ball.physics.body.applyImpulse(shot.stroke)
        
        if UserSettings.current.isEffectsEnabled {
            let sound = SKAudioNode(fileNamed: "clubHit.wav")
            sound.autoplayLooped = false
            sound.position = ball.visual.position(in: self)!
            
            // scale volume with shot power
            let setVolume = SKAction.changeVolume(to: Float(power / 100.0), duration: 0)
            
            let remove = SKAction.sequence([
                SKAction.wait(forDuration: 1),
                SKAction.removeFromParent(),
            ])
            sound.run(SKAction.group([setVolume, SKAction.play(), remove]))
            
            addChild(sound)
        }
        
        let params: [String : NSObject] = [
            "power": power as NSObject,
            kFIRParameterValue: power as NSObject,
            "hole_number": holeNumber as NSObject,
            "course": course.name as NSObject,
            "duration": Date().timeIntervalSince1970 - lastShotTime.timeIntervalSince1970 as NSObject
        ]
        lastShotTime = Date()
        FIRAnalytics.logEvent(withName: "ShotTaken", parameters: params)
    }
    
    // MARK: Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        // grabs ball velocity before physics calculations,
        // used in wall reflection
        let body = ball.physics.body
        
        ballPrePhysicsVelocity = body.velocity
        
        let ballPosition = ball.visual.position(in: self)!
        let distanceFromCamera = ballPosition.distance(toPoint: camera!.position)
        if adjustingShot, distanceFromCamera <= limiter.freedomRadius {
            passivelyEnableBallTracking()
        }
    }
    
    override func didFinishUpdate() {
        // if there is a wall reflection pending, apply it
        if let reflection = reflectionVelocity {
            ball.physics.body.applyImpulse(reflection/3)
            reflectionVelocity = nil
        }
        
        if !limiter.isActive {
            passivelyEnableCameraBounds()
        }
    }
    
    override func didSimulatePhysics() {
        ball.ballTrail?.particleAlpha = 0.1 + (ball.physics.body.velocity.magnitude / 80.0) * 0.2
        if holeComplete {
            let distanceToHole = ball.visual.position(in: hole.visual.parent!)!.distance(toPoint: hole.visual.position)
            
            if distanceToHole < 5 {
                (hole.visual.node.childNode(withName: "gravity") as? SKFieldNode)?.strength = 30
            }
        }
        
        let body = ball.physics.body
        if body.velocity.magnitude < 5.0 {
            if let ballTracking = limiter.ballTracking, let index = camera?.constraints?.index(of: ballTracking), body.isResting {
                camera?.constraints?.remove(at: index)
                self.limiter.ballTracking = nil
            }
            
            if shotIndicator.ballIndicator.alpha != 1.0 {
                updateShotIndicatorPosition()
                shotIndicator.ballStopped()
            }
            
            let ballPosition = ball.visual.position(in: hole.visual.parent!)!
            if ballPosition.distance(toPoint: hole.visual.position) > 150, !flag.isWiggling {
                flag.lower()
            }
        } else {
            shotIndicator.shotTaken()
        }

    }
    
    deinit {
        print("PuttScene is gone!")
    }
}

// MARK: Contact Delegate

var ballPrePhysicsVelocity: CGVector = .zero

var reflectionVelocity: CGVector? = nil

var holeCupConstraint: SKConstraint?

var lastWallCollision: (SKPhysicsContact, CGVector, TimeInterval)?

extension PuttScene: SKPhysicsContactDelegate {
   
    func didBegin(_ contact: SKPhysicsContact) {
        let bodies = [contact.bodyA, contact.bodyB]
        
        func node(withName name: String) -> SKNode? {
            return bodies.filter{$0.node?.name==name}.first?.node
        }
        
        if let _ = node(withName: Ball.name) as? Ball,
            let wall = node(withName: Wall.nodeName) {
            
            ballHitWall(wall, contact: contact)
        }
        
        if let _ = node(withName: Ball.name) as? Ball, let hole = node(withName: "bodyPiece")?.parent as? Hole {
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
    
    func ballHitWall(_ wall: SKNode, contact: SKPhysicsContact) {
        defer {
            let params: [String : NSObject] = [
                "hole_number": holeNumber as NSObject,
                "course": course.name as NSObject,
                "speed": ball.physics.body.velocity.magnitude as NSObject,
                kFIRParameterValue: ball.physics.body.velocity.magnitude as NSObject,
            ]
            FIRAnalytics.logEvent(withName: "WallHit", parameters: params)
        }
        
        let reflected = reflect(velocity: ballPrePhysicsVelocity,
                                     for: contact,
                                    with: wall.physicsBody!)
        let angle = acos(reflected.normalized • ballPrePhysicsVelocity.normalized)

        // guard for high angles
        guard angle > .pi / 3.0 else {
            
            defer {
                let currentTime = Date().timeIntervalSince1970
                if let lastTime = lastWallCollision?.2 {
                    if currentTime - lastTime < 0.1 {
                        lastWallCollision = (contact, ball.physics.body.velocity, Date().timeIntervalSince1970)
                    } else {
                        lastWallCollision = nil
                    }
                } else {
                    lastWallCollision = (contact, ball.physics.body.velocity, Date().timeIntervalSince1970)
                }
            }
            
            if let (lastContact, lastVelocity, _) = lastWallCollision {
                if acos(lastContact.contactNormal • contact.contactNormal) < .pi / 4,
                    acos(ball.physics.body.velocity.normalized • lastVelocity.normalized) < .pi / 4 {
                    return
                }
            }
                
            if UserSettings.current.isEffectsEnabled {
                let sound = AudioPlayer()
                sound.play("softWall", ofType: "m4a") { [weak self] in
                    if let index = self?.audio.temporaryPlayers.index(of: sound) {
                        self?.audio.temporaryPlayers.remove(at: index)
                    }
                }
                sound.volume = (Float(angle) / (.pi / 3.0))
                self.audio.temporaryPlayers.append(sound)
            }
            return
        }

        if UserSettings.current.isEffectsEnabled {
            let sound = AudioPlayer()
            sound.play("softWall", ofType: "m4a") { [weak self] in
                if let index = self?.audio.temporaryPlayers.index(of: sound) {
                    self?.audio.temporaryPlayers.remove(at: index)
                }
            }
            sound.volume = Float(ball.physics.body.velocity.magnitude / 50.0)
            audio.temporaryPlayers.append(sound)
        }
        
        reflectionVelocity = reflected
    
        ball.physics.body.applyImpulse(contact.contactNormal * 5)
    }
    
    func ballHitHole(_ hole: Hole, contact: SKPhysicsContact) {
        guard !holeComplete else { return }
        // if hole isn't already completed
        // collision can occur several times during animation
        
        if let drop = SKAction(named: "Drop") {
            let stopTrail = SKAction.run(ball.disableTrail)
            let group = SKAction.group([drop, stopTrail])
            
            entityManager.remove(entity: shotIndicator)
            
            if UserSettings.current.isEffectsEnabled {
                let sound = AudioPlayer()
                sound.play("ballInHole", ofType: "m4a") { [weak self] in
                    if let index = self?.audio.temporaryPlayers.index(of: sound) {
                        self?.audio.temporaryPlayers.remove(at: index)
                    }
                }
                audio.temporaryPlayers.append(sound)
            }
            
            ball.visual.node.run(group)

            let gravity = hole.childNode(withName: "gravity") as? SKFieldNode
            gravity?.strength = 100
            game.finish()
            
            let distanceToHole = (hole.size.width / 2) - 1
            
            let range = SKRange(upperLimit: distanceToHole)
            let limit = SKConstraint.distance(range, to: hole)
            
            ball.visual.node.constraints = ball.visual.node.constraints ?? []
            ball.visual.node.constraints?.append(limit)

            if let view = self.view {
                let recognizers: [UIGestureRecognizer] = [gestureManager.pan, gestureManager.zoom]
                gestureManager.remove(recognizers: recognizers, from: view)
            }
            
            let params: [String : NSObject] = [
                "hole_number": self.holeNumber as NSObject,
                "course": self.course.name as NSObject,
                kFIRParameterValue: self.shots.count as NSObject,
                
                "duration": Date().timeIntervalSince1970 - self.startTime.timeIntervalSince1970 as NSObject
            ]
            FIRAnalytics.logEvent(withName: "HoleFinish", parameters: params)

            if let holeParent = hole.parent {
                let pulse = SKSpriteNode(imageNamed: "holeBurst")
                pulse.size = CGSize(width: hole.size.width*(0.9), height: hole.size.height*(0.9))
                pulse.position = convert(hole.position, from: holeParent)
                addChild(pulse)
                
                let duration: TimeInterval = 1
                let scale = SKAction.scale(to: CGSize(width: 80, height: 80), duration: duration)
                let fadeOut = SKAction.fadeOut(withDuration: duration)
                let remove = SKAction.removeFromParent()
                
                let group = SKAction.group([fadeOut, scale])
                
                let sequence = SKAction.sequence([group, remove])
                pulse.run(sequence)
            }
        }
        
        holeComplete = true
    }
    
    func ballHitPortal(_ portal: Portal, contact: SKPhysicsContact) {
        guard !teleporting else { teleporting = false; return }
        
        if let destination = portal.parent?.parent?.parent?.userData?["destination"] as? String {
            
            enumerateChildNodes(withName: "//portal") { node, stop in
                let userData = node.parent?.parent?.parent?.userData
                if userData?["name"] as? String == destination {
                    let move = SKAction.move(to: node.parent!.convert(node.position, to: self.ball.visual.parent!), duration: 0)
                    
                    
                    if let isVelocityFlipped = userData?["velocityFlipped"] as? Bool, isVelocityFlipped {
                        
                        let dx = self.ball.physics.body.velocity.dx
                        let dy = self.ball.physics.body.velocity.dy
                        self.ball.physics.body.velocity.dx = dy
                        self.ball.physics.body.velocity.dy = dx
                    }
                    
                    let velocityXMultipler = userData?["velocityXMultiplier"] as? CGFloat ?? 1
                    let velocityYMultipler = userData?["velocityYMultiplier"] as? CGFloat ?? 1
                    
                    self.ball.physics.body.velocity.dx *= velocityXMultipler
                    self.ball.physics.body.velocity.dy *= velocityYMultipler
                    self.ball.visual.node.run(move)
                    
                    let sound = SKAction.playSoundFileNamed("portalTransfer.mp3", waitForCompletion: false)
                    self.run(sound)
                    
                    self.teleporting = true
                }
            }
        }
    }
    
    func preScorecardTearDown() {
        enumerateChildNodes(withName: "//portalEmitter") { node, stop in
            (node as? SKEmitterNode)?.particleBirthRate = 0
        }
    }
    
    func postScorecardTearDown() {
        audio.backgroundMusic = nil
    }
    
    func showScorecard(hole: Int, names: (String, String), player1Strokes: [Int], player2Strokes: [Int], pars: [Int], donePressed: @escaping ()->Void) {
        
        let scorecard = SKScene(fileNamed: "Scorecard")! as! Scorecard
        self.scorecard = scorecard
        scorecard.update(hole: hole, names: names, player1Strokes: player1Strokes, player2Strokes: player2Strokes, course: course)
        scorecard.donePressed = donePressed
        
        scorecard.zPosition = 100
        
        let duration: TimeInterval = 0.8
        scorecard.children.forEach {
            let scale = camera!.xScale
            $0.setScale($0.xScale * scale)
            
            let x = ($0.position.x * scale) + camera!.position.x
            let y = ($0.position.y * scale) + camera!.position.y
            let destination: CGPoint = self.convert(CGPoint(x: x, y: y), to: scorecard)
            
//            $0.position = CGPoint(x: destination.x-self.size.width*scale, y: destination.y-self.size.height*scale)

            $0.position = CGPoint(x: destination.x-self.size.width*scale, y: destination.y)

            
            let slide = SKAction.move(to: destination, duration: duration)
            slide.timingMode = .easeOut
            
            $0.run(slide)
        }
        
        let delay = SKAction.wait(forDuration: duration)
        let infoDelay = SKAction.wait(forDuration: 0.4)

        let showInfo = SKAction.run(scorecard.showHoleInfo)
        let showToken = SKAction.run(scorecard.showToken)
        
        let tokenSequence = SKAction.sequence([delay, showToken])
        scorecard.run(tokenSequence)
        
        let sequence = SKAction.sequence([delay, infoDelay, showInfo])
        scorecard.infoPanel.run(sequence)
        
        addChild(scorecard)
        
        let touch = UITapGestureRecognizer(target: self, action: #selector(PuttScene.sceneClosePressed(recognizer:)))
        view?.addGestureRecognizer(touch)
        
        if UserSettings.current.isEffectsEnabled {
            let temporary = AudioPlayer()
            temporary.play("scorecard2", ofType: "wav") { [weak self] in
                if let index = self?.audio.temporaryPlayers.index(of: temporary) {
                    self?.audio.temporaryPlayers.remove(at: index)
                }
            }
            audio.temporaryPlayers.append(temporary)
        }
    }
    
    func sceneClosePressed(recognizer: UITapGestureRecognizer) {
        guard let scorecard = scorecard else { return  }
        let viewLocation = recognizer.location(in: recognizer.view!)
        let sceneLocation = convertPoint(fromView: viewLocation)
        
        let location = convert(sceneLocation, to: scorecard)
        
        if scorecard.button.contains(location) {
            let highlight = SKAction.run {
                scorecard.button.texture = SKTexture(imageNamed: "ContinueButtonPressed")
            }
            highlight.duration = 0.2
            let done = SKAction.run(scorecard.donePressed)
            
            let sequence = SKAction.sequence([highlight, done])
            scorecard.run(sequence)
        }
    }
}

func reflect(velocity entrance: CGVector, for contact: SKPhysicsContact, with body: SKPhysicsBody) -> CGVector {
    return reflect(vector: entrance, across: contact.contactNormal, at: contact.contactPoint, offOf: body)
}

func reflect(vector entrance: CGVector, across normal: CGVector, at point: CGPoint, offOf body: SKPhysicsBody) -> CGVector {
    return entrance - (normal * (entrance • normal) * 2)
}
