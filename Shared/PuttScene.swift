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

class PuttScene: SKScene {
    
    lazy var ball: Ball = {
        return self.childNode(withName: "//\(Ball.name)")! as! Ball
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
                    self.hud.backgroundColor = .red
                }
            }
        }
    }
    
    var course: CoursePack.Type!
    var holeNumber: Int!
    
    var backgroundMusic: AudioPlayer?
    var temporaryPlayers: [AudioPlayer] = []

    var touchNode = SKNode()
    
    var hud: HUDView!
    
    lazy var shotIndicator: ShotIndicator = {
        if let matRotation = self.childNode(withName: "//\(Mat.name)")?.parent?.parent?.zRotation {
            let offset = SKRange(constantValue: matRotation - .pi/2)
            return ShotIndicator(orientToward: self.touchNode, withOffset: offset)
        }
        return ShotIndicator(orientToward: self.touchNode, withOffset: SKRange(constantValue: 0))
    }()
    
    var cameraLimiter: CGRect = .zero
    
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
                    
                    if let isMusicOn = newValue as? Bool {
                        if isMusicOn {
                            backgroundMusic?.resume()
                        } else {
                            backgroundMusic?.pause()
                        }
                    }
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
        
        setupAmbience()
        
        mat.removeFromParent()
        
        ball.removeFromParent()
        addChild(ball)
        
        let delay = SKAction.wait(forDuration: 0.9)
        
        let settings = UserDefaults.standard
        let isEffectsOn = settings.value(forKey: Options.effects.rawValue) as? Bool ?? true
        
        if isEffectsOn {
        
            let sound = SKAction.run {
                let audio = AudioPlayer()
                audio.play("ballDrop") {
                    if let index = self.temporaryPlayers.index(of: audio) {
                        self.temporaryPlayers.remove(at: index)
                    }
                }
                audio.volume = 0.8
                self.temporaryPlayers.append(audio)
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
        
        
        let size = holeSize()
        cameraLimiter = CGRect(origin: .zero, size: size)
        
        passivelyEnableCameraBounds()
        
        parse(url: url)
        
        let ballPosition = ballLocation(url: url)
        let holePosition = holeLocation(url: url)
        
        camera?.position = holePosition
        
        let pan = SKAction.move(to: ballPosition, duration: 4.0)
        pan.timingMode = .easeOut
        camera?.run(pan)
    
        ball.alpha = 0
        ball.ballTrail.particleAlpha = 0
        shotIndicator.alpha = 0
        hole.alpha = 0
        
        let placement = SKAction.run {
            self.ball.position = self.convert(ballPosition, to: self.ball.parent!)
            self.hole.position = self.convert(holePosition, to: self.hole.parent!)
        }
        let fadeIn = SKAction.run {
            let fade = SKAction.fadeIn(withDuration: 0.5)
            self.ball.run(fade)
            self.hole.run(fade)
            
            self.ball.ballTrail.particleAlpha = 1
            self.shotIndicator.run(fade)
        }
        let wait = SKAction.wait(forDuration: 2)
        run(SKAction.sequence([wait, placement, fadeIn]))
    }
    
    var url: URL {
        let coursePrefix = course.name.lowercased()
        return Bundle(for: PuttScene.self).url(forResource: "\(coursePrefix)Hole\(holeNumber!)-\(holeNumber!)", withExtension: "svg")!
    }
    
    func parse(url: URL) {
        
        let paths: [SVGBezierPath] = beziers(url: url).map {
            SVGBezierPath.paths(fromSVGString: $0).first! as! SVGBezierPath
        }
        
        for path in paths {
            let layer = CAShapeLayer()
            layer.path = path.cgPath
            
            let size = holeSize()
            
            let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: -size.width/2, y: -size.height/2)
            
            let pathCopy = CGMutablePath()
            pathCopy.addPath(path.cgPath, transform: transform)
            
            layer.lineWidth = 2
            layer.strokeColor = path.svgAttributes["stroke"] as! CGColor?
            layer.fillColor = path.svgAttributes["fill"] as! CGColor?
            
            let physics = SKNode()
            physics.name = "wall"
            physics.position = CGPoint(x: 0, y: 0)
            physics.physicsBody = SKPhysicsBody(edgeLoopFrom: pathCopy)
            physics.physicsBody?.isDynamic = false
            physics.physicsBody?.collisionBitMask = Category.ball.rawValue
            addChild(physics)
        }
        
        let coursePrefix = course.name.lowercased()

        let texture = SKTexture(imageNamed: "\(coursePrefix)Hole\(holeNumber!)")
        let sprite = SKSpriteNode(texture: texture)
        sprite.zPosition = -1
        sprite.position = CGPoint(x: 0, y: 0)
        addChild(sprite)
    }
    
    func holeLocation(url: URL) -> CGPoint {
        let data = try! Data(contentsOf: url)
        let xml = SWXMLHash.parse(data)
       
        let hole = all(indexer: xml).filter {
            var id = ""
            do {
                id = try $0.value(ofAttribute: "id") as String
            } catch { }
            
            return id.contains("end")
        }[0]
        let x = CGFloat((try! hole.value(ofAttribute: "x") as String).double!)
        let y = CGFloat((try! hole.value(ofAttribute: "y") as String).double!)
        
        let size = holeSize()

        return CGPoint(x: x-size.width/2, y: -(y-size.height/2))
    }
    
    func ballLocation(url: URL) -> CGPoint {
        let data = try! Data(contentsOf: url)
        let xml = SWXMLHash.parse(data)
        
        
        let ball = all(indexer: xml).filter {
            var id = ""
            do {
                id = try $0.value(ofAttribute: "id") as String
            } catch { }
            
            return id.contains("ball")
        }[0]
        
        let x = CGFloat((try! ball.value(ofAttribute: "x") as String).double!)
        let y = CGFloat((try! ball.value(ofAttribute: "y") as String).double!)
        
        let size = holeSize()
        
        return CGPoint(x: x-size.width/2, y: -(y-size.height/2))
    }
    
    func holeSize() -> CGSize {
        
        
        let data = try! Data(contentsOf: url)
        let xml = SWXMLHash.parse(data)
        
        let svg: XMLIndexer = xml["svg"]
        
        let width = try! (svg.value(ofAttribute: "width") as String).int!
        let height = try! (svg.value(ofAttribute: "height") as String).int!
        
        return CGSize(width: width, height: height)
    }
    
    func all(indexer: XMLIndexer, withName name: String? = nil) -> [XMLIndexer] {
        var indexers: [XMLIndexer] = indexer.children
        
        for child in indexer.children {
            indexers.append(contentsOf: all(indexer: child, withName: name))
        }
        
        if let name = name {
            return indexers.filter {
                ($0.element?.name == name) == true
            }
        }
        return indexers
    }
    
    func beziers(url: URL) -> [String] {
        let data = try! Data(contentsOf: url)
        let xml = SWXMLHash.parse(data)
    
        let allPaths = all(indexer: xml, withName: "path")
        
        let strings: [String] = allPaths.map {
            $0.element!.description
        }
        
        var corrected: [String] = strings.map {
            guard let startRange = $0.range(of: "stroke=") else { return $0 }
            
            let start = $0.index(before: startRange.lowerBound)
            
            guard let end = $0.range(of: ")\"", options: .caseInsensitive, range: start..<$0.endIndex, locale: nil) else { return $0 }
            
            return $0.replacingCharacters(in: start..<end.upperBound, with: "")
        }
            
        corrected = corrected.map {
            guard let startRange = $0.range(of: "fill=") else { return $0 }
            
            let start = $0.index(before: startRange.lowerBound)
            
            guard let end = $0.range(of: ")\"", options: .caseInsensitive, range: start..<$0.endIndex, locale: nil) else { return $0 }
            
            return $0.replacingCharacters(in: start..<end.upperBound, with: "")
        }
        
        return corrected
    }
    
    func renderImage(from layer: CALayer) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(layer.bounds.size, false, 0)
        
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        return image
    }
    
    func updateShotIndicatorPosition() {
        if let shotIndicatorParent = shotIndicator.parent, let ballParent = ball.parent {
            shotIndicator.position = ballParent.convert(ball.position, to: shotIndicatorParent)
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
        listener = ball
    }
    
    func setupCamera() {
        camera?.zPosition = -10
    }
    
    func setupAmbience() {
       HoleSetup.setup(self, forHole: holeNumber, inCourse: course)
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
        
        if (0.6...1.3).contains(recognizer.scale) {
            
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

//            // reapplies ball tracking constraint, needs to scale with scene
//            if isBallTrackingEnabled {
//                if let constraint = ballTracking, let index = camera.constraints?.index(of: constraint) {
//                    camera.constraints?.remove(at: index)
//                }
//                
//                let range = SKRange(value: 0, variance: ballFreedomRadius)
//                ballTracking = SKConstraint.distance(range, to: ball)
//                camera.constraints?.insert(ballTracking!, at: 0)
//            }
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
                            
                            shotIndicator.showAngle()
                        }
                    }
                }
            }
        }
    }
    
    func cancelShot(recognizer: UITapGestureRecognizer) {
        adjustingShot = false
        
        let ballPosition = hole.parent!.convert(ball.position, from: ball.parent!)
        if ballPosition.distance(toPoint: hole.position) <= 150 {
            flag.lower()
        }
        
        shotIndicator.shotCancelled()
        
        view?.removeGestureRecognizer(recognizer)
    }
    
    func beginShot() {
        let ballPosition = hole.parent!.convert(ball.position, from: ball.parent!)
        if ballPosition.distance(toPoint: hole.position) <= 150 {
            flag.raise()
        }
        
        let settings = UserDefaults.standard
        let isEffectsOn = settings.value(forKey: Options.effects.rawValue) as? Bool ?? true
        
        if isEffectsOn {
            let selection = SKAction.playSoundFileNamed("ballSelect.mp3", waitForCompletion: false)
            ball.run(selection)
        }
        
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
        
        let cancel = UITapGestureRecognizer(target: self, action: #selector(PuttScene.cancelShot(recognizer:)))
        view?.addGestureRecognizer(cancel)
        
        // if no ball tracking, move camera toward ball
        if !isBallTrackingEnabled {
            let ballPosition = convert(ball.position, from: ball.parent!)
            
            if ballPosition.distance(toPoint: camera!.position) > ballFreedomRadius {
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
            touchNode.position = touch.location(in: ball)
            
            let ballLocation = convert(ball.position, from: ball.parent!)
            shotIndicator.power = touchLocation.distance(toPoint: ballLocation) * camera!.xScale / 250.0
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            
            guard adjustingShot else { return }

            let ballPosition = ball.parent!.convert(ball.position, to: self)
            
            let shotThreshold = shotIndicator.ballIndicator.size.width / 2
            
            guard ballPosition.distance(toPoint: touchLocation) > shotThreshold else {
                adjustingShot = false
                return
            }
            
            let angle = ballPosition.angle(toPoint: touchLocation)
            
            adjustingShot = false
            takeShot(at: angle, with: shotIndicator.power * 600)
            
            shotIndicator.shotTaken()
        }
    }
   
    func takeShot(at angle: CGFloat, with power: CGFloat) {
        print("\(angle) - \(power)")
        
        let stroke = CGVector(dx: cos(angle) * power,
                              dy: sin(angle) * power)
        
        let settings = UserDefaults.standard
        let isEffectsOn = settings.value(forKey: Options.effects.rawValue) as? Bool ?? true
        
        if isEffectsOn {
            let sound = SKAudioNode(fileNamed: "clubHit.wav")
            sound.autoplayLooped = false
            sound.position = convert(ball.position, from: ball.parent!)
            
            // scale volume with shot power
            let setVolume = SKAction.changeVolume(to: Float(power / 100.0), duration: 0)
            
            let remove = SKAction.sequence([
                SKAction.wait(forDuration: 1),
                SKAction.removeFromParent(),
                ])
            sound.run(SKAction.group([setVolume, SKAction.play(), remove]))

            addChild(sound)
        }
        
        ball.physicsBody?.applyImpulse(stroke)
        
        let shot = Shot(power: power,
                        angle: angle,
                     position: convert(ball.position, from: ball.parent!))
        // shot data tracked for sending
        shots.append(shot)
    }
    
    // MARK: Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        // grabs ball velocity before physics calculations,
        // used in wall reflection
        ballPrePhysicsVelocity = ball.physicsBody?.velocity ?? .zero
        
        if let body = ball.physicsBody, body.velocity.magnitude < 5.0 {
            
            if let ballTracking = ballTracking, let index = camera?.constraints?.index(of: ballTracking), body.isResting {
                camera?.constraints?.remove(at: index)
                self.ballTracking = nil
            }
            
            if shotIndicator.ballIndicator.alpha != 1.0 {
                updateShotIndicatorPosition()
                shotIndicator.ballStopped()
            }
    
            let ballPosition = hole.parent!.convert(ball.position, from: ball.parent!)
            if ballPosition.distance(toPoint: hole.position) > 150, !flag.isWiggling {
                flag.lower()
            }
        }
        
        let ballPosition = convert(ball.position, from: ball.parent!)
        let distanceFromCamera = ballPosition.distance(toPoint: camera!.position)
        if adjustingShot, distanceFromCamera <= ballFreedomRadius {
            passivelyEnableBallTracking()
        }
    }
    
    override func didSimulatePhysics() {
        
        
    }
    
    override func didFinishUpdate() {
        // if there is a wall reflection pending, apply it
        if let reflection = reflectionVelocity {
            ball.physicsBody?.velocity = reflection
            reflectionVelocity = nil
        }
        
        if !isCameraBounded {
            passivelyEnableCameraBounds()
        }
    }
    
    func passivelyEnableBallTracking() {
        let ballPosition = convert(ball.position, from: ball.parent!)
        
        // if ball is withing tracking range, start tracking
        guard let _ = camera?.action(forKey: "trackingEnabler"),
            camera!.position.distance(toPoint: ballPosition) <= ballFreedomRadius else {
            return
        }
        let tracking = SKConstraint.distance(SKRange(upperLimit: ballFreedomRadius), to: ball)
        if let _ = camera?.constraints {
            camera?.constraints?.insert(tracking, at: 0)
        } else {
            camera?.constraints = [tracking]
        }
        camera?.removeAction(forKey: "trackingEnabler")
        
        ballTracking = tracking
    }
    
    func passivelyEnableCameraBounds() {
        let cameraSize = CGSize(width: size.width * camera!.xScale,
                               height: size.height * camera!.yScale)
        
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

        cameraXBound = SKConstraint.positionX(xRange)
        cameraYBound = SKConstraint.positionY(yRange)
 
        var constraints = camera?.constraints ?? []
        constraints.append(cameraXBound!)
        constraints.append(cameraYBound!)
        camera?.constraints = constraints
    }
}

