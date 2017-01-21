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

private var settingsContext = 0

public extension SKRange {
    public var openInterval: Range<CGFloat> {
        return lowerLimit..<upperLimit
    }
    
    public var closedInterval: ClosedRange<CGFloat> {
        return lowerLimit...upperLimit
    }
}

func renderImage(from layer: CALayer) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(layer.bounds.size, false, 0)
    
    layer.render(in: UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    
    UIGraphicsEndImageContext()
    return image
}

func reflect(velocity entrance: CGVector, for contact: SKPhysicsContact, with body: SKPhysicsBody) -> CGVector {
    return reflect(vector: entrance, across: contact.contactNormal, at: contact.contactPoint, offOf: body)
}

func reflect(vector entrance: CGVector, across normal: CGVector, at point: CGPoint, offOf body: SKPhysicsBody) -> CGVector {
    
    let normalized = normal.normalized
    let dot = entrance • normalized
    let directed = CGVector(dx: dot*normalized.dx, dy: dot*normalized.dy)
    let scaled = CGVector(dx: 2*directed.dx, dy: 2*directed.dy)
    return CGVector(dx: entrance.dx-scaled.dx, dy: entrance.dy-scaled.dy)
}

class PuttScene: SKScene {
    
    var entities: [GKEntity] = []
    
    var startTime: Date!
    
    lazy var ball: BallEntity = {
        let node = self.childNode(withName: "//\(Ball.name)")! as! Ball
        return BallEntity(node: node, physics: node.physicsBody!)
    }()
    
    lazy var mat: Mat = {
        return self.childNode(withName: "//\(Mat.name)")! as! Mat
    }()
    
