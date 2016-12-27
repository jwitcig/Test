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
import AVFoundation


class GameViewController: UIViewController , SKPhysicsContactDelegate {
    
    
    
    
    
    //Audio Player(s)
    var audioPlayer = AVAudioPlayer()
    var winPlayer = AVAudioPlayer()
    
    
    var sceneView: SKView {
        return view as! SKView
    }
    
    var scene: SKScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.showsFPS = true
        
        sceneView.backgroundColor = .black
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        // create a new scene
        scene = SKScene(fileNamed: "Hole1")!
        sceneView.presentScene(scene)
        
        let camera = SKCameraNode()
        camera.setScale(2)
        scene.addChild(camera)
        
        scene.camera = camera
        //Checks physics contacts 
        scene.physicsWorld.contactDelegate = self
        
        
        scene.enumerateChildNodes(withName: "//wall") { (node, bool) in
            let body = SKPhysicsBody(rectangleOf: CGSize(width: 80 , height: 20))
            
            node.physicsBody = body
            
            body.isDynamic = false
            body.categoryBitMask = 2
            body.collisionBitMask = 1
            body.restitution = 0.5
            body.friction = 0
            body.mass = 2
            body.contactTestBitMask = 0
        }
        
        
        
        
        
        
        
        
        
        
        
        
        
                let clouds = scene.childNode(withName: "clouds") as! SKSpriteNode!
        let birds = scene.childNode(withName: "birds") as! SKSpriteNode!
        let golfBall = scene.childNode(withName: "golfBall") as! SKSpriteNode!
       
        let moveSlow = SKAction.move(by: CGVector(dx: -2000 ,dy: 0), duration: 200.0)
        
        golfBall?.physicsBody?.contactTestBitMask = 4
        
        //Play Background Music
        
        do{
            
            audioPlayer = try  AVAudioPlayer(contentsOf: URL.init( fileURLWithPath: Bundle.main.path(forResource: "ambience", ofType: "mp3")!))
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            audioPlayer.volume = 0.8
            audioPlayer.numberOfLoops = 100000000000000
            
            
        }
            
        catch{
            print(error)
        }
        
        
        
        
        clouds?.run(moveSlow)
        
        birds?.run(moveSlow)
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
        
            
            let location = touch.location(in: scene)
            let golfBall = scene.childNode(withName: "golfBall") as! SKSpriteNode!
        //    golfBall?.position = location
            
        }
        
    }
  
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            
            
            let location = touch.location(in: scene)
            let golfBall = scene.childNode(withName: "golfBall")! as! SKSpriteNode
            
            
            
            let v1 = CGVector(dx: location.x - golfBall.position.x, dy: location.y - golfBall.position.y)
            let v2 = CGVector(dx: location.x - golfBall.position.x, dy: location.y - golfBall.position.y)
            
            let angle = atan2(v2.dy, v2.dx) - atan2(v1.dy, v1.dx)
            
            
            let power: CGFloat = 20
            
            golfBall.physicsBody?.applyImpulse(CGVector(dx: cos(angle) * power ,dy: sin(angle) * power ))
            
            print("\(angle)")
            
            
        }
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        print("Yay we made contact Houston")
        
        
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
