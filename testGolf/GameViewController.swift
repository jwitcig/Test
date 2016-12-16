//
//  GameViewController.swift
//  testGolf
//
//  Created by Kenny Testa Jr on 12/15/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

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

        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        sceneView.scene!.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        sceneView.scene!.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        sceneView.scene!.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
        let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!
        
        let ball = scene.rootNode.childNode(withName: "sphere", recursively: true)!
        
        let light1 = scene.rootNode.childNode(withName: "light1", recursively: true)!
        
        let box1 = scene.rootNode.childNode(withName: "box1", recursively: true)!
        
        let rotateBox = SCNAction.rotateBy(x: 20, y: 0, z: 0, duration: 3.0)
        
        box1.runAction(rotateBox)
        
        ball.physicsBody?.applyForce(SCNVector3(0,1,2), asImpulse: true)
        
        // animate the 3d object
        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
    }
    
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
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
}
