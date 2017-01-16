//
//  ShotIndicatorEntity.swift
//  MrPutt
//
//  Created by Developer on 1/15/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import GameplayKit

class ShotIndicatorEntity: GKEntity {

    var visual: ShotIndicatorRenderComponent {
        return component(ofType: ShotIndicatorRenderComponent.self)!
    }
    
    let ball: BallEntity!
    
    var stateMachine: GKStateMachine!
    
    let motionDuration: TimeInterval = 0.2
    
    var power: CGFloat = 0 {
        didSet {
            updatePowerIndicator(forPower: power)
        }
    }
    
    init(node: ShotIndicator, ball: BallEntity, orientedToward angleNode: SKNode, withOffset offset: SKRange) {
        self.ball = ball
        
        super.init()
        
        let states = [
            BallStoppedState(indicator: self),
            BallMovingState(indicator: self),
        ]
        stateMachine = GKStateMachine(states: states)
        
        let render = ShotIndicatorRenderComponent(shotIndicator: node, angleToward: angleNode, withOffset: offset)
        addComponent(render)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        visual.node.alpha = 0
    }
    
    func hide() {
        visual.node.alpha = 1
    }
    
    func ballStopped() {
        let fadeIn = SKAction.fadeIn(withDuration: motionDuration)
        visual.ballIndicator.run(fadeIn)
    }
    
    func showAngle() {
        let fadeIn = SKAction.fadeIn(withDuration: motionDuration)
        visual.angleIndicator.run(fadeIn)
    }
    
    func shotTaken() {
        let fadeOut = SKAction.fadeOut(withDuration: motionDuration)
        visual.ballIndicator.run(fadeOut)
        visual.angleIndicator.run(fadeOut)
        power = 0
    }
    
    func shotCancelled() {
        let fadeOut = SKAction.fadeOut(withDuration: motionDuration)
        visual.angleIndicator.run(fadeOut)
        power = 0
    }
    
    func updatePowerIndicator(forPower power: CGFloat) {
        var power = power < 0 ? 0 : power
        power = power > 1 ? 1 : power
        
        visual.powerIndicator.setScale(power)
        
        let red = UIColor(red: 0.882, green: 0.071, blue: 0.071, alpha: 1)
        let yellow = UIColor(red: 1.0, green: 0.943, blue: 0.023, alpha: 1)
        let green = UIColor(red: 0.086, green: 0.839, blue: 0.324, alpha: 1)
        
        func color(forPower: CGFloat) -> UIColor {
            if power < 0.5 {
                let step = power / 0.5
                return UIColor(red: green.r + (yellow.r - green.r)*step,
                               green: green.g + (yellow.g - green.g)*step,
                               blue: green.b + (yellow.b - green.b)*step,
                               alpha: 1)
            } else {
                let step = (power - 0.5) / 0.5
                return UIColor(red: yellow.r + (red.r - yellow.r)*step,
                               green: yellow.g + (red.g - yellow.g)*step,
                               blue: yellow.b + (red.b - yellow.b)*step,
                               alpha: 1)
            }
        }
        
        visual.powerIndicator.fillColor = color(forPower: power)
    }
    
}

class ShotIndicatorRenderComponent: RenderComponent {
    init(shotIndicator: ShotIndicator, angleToward: SKNode, withOffset offset: SKRange) {
        super.init(node: shotIndicator)
        
        let orient = SKConstraint.orient(to: node, offset: offset)
        angleIndicator.constraints = [orient]
        
        node.addChild(angleIndicator)
        node.addChild(ballIndicator)
        node.addChild(powerIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var ballIndicator: SKSpriteNode = {
        return SKSpriteNode(imageNamed: "shotIndicatorCircle")
    }()
    
    lazy var angleIndicator: SKSpriteNode = {
        return SKSpriteNode(imageNamed: "shotIndicatorArrow")
    }()
    
    lazy var powerIndicator: SKShapeNode = {
        let node = SKShapeNode(circleOfRadius: 72/2)
        node.fillColor = .red
        node.strokeColor = .clear
        return node
    }()
}

class ShotIndicatorState: GKState {
    let indicator: ShotIndicatorEntity

    init(indicator: ShotIndicatorEntity) {
        self.indicator = indicator
    }
}

class BallStoppedState: ShotIndicatorState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == BallMovingState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        if let parent = indicator.visual.node.parent,
            let ball = indicator.ball,
            let ballParent = ball.visual.node.parent {
            
            indicator.visual.node.position = ballParent.convert(ball.visual.node.position, to: parent)
        }
        
        indicator.show()
    }
}

class BallMovingState: ShotIndicatorState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == BallStoppedState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        indicator.hide()
    }
}