// MARK: Contact Delegate

var ballPrePhysicsVelocity: CGVector = .zero

var reflectionVelocity: CGVector? = nil

var lastFrameContact: SKPhysicsBody?

var holeCupConstraint: SKConstraint?

var lockedDistanceToHole: CGFloat = 10000000

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
  
        let normalized = normal.normalized        
        let dot = entrance • normalized
        let directed = CGVector(dx: dot*normalized.dx, dy: dot*normalized.dy)
        let scaled = CGVector(dx: 2*directed.dx, dy: 2*directed.dy)
        return CGVector(dx: entrance.dx-scaled.dx, dy: entrance.dy-scaled.dy)
    }
    
    func ballHitWall(_ wall: SKNode, contact: SKPhysicsContact) {
        let reflected = reflect(velocity: ballPrePhysicsVelocity,
                                 for: contact,
                                 with: wall.physicsBody!)
        let angle = acos(reflected.normalized • ballPrePhysicsVelocity.normalized)

        guard angle > .pi / 3.0 else {
            return
        }

        let settings = UserDefaults.standard
        let isEffectsOn = settings.value(forKey: Options.effects.rawValue) as? Bool ?? true
    
        if isEffectsOn {
            let sound = AudioPlayer()
            sound.play("softWall") {
                if let index = self.temporaryPlayers.index(of: sound) {
                    self.temporaryPlayers.remove(at: index)
                }
            }
            sound.volume = Float(ball.physicsBody!.velocity.magnitude / 50.0)
            temporaryPlayers.append(sound)
        }
        
        reflectionVelocity = reflected * 0.7
    }
    
    func ballHitHole(_ hole: Hole, contact: SKPhysicsContact) {
        
        guard !holeComplete else { return }
        // if hole isn't already completed
        // collision can occur several times during animation
        
        if let drop = SKAction(named: "Drop") {
            let holePosition = hole.parent!.convert(hole.position, to: ball.parent!)
            
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
                return hole.parent!.convert(self.ball.position, from: self.ball.parent!)
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
                    
                    self.ball.removeAction(forKey: ballInHoleKey)
                    let settings = UserDefaults.standard
                    let isEffectsOn = settings.value(forKey: Options.effects.rawValue) as? Bool ?? true
                
                    if isEffectsOn {
                        let sound = AudioPlayer()
                        sound.play("ballMade") {
                            if let index = self.temporaryPlayers.index(of: sound) {
                                self.temporaryPlayers.remove(at: index)
                            }
                        }
                        self.temporaryPlayers.append(sound)
                    }
                    
                    self.ball.run(group)

                    self.game.finish()
                    return
                }
                
                if let joint = holeCupConstraint, let index = self.ball.constraints?.index(of: joint) {
                    self.ball.constraints?.remove(at: index)
                }
                
                lockedDistanceToHole -= 2
                lockedDistanceToHole = lockedDistanceToHole < distance ? lockedDistanceToHole : distance
                
                let range = SKRange(upperLimit: lockedDistanceToHole)
                let joint = SKConstraint.distance(range, to: hole)
                holeCupConstraint = joint
                
                self.ball.constraints = self.ball.constraints ?? []
                self.ball.constraints?.append(joint)
            }
            
            let sequence = SKAction.sequence([delay, move])
            ball.run(SKAction.repeatForever(sequence), withKey: ballInHoleKey)
            
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
                    let move = SKAction.move(to: node.parent!.convert(node.position, to: self.ball.parent!), duration: 0)
                    
                    
                    if let isVelocityFlipped = userData?["velocityFlipped"] as? Bool, isVelocityFlipped {
                        
                        let dx = self.ball.physicsBody!.velocity.dx
                        let dy = self.ball.physicsBody!.velocity.dy
                        self.ball.physicsBody?.velocity.dx = dy
                        self.ball.physicsBody?.velocity.dy = dx
                    }
                    
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
    
    func preScorecardTearDown() {
        enumerateChildNodes(withName: "//portalEmitter") { node, stop in
            guard let portal = node as? SKEmitterNode else { return }
            
            portal.particleBirthRate = 0
        }
    }
    
    func postScorecardTearDown() {
        backgroundMusic?.pause()
    }
    
    func showScorecard(hole: Int, names: (String, String), player1Strokes: [Int], player2Strokes: [Int], pars: [Int], donePressed: @escaping ()->Void) {
        
        let scorecard = SKScene(fileNamed: "Scorecard")! as! Scorecard
        self.scorecard = scorecard
        scorecard.update(hole: hole, names: names, player1Strokes: player1Strokes, player2Strokes: player2Strokes, course: course)
        scorecard.donePressed = donePressed
        
        let duration: TimeInterval = 0.8
        scorecard.children.filter{$0 != scorecard.token}.forEach {
            let scale = camera!.xScale
            $0.setScale($0.xScale * scale)
            
            let x = ($0.position.x * scale) + camera!.position.x
            let y = ($0.position.y * scale) + camera!.position.y
            let destination: CGPoint = self.convert(CGPoint(x: x, y: y), to: scorecard)
            
            $0.position = CGPoint(x: destination.x-self.size.width*scale, y: destination.y-self.size.height*scale)
    
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
            temporary.play("scoreCard") {
                if let index = self.temporaryPlayers.index(of: temporary) {
                    self.temporaryPlayers.remove(at: index)
                }
            }
            temporaryPlayers.append(temporary)
        }
    }
    
    func sceneClosePressed(recognizer: UITapGestureRecognizer) {
        guard let scorecard = scorecard else { return  }
        let viewLocation = recognizer.location(in: recognizer.view!)
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
