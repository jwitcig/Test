//
//  GameplayClasses.swift
//  MrPutt
//
//  Created by Developer on 1/20/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import GameplayKit

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
