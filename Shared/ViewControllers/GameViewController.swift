//
//  GameViewController.swift
//  testGolf
//
//  Created by Kenny Testa Jr on 12/15/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import AVFoundation
import QuartzCore
import SpriteKit
import UIKit

import JWSwiftTools

class GameViewController: UIViewController {

    var sceneView: SKView {
        return view as! SKView
    }
    
    var opponentSession: PuttSession?
    
    var scene: PuttScene!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sceneName = "Hole9"
        scene = PuttScene(fileNamed: sceneName)!
        configureScene(previousSession: nil)
        sceneView.presentScene(scene)
    }
    
    func configureScene(previousSession: PuttSession?) {
        // setup any visuals with data specific to the previous session; if nil, start fresh
    
        let number = previousSession?.initial.holeNumber ?? 1
        scene = SKScene(fileNamed: "Hole\(number)")! as! PuttScene
        
        let cycle = SessionCycle(started: started, finished: finished, generateSession: generateSession)

        scene.game = Putt(previousSession: previousSession, initial: previousSession?.initial, padding: nil, cycle: cycle)
        
        HoleSetup.setup(scene, forHole: number, inCourse: Frost.self)
    }
    
    // MARK: Game Cycle
    
    func started() {
        
    }
    
    func finished(session: PuttSession) {
        
    }
    
    func generateSession() -> PuttSession {
        let instance = PuttInstanceData(shots: [], opponentShots: nil, winner: nil)
        let initial = PuttInitialData(course: Frost.self as CoursePack.Type, holeNumber: 1, holeSet: [])
        return PuttSession(instance: instance, initial: initial, ended: false, messageSession: opponentSession?.messageSession)
    }

}
