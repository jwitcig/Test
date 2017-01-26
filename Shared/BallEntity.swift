//
//  BallEntity.swift
//  MrPutt
//
//  Created by Developer on 1/20/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import GameplayKit

class BallEntity: GKEntity {
    var visual: RenderComponent {
        return component(ofType: RenderComponent.self)!
    }
    
    var physics: PhysicsComponent {
        return component(ofType: PhysicsComponent.self)!
    }
    
    var stroke: StrokeComponent? {
        return component(ofType: StrokeComponent.self)
    }
    
    var ballTrail: SKEmitterNode? {
        return visual.node.childNode(withName: "//ballTrail") as? SKEmitterNode
    }
    var trailBirthrate: CGFloat = 100
    
    var shotMachine: GKStateMachine!
    
    init(node: Ball, physics body: SKPhysicsBody) {
        super.init()
        
        let shotStates = [
            Ready(ball: self),
            Adjusting(ball: self),
            ShotTaken(ball: self),
            NotReady(ball: self),
            Cancelled(ball: self),
        ]
        shotMachine = GKStateMachine(states: shotStates)
        
        let render = RenderComponent(node: node)
        let physics = PhysicsComponent(body: body)
        
        render.node.physicsBody = physics.body
        
        addComponent(render)
        addComponent(physics)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func enableTrail() {
        ballTrail?.particleBirthRate = trailBirthrate
    }
    
    func disableTrail() {
        trailBirthrate = ballTrail?.particleBirthRate ?? trailBirthrate
        ballTrail?.particleBirthRate = 0
    }
    
    func updateTrailEmitter() {
        ballTrail?.targetNode = ballTrail?.scene
        ballTrail?.particleScale *= 0.15
        ballTrail?.particleScaleSpeed *= 0.15
    }
}
