//
//  Cart.swift
//  MrPutt
//
//  Created by Developer on 1/15/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import GameplayKit

class Cart: GKEntity, GKAgentDelegate {
    
    let agent = GKAgent2D()
    
    var movement: GKBehavior
    
    let node: SKNode

    init(node: SKNode, follow pathPoints: [CGPoint]? = nil, track agentToTrack: GKAgent? = nil) {
        
        self.node = node
        
        self.movement = GKBehavior()
        
        super.init()
        
        self.agent.delegate = self

        if let pathPoints = pathPoints {
            let path = GKPath(points: pathPoints.map{float2(Float($0.x), Float($0.y))},
                              radius: 60, cyclical: true)
            
            let follow = GKGoal(toFollow: path, maxPredictionTime: 1.0, forward: true)
            
            movement = GKBehavior(goal: follow, weight: 1)

        } else if let toBeTracked = agentToTrack {
            let track = GKGoal(toInterceptAgent: toBeTracked, maxPredictionTime: 3.0)
            movement = GKBehavior(goal: track, weight: 1)

        } else {
            movement = GKBehavior()
        }
        
        agent.behavior = movement
        agent.maxSpeed = 500
        agent.maxAcceleration = 1000
        agent.mass = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func agentWillUpdate(_ agent: GKAgent) {
        let agent = agent as! GKAgent2D
        
        
        agent.rotation = Float(node.zRotation - .pi / 2)
        agent.position = float2(Float(node.position.x), Float(node.position.y))
    }
    
    func agentDidUpdate(_ agent: GKAgent) {
        let agent = agent as! GKAgent2D
        node.zRotation = CGFloat(agent.rotation) + .pi / 2
        node.position = CGPoint(x: CGFloat(agent.position.x), y: CGFloat(agent.position.y))
    }
    
}
