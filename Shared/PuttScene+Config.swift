//
//  PuttScene+Config.swift
//  MrPutt
//
//  Created by Developer on 1/22/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import SpriteKit

extension PuttScene {
    func configure(for holeData: HoleData, in view: SKView) {
        setDebugOptions(on: view)

        addSettingsListener(forKey: "Music")
        
        addGestureRecognizers(in: view)
        
        removeGrid()
        setupCamera()
        setupAmbience()
        setupPhysics()
        
        let size = holeData.size
        let cameraBox = CGRect(x: 0, y: 0, width: size.width + 100, height: size.height + 100)
        limiter = CameraLimiter(camera: camera!, boundingBox: cameraBox, freedomRadius: { [unowned self] in
            return self.size.width * self.camera!.xScale * 0.4
        })
        
        startTime = Date()
        lastShotTime = Date()
    }
    
    func removeGrid() {
        childNode(withName: "grid")?.removeFromParent()
    }
    
    func setDebugOptions(on view: SKView) {
        view.showsFPS = false
        view.showsPhysics = false
        view.backgroundColor = .black
    }
    
    func setupAmbience() {
        HoleSetup.setup(self, forHole: holeNumber, inCourse: course)
    }

    func addGestureRecognizers(in view: SKView) {
        gestureManager.addRecognizers(to: view)
    }
    
    func setupPhysics() {
        // sends contact notifications to didBegin(contact:)
        physicsWorld.contactDelegate = self
        
        // positional audio target
        listener = ball.visual.node
    }
    
    // Sets position and initial state for nodes
    func initiate(with holeData: HoleData) {
        add(entity: ball)
        addChild(shotIndicator)
        
        flag.updateFlag(hole: holeNumber)
        
        ball.updateTrailEmitter()

        shotIndicator.shotTaken()
        
        camera?.position = holeData.holeLocation
        
        ball.visual.node.alpha = 0
        ball.ballTrail!.alpha = 0
        ball.ballTrail!.particleAlpha = 0
        shotIndicator.alpha = 0
        hole.alpha = 0
        
        let ballPosition = holeData.ballLocation
        let holePosition = holeData.holeLocation
        
        shotIndicator.position = ballPosition
        ball.visual.position = convert(ballPosition, to: ball.visual.parent!)
        hole.position = convert(holePosition, to: hole.parent!)
    }
    
    func initiateAnimations(with holeData: HoleData) {
        flag.wiggle()

        let beginShot = SKAction.run(shotIndicator.ballStopped)
        
        let delay = SKAction.wait(forDuration: 0.9)
        
        if let ballDrop = SKAction(named: "BallDrop") {
            run(SKAction.sequence([delay, ballDrop]))
        }
        
        run(SKAction.sequence([delay, beginShot]))
        
        
        if UserSettings.current.isEffectsEnabled {
            let sound = SKAction.run {
                let audio = AudioPlayer()
                audio.play("ballDrop", ofType: "m4a") { [weak self] in
                    if let index = self?.audio.temporaryPlayers.index(of: audio) {
                        self?.audio.temporaryPlayers.remove(at: index)
                    }
                }
                audio.volume = 0.8
                self.audio.temporaryPlayers.append(audio)
            }
            run(SKAction.sequence([delay, sound]))
        }
        
        
        let pan = SKAction.move(to: holeData.ballLocation, duration: 4.0)
        pan.timingMode = .easeOut
        camera?.run(pan)
        
        
        let wait = SKAction.wait(forDuration: 2)
        let fadeIn = SKAction.run {
            let fade = SKAction.fadeIn(withDuration: 0.5)
            self.ball.visual.node.run(fade)
            self.hole.run(fade)
            
            self.ball.ballTrail!.alpha = 1
            self.ball.ballTrail!.particleAlpha = 1
            self.shotIndicator.run(fade)
        }
        run(SKAction.sequence([wait, fadeIn]))

    }
}
