//
//  PuttScene.swift
//  testGolf
//
//  Created by Developer on 12/19/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import SpriteKit

class PuttScene: SKScene {
    //2
    let view2D:SKSpriteNode
    let viewIso:SKSpriteNode
    
    //3
    let tiles = [
        [1, 1, 1, 1, 1, 1],
        [1 ,0, 0, 0, 0, 1],
        [1 ,0, 0, 0, 0, 1],
        [1 ,0, 0, 0, 0, 1],
        [1 ,0, 0, 0, 0, 1],
        [1, 1, 1, 1, 1, 1]
    ]
    let tileSize = (width:32, height:32)
    
    //4
    override init(size: CGSize) {
        
        view2D = SKSpriteNode()
        viewIso = SKSpriteNode()
        
        super.init(size: size)
        self.anchorPoint = CGPoint(x:0.5, y:0.5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //5
    override func didMove(to view: SKView) {
        
        let deviceScale = self.size.width/667
        
        view2D.position = CGPoint(x:-self.size.width*0.45, y:self.size.height*0.17)
        view2D.xScale = deviceScale
        view2D.yScale = deviceScale
        addChild(view2D)
        
        viewIso.position = CGPoint(x:self.size.width*0.12, y:self.size.height*0.12)
        viewIso.xScale = deviceScale
        viewIso.yScale = deviceScale
        addChild(viewIso)
    }

}
