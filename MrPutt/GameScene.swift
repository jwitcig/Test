//
//  GameScene.swift
//  MrPutt
//
//  Created by Kenny Testa Jr on 12/10/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation



class GameScene: SKScene {
    
    //SpriteNodes
    var ball = SKSpriteNode()
    var direction = SKSpriteNode()
    var score = [Int]()
    var hole = SKSpriteNode()
    var rock2 = SKSpriteNode()
    var test = SKSpriteNode()
    var powerHolder = SKSpriteNode()
    var powerSlider = SKSpriteNode()
    var angleHolder = SKSpriteNode()
    var angleSlider = SKSpriteNode()
    var degrees = SKLabelNode()
    
    let trailNode = SKNode()

    
    var lastTouchX = CGFloat()
    var lastTouchY = CGFloat()
    
    
    //Audio Player
    var audioPlayer = AVAudioPlayer()

    
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    override func didMove(to view: SKView) {
        
        
        //Play Background Music 
        
        do{
            
            audioPlayer = try  AVAudioPlayer(contentsOf: URL.init( fileURLWithPath: Bundle.main.path(forResource: "ambience", ofType: "mp3")!))
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            audioPlayer.volume = 0.5
            let infinite = 100000000000000
            audioPlayer.numberOfLoops = infinite
        }
        
        catch{
            print(error)
        }

        // Instantiate all nodes
        
        ball = self.childNode(withName:"ball") as! SKSpriteNode
        direction = self.childNode(withName: "direction") as! SKSpriteNode
        hole = self.childNode(withName: "hole") as! SKSpriteNode
        rock2 = self.childNode(withName: "rock2") as! SKSpriteNode
        powerHolder = self.childNode(withName: "powerHolder") as! SKSpriteNode
        powerSlider = self.childNode(withName: "powerSlider") as! SKSpriteNode
        test = self.childNode(withName: "test") as! SKSpriteNode
        angleHolder = self.childNode(withName: "angleHolder") as! SKSpriteNode
        angleSlider = self.childNode(withName: "angleSlider") as! SKSpriteNode
        degrees = self.childNode(withName: "degrees") as! SKLabelNode
        
        //Border to prevent Ball from flying off screen
        
        let border = SKPhysicsBody(edgeLoopFrom: self.frame)
        border.friction = 0
        border.restitution = 0
        self.physicsBody = border
        

        
        
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       
        //Grab Touch Location
        
        for touch in touches{
      //  let location = touch.location(in: self)//Keep below value with a decimal
        
            //Change position of powerBar based on balls position
            
            direction.position.x = ball.position.x
            direction.position.y = ball.position.y
            direction.alpha = 1
            
        }
        
    }
    
    
    func showPowerSlider(){
        powerHolder.alpha = 1
        powerSlider.alpha = 1
    
    }
    
    func hidePowerSlider(){
        powerHolder.alpha = 0
        powerSlider.alpha = 0
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            
            let location = touch.location(in: self)//Keep below value with a decimal
            //main.run(SKAction.moveTo(x: location.x, duration: 0.1))
      
       
            
            if (location.x > -280){
               
            // Get sprite's current position (a.k.a. starting point).
          //--      let currentPosition = ball.position
                
            // Calculate the angle using the relative positions of the sprite and touch.
         //--       let angle = atan2(currentPosition.y - location.y, direction.position.x - location.x)
                
            // Define actions for the ship to take.
         //  --     let rotateAction = SKAction.rotate(toAngle: angle  + CGFloat(M_PI*0.5), duration: 0.0)
         
         //    --   direction.run(SKAction.sequence([rotateAction]))
            
            //Actually moves the directional arrow thing
                direction.position.x = ball.position.x
                direction.position.y = ball.position.y

            
                
                lastTouchX = location.x
                
                lastTouchY = location.y
                
          
            }
         //Allows slider to work properly
            if (location.x < -280){
                
            powerSlider.position.y = location.y + 100

            
            }
            
            if (location.y < -500){
                
                angleSlider.position.x = location.x
                degrees.position.x = location.x
                
                degrees.text = "\((angleSlider.position.x * 1.0).rounded(.towardZero))" + "°"
                direction.zRotation = angleSlider.position.x * -0.01
                
                
                
            
            }
        
        
        }
        

       
        
        
        
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches{
            
            
            print ("\(angleSlider.position.x)")
            
            let location = touch.location(in: self)//Keep below value with a decimal

            
        //    let currentPosition = direction.position
           // let gBallDirection = direction.zRotation
           //  let angle = atan2(currentPosition.y - location.y, direction.position.x - location.x)
         //   let sendtoAngle = SKAction.applyImpulse(CGVector(dx: 1.0 , dy: 0.0), duration: 0.0)
            
            
            if ball.position.x + 30 == hole.position.x + 30 && ball.position.y + 30 == hole.position.y + 30{
            
                ball.position.x = hole.position.x
                ball.position.y = hole.position.y
            
            }
            
            let degrees = angleSlider.position.x
            let radians = (.pi / 180) * -degrees + .pi/2
            
            let impulse = CGVector(dx: cos(radians), dy: sin(radians))
            
            if (location.y < 630) && (location.x < -280) {
                ball.physicsBody?.applyImpulse(impulse)
                run(SKAction.playSoundFileNamed("clubHit2.wav", waitForCompletion: false))
                
            }
            
            let resetPowerSlider = SKAction.moveTo(y: 630, duration: 0.05)
            powerSlider.run(resetPowerSlider)
            
        }
      }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered //Keep below value with a decimal
      //  enemy.run(SKAction.moveTo(x: ball.position.x, duration: 0.3))
        direction.position.x = ball.position.x
        direction.position.y = ball.position.y

        let n = (angleSlider.position.x * 1.0).rounded(.towardZero)
        
        if (n == 10 || n == 50 || n == 100 || n == 150 || n == 200  || n == 250 || n == 300 || n == 350 || n == -10  ){
            run(SKAction.playSoundFileNamed("notch.wav", waitForCompletion: true))
        }


        
    
    }
}