    lazy var hole: Hole = {
        return self.childNode(withName: "//\(Hole.name)")! as! Hole
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
            
            let par = HoleInfo.par(forHole: holeNumber, in: course)
            if shots.count > par {
                UIView.animate(withDuration: 0.5) {
                    self.hud.strokeLabel.textColor = .red
                }
            }
        }
    }
    
    var course: CoursePack.Type!
    var holeNumber: Int!
    
    let audio = AudioManager()
    
    lazy var gestureManager: GestureManager = {
        return GestureManager(delegate: self as UIGestureRecognizerDelegate)
    }()
    
    var touchNode = SKNode()
    
    var hud: HUDView!
    
    lazy var shotIndicator: ShotIndicator = {
        if let matRotation = self.childNode(withName: "//\(Mat.name)")?.parent?.parent?.zRotation {
            let offset = SKRange(constantValue: matRotation + .pi/2)
            return ShotIndicator(orientToward: self.touchNode, withOffset: offset)
        }
        return ShotIndicator(orientToward: self.touchNode, withOffset: SKRange(constantValue: 0))
    }()
    
    var limiter: CameraLimiter!
    
    var scorecard: Scorecard?
    
    // MARK: Scene Lifecycle

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &settingsContext {
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

    override func didMove(to view: SKView) {
        let params: [String : NSObject] = [
            "course": course.name as NSObject,
            "hole": course.holeCount as NSObject,
        ]
        FIRAnalytics.logEvent(withName: "RoundStart", parameters: params)
        
        setDebugOptions(on: view)
    
        scaleMode = .resizeFill
        
        removeGrid()
        
        addGestureRecognizers(in: view)
        
        setupPhysics()
        
        setupCamera()
    
        ball.updateTrailEmitter()
        
        addSettingsListener(forKey: "Music")
        
        addChild(shotIndicator)
        
        setupAmbience()
        
        mat.removeFromParent()
        
        startTime = Date()
        lastShotTime = Date()
        
        ball.visual.node.removeFromParent()
        add(entity: ball)
        
        let holeData = HoleData(holeNumber: holeNumber, course: course)
        let size = holeData.size
        let cameraBox = CGRect(x: 0, y: 0, width: size.width + 100, height: size.height + 100)
        limiter = CameraLimiter(camera: camera!, boundingBox: cameraBox, freedomRadius: {
            return self.size.width * self.camera!.xScale * 0.4
        })
        
        let delay = SKAction.wait(forDuration: 0.9)
        
        let settings = UserDefaults.standard
        let isEffectsOn = settings.value(forKey: Options.effects.rawValue) as? Bool ?? true
        
        if isEffectsOn {
        
            let sound = SKAction.run {
                let audio = AudioPlayer()
                audio.play("ballDrop", ofType: "m4a") {
                    if let index = self.audio.temporaryPlayers.index(of: audio) {
                        self.audio.temporaryPlayers.remove(at: index)
                    }
                }
                audio.volume = 0.8
                self.audio.temporaryPlayers.append(audio)
            }
            run(SKAction.sequence([delay, sound]))
        }
        
        if let ballDrop = SKAction(named: "BallDrop") {
            run(SKAction.sequence([delay, ballDrop]))
        }
        
        shotIndicator.shotTaken()

        let beginShot = SKAction.run {
            self.shotIndicator.ballStopped()
        }
        run(SKAction.sequence([delay, beginShot]))
        
        flag.wiggle()
        
        passivelyEnableCameraBounds()
        
        holeData.parse(scene: self)
        
        let ballPosition = holeData.ballLocation
        let holePosition = holeData.holeLocation
        
        camera?.position = holePosition
        
        let pan = SKAction.move(to: ballPosition, duration: 4.0)
        pan.timingMode = .easeOut
        camera?.run(pan)
    
        ball.visual.node.alpha = 0
        ball.ballTrail!.particleAlpha = 0
        shotIndicator.alpha = 0
        hole.alpha = 0
        
        let placement = SKAction.run {
            self.shotIndicator.position = ballPosition
            self.ball.visual.position = self.convert(ballPosition, to: self.ball.visual.parent!)
            self.hole.position = self.convert(holePosition, to: self.hole.parent!)
        }
        let fadeIn = SKAction.run {
            let fade = SKAction.fadeIn(withDuration: 0.5)
            self.ball.visual.node.run(fade)
            self.hole.run(fade)
            
            self.ball.ballTrail!.particleAlpha = 1
            self.shotIndicator.run(fade)
        }
        let wait = SKAction.wait(forDuration: 2)
        run(SKAction.sequence([wait, placement, fadeIn]))
    }
    
    func add(entity: GKEntity) {
        entities.append(entity)
        if let visual = entity.component(ofType: RenderComponent.self) {
            addChild(visual.node)
        }
    }
    
    func updateShotIndicatorPosition() {
        if let shotIndicatorParent = shotIndicator.parent, let ballParent = ball.visual.parent {
            shotIndicator.position = ballParent.convert(ball.visual.position, to: shotIndicatorParent)
        }
    }
    
    func addSettingsListener(forKey key: String) {
        UserDefaults.standard.addObserver(self, forKeyPath: key, options: .new, context: &settingsContext)
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
        
        // positional audio target
        listener = ball.visual.node
    }
    
    func setupCamera() {
        camera?.zPosition = -10
        
        let background = SKSpriteNode(imageNamed: course.name.lowercased()+"Background")
        background.name = "background"
        background.size = CGSize(width: 800, height: 1600)
        camera?.addChild(background)
    }
    
    func setupAmbience() {
       HoleSetup.setup(self, forHole: holeNumber, inCourse: course)
    }
    
    func addGestureRecognizers(in view: SKView) {
        gestureManager.addRecognizers(to: view)
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
            
            let existing = camera.xScale
//            camera.childNode(withName: "background")?.setScale(1 / existing / 0.8)
            
            camera.childNode(withName: "background")?.setScale(1 / existing / 0.8)
//            let scale = SKAction.scale(to: 1 / existing / 0.8, duration: 0.1)
//            camera.childNode(withName: "background")?.run(scale)
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

    // MARK: Animations

    // MARK: Touch Handling

    var adjustingShot = false
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.count == 1 else { return }
        
        for touch in touches {
            
            let location = touch.location(in: ball.visual.parent!)
            
            if !adjustingShot {
                if location.distance(toPoint: ball.visual.position) <= 100 {
                    if ball.physics.body.velocity.magnitude < 5.0 {
                        beginShot()
                        
                        shotIndicator.showAngle()
                    }
                }
            }
        }
    }
    
    func cancelShot(recognizer: UITapGestureRecognizer) {
        adjustingShot = false
        
        let ballPosition = ball.visual.position(in: hole.parent!)!
        if ballPosition.distance(toPoint: hole.position) <= 150 {
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
    
    func beginShot() {
        let ballPosition = hole.parent!.convert(ball.visual.position, from: ball.visual.parent!)
        
        let distanceToHole = ballPosition.distance(toPoint: hole.position)
        if distanceToHole <= 150 {
            flag.raise()
            
            let params = [
                "hole_number": holeNumber as NSObject,
                "course": course.name as NSObject,
                kFIRParameterValue: distanceToHole as NSObject,
            ]
            FIRAnalytics.logEvent(withName: "ShotNearHole", parameters: params)
        }
        
        let settings = UserDefaults.standard
        let isEffectsOn = settings.value(forKey: Options.effects.rawValue) as? Bool ?? true
        
        if isEffectsOn {
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
        
        shotIndicator.position = convert(ball.visual.position, from: ball.visual.parent!)
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

            let ballPosition = ball.visual.position(in: self)!
            
            let shotThreshold = shotIndicator.ballIndicator.size.width / 2
            
            guard ballPosition.distance(toPoint: touchLocation) > shotThreshold else {
                adjustingShot = false
                return
            }
            
            let angle = ballPosition.angle(toPoint: touchLocation) + .pi
            
            adjustingShot = false
            takeShot(at: angle, with: shotIndicator.power * 600)
            
            shotIndicator.shotTaken()
        }
    }
    
    var lastShotTime: Date!
   
    func takeShot(at angle: CGFloat, with power: CGFloat) {
        let shot = Shot(power: power,
                        angle: angle,
                     position: ball.visual.position(in: self)!)
        // shot data tracked for sending
        shots.append(shot)

        ball.physics.body.applyImpulse(shot.stroke)
        
        let settings = UserDefaults.standard
        let isEffectsOn = settings.value(forKey: Options.effects.rawValue) as? Bool ?? true
        
        if isEffectsOn {
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
        
        if body.velocity.magnitude < 5.0 {
            
            if let ballTracking = limiter.ballTracking, let index = camera?.constraints?.index(of: ballTracking), body.isResting {
                camera?.constraints?.remove(at: index)
                self.limiter.ballTracking = nil
            }
            
            if shotIndicator.ballIndicator.alpha != 1.0 {
                updateShotIndicatorPosition()
                shotIndicator.ballStopped()
            }
            
            let ballPosition = ball.visual.position(in: hole.parent!)!
            if ballPosition.distance(toPoint: hole.position) > 150, !flag.isWiggling {
                flag.lower()
            }
        }
        
        let ballPosition = ball.visual.position(in: self)!
        let distanceFromCamera = ballPosition.distance(toPoint: camera!.position)
        if adjustingShot, distanceFromCamera <= limiter.freedomRadius {
            passivelyEnableBallTracking()
        }
    }
    
    override func didFinishUpdate() {
        // if there is a wall reflection pending, apply it
        if let reflection = reflectionVelocity {
//            ball.physicsBody?.velocity = reflection
            ball.physics.body.applyImpulse(reflection/3)
            reflectionVelocity = nil
        }
        
        if !limiter.isActive {
            passivelyEnableCameraBounds()
        }
    }
    
    override func didSimulatePhysics() {
        ball.ballTrail?.particleAlpha = 0.1 + (ball.physics.body.velocity.magnitude / 80.0) * 0.2
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

// MARK: Contact Delegate

var ballPrePhysicsVelocity: CGVector = .zero

var reflectionVelocity: CGVector? = nil

var holeCupConstraint: SKConstraint?

var lockedDistanceToHole: CGFloat = 10000000

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

        guard angle > .pi / 3.0 else {
            
//            let settings = UserDefaults.standard
//            let isEffectsOn = settings.value(forKey: Options.effects.rawValue) as? Bool ?? true
//            
//            if isEffectsOn {
//                var shouldPlaySound = true
//                
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
                
//                if shouldPlaySound {
                    let sound = AudioPlayer()
                    sound.play("softWall", ofType: "m4a") {
                        if let index = self.audio.temporaryPlayers.index(of: sound) {
                            self.audio.temporaryPlayers.remove(at: index)
                        }
                    }
                    sound.volume = (Float(angle) / (.pi / 3.0))
                    self.audio.temporaryPlayers.append(sound)
//                }
//            }
            return
        }

        let settings = UserDefaults.standard
        let isEffectsOn = settings.value(forKey: Options.effects.rawValue) as? Bool ?? true
    
        if isEffectsOn {
            var shouldPlaySound = true
            
            if shouldPlaySound {
                let sound = AudioPlayer()
                sound.play("softWall", ofType: "m4a") {
                    if let index = self.audio.temporaryPlayers.index(of: sound) {
                        self.audio.temporaryPlayers.remove(at: index)
                    }
                }
                sound.volume = Float(ball.physics.body.velocity.magnitude / 50.0)
                audio.temporaryPlayers.append(sound)
            }
        }
        
        reflectionVelocity = reflected
        
//        reflectionVelocity = reflected * 0.7
        
        ball.physics.body.applyImpulse(contact.contactNormal * 5)
    }
    
    func ballHitHole(_ hole: Hole, contact: SKPhysicsContact) {
        guard !holeComplete else { return }
        // if hole isn't already completed
        // collision can occur several times during animation
        
        if let drop = SKAction(named: "Drop") {
            let holePosition = hole.parent!.convert(hole.position, to: ball.visual.parent!)
            
            let insideHole = SKAction.move(to: holePosition, duration: drop.duration/3)
            insideHole.timingMode = .easeOut
            let stopTrail = SKAction.run {
                self.ball.disableTrail()
            }
            let group = SKAction.group([drop, insideHole, stopTrail])

            // stop ball's existing motion
//            ball.physicsBody?.velocity = .zero
            
//            ball.run(group)
            
//            game.finish()
            
            shotIndicator.removeFromParent()
            
            let ballInHoleKey = "spiral"
            
            var ballPosition: CGPoint {
                return hole.parent!.convert(self.ball.visual.position, from: self.ball.visual.parent!)
            }
            
            var distance: CGFloat {
                return ballPosition.distance(toPoint: hole.position)
            }
            
            lockedDistanceToHole = distance
            
            let delay = SKAction.wait(forDuration: 0.05)
            let move = SKAction.run {
//                let ballPosition = hole.parent!.convert(self.ball.position, from: self.ball.parent!)
//
//                let distance = ballPosition.distance(toPoint: hole.position)-1
                guard lockedDistanceToHole > 1 && !self.holeComplete else {
                    self.holeComplete = true
                    
                    self.ball.visual.node.removeAction(forKey: ballInHoleKey)
                    let settings = UserDefaults.standard
                    let isEffectsOn = settings.value(forKey: Options.effects.rawValue) as? Bool ?? true
                
                    if isEffectsOn {
                        let sound = AudioPlayer()
                        sound.play("ballMade") {
                            if let index = self.audio.temporaryPlayers.index(of: sound) {
                                self.audio.temporaryPlayers.remove(at: index)
                            }
                        }
                        self.audio.temporaryPlayers.append(sound)
                    }
                    
                    self.ball.visual.node.run(group)

                    self.game.finish()
                    
                    let manager = self.gestureManager
                    manager.remove(recognizer: manager.pan, from: self.view!)
                    manager.remove(recognizer: manager.zoom, from: self.view!)
                    
                    let params: [String : NSObject] = [
                        "hole_number": self.holeNumber as NSObject,
                        "course": self.course.name as NSObject,
                        kFIRParameterValue: self.shots.count as NSObject,
                        
                        "duration": Date().timeIntervalSince1970 - self.startTime.timeIntervalSince1970 as NSObject
                    ]
                    FIRAnalytics.logEvent(withName: "HoleFinish", parameters: params)
                    return
                }
                
                if let joint = holeCupConstraint, let index = self.ball.visual.node.constraints?.index(of: joint) {
                    self.ball.visual.node.constraints?.remove(at: index)
                }
                
                lockedDistanceToHole -= 2
                lockedDistanceToHole = lockedDistanceToHole < distance ? lockedDistanceToHole : distance
                
                let range = SKRange(upperLimit: lockedDistanceToHole)
                let joint = SKConstraint.distance(range, to: hole)
                holeCupConstraint = joint
                
                var constraints = self.ball.visual.node.constraints ?? []
                constraints.append(joint)
                self.ball.visual.node.constraints = constraints
            }
            
            let sequence = SKAction.sequence([delay, move])
            ball.visual.node.run(SKAction.repeatForever(sequence), withKey: ballInHoleKey)
            
            return
            let par = HoleInfo.par(forHole: holeNumber, in: course)
            
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
            guard let portal = node as? SKEmitterNode else { return }
            
            portal.particleBirthRate = 0
        }
    }
    
    func postScorecardTearDown() {
        audio.backgroundMusic?.pause()
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
        
        
        let settings = UserDefaults.standard
        let isEffectsOn = settings.value(forKey: Options.effects.rawValue) as? Bool ?? true
        
        if isEffectsOn {
            let temporary = AudioPlayer()
            temporary.play("scorecard2", ofType: "wav") {
                if let index = self.audio.temporaryPlayers.index(of: temporary) {
                    self.audio.temporaryPlayers.remove(at: index)
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
}
