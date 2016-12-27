//
//  PuttScene.swift
//  testGolf
//
//  Created by Developer on 12/19/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import SpriteKit

class PuttScene: SKScene {
    
    lazy var ball: SKNode = {
        return self.childNode(withName: "ball")!
    }()

    lazy var shotPathLine: SKNode = {
        return self.childNode(withName: "shotPathLine")!
    }()
    
    lazy var golfBall1: SKNode = {
        return self.childNode(withName: "golfBall")!
    }()

    
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches{
            let location = touch.location(in: self)
            //Change position of powerBar based on balls position
        }
    }
    
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            
            let location = touch.location(in: self)
            
          //  ball.position = location
            
            // Get sprite's current position (a.k.a. starting point).
            let currentPosition = shotPathLine.position
            
            // Calculate the angle using the relative positions of the sprite and touch.
            let angle = atan2(currentPosition.y - location.y, currentPosition.x - location.x)
            
            // Define actions for the ship to take.
            let rotateAction = SKAction.rotate(toAngle: angle + CGFloat(M_PI*0.5) , duration: 0.0)
            
            // Tell the ship to execute actions.
            //   direction.run(SKAction.sequence([rotateAction]))
            
            shotPathLine.run(rotateAction)
            
            
            
            
        }
    }
    
    
    
    //------------------------------  Touches Ended  something in the comment  --------------------------------//
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        
        
        
        for touch in touches{
            
            
            /*
            let strokeForce = abs((powerSlider.position.y - 330) * 0.01 )
            let degrees2 = angleSlider.position.x
            
            let radians = (.pi / 180) *  -degrees2 + (.pi/2)
            
            
            
            let impulse = CGVector(dx: cos(radians) * strokeForce , dy: sin(radians) * strokeForce )
            
            
            
            if (location.y < 630) && (location.x < -280) && (location.y < 300) {
                direction.alpha = 0
                ball.physicsBody?.applyImpulse(impulse)
                run(SKAction.playSoundFileNamed("clubHit.wav", waitForCompletion: false))
                
                
                
                
                playerHitCount = playerHitCount + 1
                playerScore.text = "\(playerHitCount)"
                
            }
            
            let resetPowerSlider = SKAction.moveTo(y: 280, duration: 0.03)
            powerSlider.run(resetPowerSlider)
            
      */
            
            
        }
    }

    
    
    //------------------------------  Update Game Functions   --------------------------------//
    
    override func update(_ currentTime: TimeInterval) {
        
        
        //Sets up positioning for the directional path image
        shotPathLine.position.x = golfBall1.position.x
        shotPathLine.position.y = golfBall1.position.y 
        
        
        
        
    }
    
    
    
}
