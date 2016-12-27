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
    
    var scene: SKScene!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sceneName = "Hole1"
        scene = PuttScene(fileNamed: sceneName)!
        
        sceneView.presentScene(scene)
    }
    
    func configureScene(previousSession: PuttSession?) {
        // setup any visuals with data specific to the previous session; if nil, start fresh
        
        if let session = previousSession {
            
        } else {
            
        }
        
        let initial = previousSession?.initial ?? PuttInitialData.random()
        let firstHole = initial.holeSet[0]
    }
}
