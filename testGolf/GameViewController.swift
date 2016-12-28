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

<<<<<<< HEAD
import JWSwiftTools

class GameViewController: UIViewController {
    
    var sceneView: SCNView {
        return view as! SCNView
    }
    
    var game: Putt!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // allows the user to manipulate the camera
        sceneView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // configure the view
        sceneView.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    func configureScene(previousSession: PuttSession?) {
        // setup any visuals with data specific to the previous session; if nil, start fresh
        
        if let session = previousSession {
            
        } else {
            
        }
        
        let initial = previousSession?.initial ?? PuttInitialData.random()
        let firstHole = initial.holeSet[0]
        
        game = Putt(previousSession: previousSession, initial: initial, padding: nil, cycle: SessionCycle(started: started, finished: finished, generateSession: gatherSessionData))
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/course\(firstHole).scn")!
        sceneView.scene = scene
=======
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
>>>>>>> spritekit

public extension CGVector {
    public var magnitude: CGFloat {
        return sqrt( dx*dx + dy*dy )
    }
<<<<<<< HEAD
    
    func started() {
        
    }
    
    func finished(session: PuttSession) {
        
    }
    
    func gatherSessionData() -> PuttSession {
        return PuttSession(dictionary: [:])!
    }
    
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: AnyObject = hitResults[0]
            
            // get its material
            let material = result.node!.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
=======
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
>>>>>>> spritekit
    }
    
    var scene: SKScene!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sceneName = "Hole1"
        scene = PuttScene(fileNamed: sceneName)!
        
        sceneView.presentScene(scene)
    }
}
