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

public extension CGPoint {
    public func angle(toPoint point: CGPoint) -> CGFloat {
        let origin = CGPoint(x: point.x - self.x, y: point.y - self.y)
        let radians = CGFloat(atan2f(Float(origin.y), Float(origin.x)))
        let corrected = radians < 0 ? radians + 2 * .pi : radians
        return corrected
    }
    
    public func distance(toPoint point: CGPoint) -> CGFloat {
        return sqrt( pow(self.x-point.x, 2) + pow(self.y - point.y, 2) )
    }
}

public extension CGVector {
    public var magnitude: CGFloat {
        return sqrt( dx*dx + dy*dy )
    }
}

enum Category: UInt32 {
    case none = 0
    case ball = 1
    case wall = 2
    case hole = 4
}

class GameViewController: UIViewController {

    var sceneView: SKView {
        return view as! SKView
    }
    
    var opponentSession: PuttSession?
    
    var scene: PuttScene!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sceneName = "Hole1"
        scene = PuttScene(fileNamed: sceneName)!
        sceneView.presentScene(scene)
    }
    
    func configureScene(previousSession: PuttSession?) {
        // setup any visuals with data specific to the previous session; if nil, start fresh
    
        let number = previousSession?.initial.holeNumber ?? 1
        scene = SKScene(fileNamed: "Hole\(number)")! as! PuttScene
        
        let cycle = SessionCycle(started: started, finished: finished, generateSession: generateSession)

        scene.game = Putt(previousSession: previousSession, initial: previousSession?.initial, padding: nil, cycle: cycle)
    }
    
    // MARK: Game Cycle
    
    func started() {
        
    }
    
    func finished(session: PuttSession) {
        
    }
    
    func generateSession() -> PuttSession {
        let instance = PuttInstanceData(shots: [], opponentShots: nil, winner: nil)
        let initial = PuttInitialData(holeNumber: 1, holeSet: [])
        return PuttSession(instance: instance, initial: initial, ended: false, messageSession: opponentSession?.messageSession)
    }

}
