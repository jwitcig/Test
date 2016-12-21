//
//  GameViewController.swift
//  testGolf
//
//  Created by Kenny Testa Jr on 12/15/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import UIKit
import QuartzCore
import SpriteKit

class GameViewController: UIViewController {
    
    var sceneView: SKView {
        return view as! SKView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.showsFPS = true
        
        sceneView.backgroundColor = .black
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        // create a new scene
        let scene = SKScene(fileNamed: "Hole1")!
        sceneView.presentScene(scene)
        
        let camera = SKCameraNode()
        camera.setScale(2)
        scene.addChild(camera)
        
        scene.camera = camera
        
        let tileMap = scene.childNode(withName: "tilemap") as! SKTileMapNode
        
        var bodies: [SKPhysicsBody] = []
        for column in 0...tileMap.numberOfColumns {
            for row in 0...tileMap.numberOfRows {
                        
                if let tile = tileMap.tileDefinition(atColumn: column, row: row), let isEdge = tile.userData?["isEdge"] as? Bool, isEdge {

                    let body = SKPhysicsBody(rectangleOf: tileMap.tileSize, center: tileMap.centerOfTile(atColumn: column, row: row))
                    
                    bodies.append(body)
                }
            }
        }
        
        tileMap.physicsBody = SKPhysicsBody(bodies: bodies)
        tileMap.physicsBody?.isDynamic = false
    }
    
    func configureScene(previousSession: PuttSession?) {
        // setup any visuals with data specific to the previous session; if nil, start fresh
        
        if let session = previousSession {
            
        } else {
            
        }
        
        let initial = previousSession?.initial ?? PuttInitialData.random()
        let firstHole = initial.holeSet[0]
                // create and add a camera to the scene
//        let camera = SKCameraNode()
//        scene.camera = camera
//        scene.addChild(camera)
    }
    
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        let location = gestureRecognize.location(in: sceneView)
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
