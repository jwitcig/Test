//
//  Ball.swift
//  MrPutt
//
//  Created by Developer on 1/15/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import GameplayKit

class BallEntity: GKEntity {

    var visual: BallRenderComponent {
        return component(ofType: BallRenderComponent.self)!
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
        
        let render = BallRenderComponent(node: node)
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

//class Ball: SKSpriteNode {
//    static let fileName = "Ball"
//    static let name = "ball"
//    
//    lazy var ballTrail: SKEmitterNode = {
//        return self.childNode(withName: "//ballTrail")! as! SKEmitterNode
//    }()
//    
//    var trailBirthrate: CGFloat = 100
//    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        
//        physicsBody = adjustedPhysicsBody()
//    }
//    
//    func adjustedPhysicsBody() -> SKPhysicsBody? {
//        physicsBody?.usesPreciseCollisionDetection = true
//        physicsBody?.categoryBitMask = Category.ball.rawValue
//        physicsBody?.collisionBitMask = Category.wall.rawValue
//        physicsBody?.contactTestBitMask = Category.hole.rawValue | Category.wall.rawValue
//        return physicsBody
//    }
//    
//    /* Should be called once ball is added to scene */
//    func updateTrailEmitter() {
//        ballTrail.targetNode = scene
//        ballTrail.particleScale *= 0.15
//        ballTrail.particleScaleSpeed *= 0.15
//    }
//    
//    func enableTrail() {
//        ballTrail.particleBirthRate = trailBirthrate
//    }
//    
//    func disableTrail() {
//        trailBirthrate = ballTrail.particleBirthRate
//        ballTrail.particleBirthRate = 0
//    }
//}

class BallRenderComponent: RenderComponent {
   
    
    
}

class BallShotState: GKState {
    let ball: BallEntity
    
    init(ball: BallEntity) {
        self.ball = ball
    }
}

class Ready: BallShotState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == Adjusting.self
    }
}

class Adjusting: BallShotState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == ShotTaken.self || stateClass == Cancelled.self
    }
}

class ShotTaken: BallShotState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == NotReady.self
    }
}

class NotReady: BallShotState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == Ready.self
    }
}

class Cancelled: BallShotState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == Ready.self
    }
}

class RenderComponent: GKComponent {
    let node: SKNode
    
    var position: CGPoint {
        get { return node.position }
        set { node.position = newValue }
    }
    
    var parent: SKNode? {
        return node.parent
    }
    
    init(node: SKNode) {
        self.node = node
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func position(in newParent: SKNode) -> CGPoint? {
        return parent?.convert(position, to: newParent)
    }
}

class PhysicsComponent: GKComponent {
    let body: SKPhysicsBody
    
    init(body: SKPhysicsBody) {
        self.body = body
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class StrokeComponent: GKComponent {
    var physics: PhysicsComponent {
        guard let physics = entity?.component(ofType: PhysicsComponent.self) else { fatalError("A StrokeComponent entity must have an PhysicsComponent") }
        return physics
    }
    
    func apply(toward direction: CGVector, withPower power: CGFloat) {
        physics.body.applyImpulse(direction.normalized * power)
    }
}
