//
//  Scorecard.swift
//  MrPutt
//
//  Created by Developer on 1/11/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import SpriteKit

import JWSwiftTools

public extension Collection {
    public subscript(safe index: Index) -> Iterator.Element? {
        guard index >= startIndex, index < endIndex else { return nil }
        return self[index]
    }
}

infix operator |

class Scorecard: SKScene {
    static let name = "scorecard"
    
    lazy var infoPanel: SKSpriteNode = {
        return self.childNode(withName: "infoPanel")! as! SKSpriteNode
    }()
    
    lazy var card: SKSpriteNode = {
        return self.childNode(withName: "card")! as! SKSpriteNode
    }()
    
    lazy var button: SKSpriteNode = {
        return self.childNode(withName: "continue")! as! SKSpriteNode
    }()
    
    var token: ShotToken? {
        didSet {
            guard let token = token else { return }
            token.zPosition = 100
            addChild(token)
        }
    }
    
    var donePressed: ()->Void = { }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        physicsBody = nil
    }

    func update(hole: Int, names: (String, String), player1Strokes: [Int], player2Strokes:
        [Int], course: CoursePack.Type) {
    
        let pars = (1...9).map { HoleInfo.par(forHole: $0, in: course) }
        
        let shotsDefault = "-"
        let cardImage = ScorecardStyleKit.imageOfCard(color3: .white,
                            holeNumber: hole.string!, name1: names.0, name2: names.1,
                          player1Hole1: player1Strokes[safe: 0]?.string ?? shotsDefault,
                          player1Hole2: player1Strokes[safe: 1]?.string ?? shotsDefault,
                          player1Hole3: player1Strokes[safe: 2]?.string ?? shotsDefault,
                          player1Hole4: player1Strokes[safe: 3]?.string ?? shotsDefault,
                          player1Hole5: player1Strokes[safe: 4]?.string ?? shotsDefault,
                          player1Hole6: player1Strokes[safe: 5]?.string ?? shotsDefault,
                          player1Hole7: player1Strokes[safe: 6]?.string ?? shotsDefault,
                          player1Hole8: player1Strokes[safe: 7]?.string ?? shotsDefault,
                          player1Hole9: player1Strokes[safe: 8]?.string ?? shotsDefault,
                          
                          player2Hole1: player2Strokes[safe: 0]?.string ?? shotsDefault,
                          player2Hole2: player2Strokes[safe: 1]?.string ?? shotsDefault,
                          player2Hole3: player2Strokes[safe: 2]?.string ?? shotsDefault,
                          player2Hole4: player2Strokes[safe: 3]?.string ?? shotsDefault,
                          player2Hole5: player2Strokes[safe: 4]?.string ?? shotsDefault,
                          player2Hole6: player2Strokes[safe: 5]?.string ?? shotsDefault,
                          player2Hole7: player2Strokes[safe: 6]?.string ?? shotsDefault,
                          player2Hole8: player2Strokes[safe: 7]?.string ?? shotsDefault,
                          player2Hole9: player2Strokes[safe: 8]?.string ?? shotsDefault,
                        
                          player1Total: player1Strokes.reduce(0, +).string!,
                          player2Total: player2Strokes.reduce(0, +).string!)

        let parDefault = "-"
        let infoImage = ScorecardStyleKit.imageOfHoleInfo(color3: .white,
                                      parHole1: pars[safe: 0]?.string ?? parDefault,
                                      parHole2: pars[safe: 1]?.string ?? parDefault,
                                      parHole3: pars[safe: 2]?.string ?? parDefault,
                                      parHole4: pars[safe: 3]?.string ?? parDefault,
                                      parHole5: pars[safe: 4]?.string ?? parDefault,
                                      parHole6: pars[safe: 5]?.string ?? parDefault,
                                      parHole7: pars[safe: 6]?.string ?? parDefault,
                                      parHole8: pars[safe: 7]?.string ?? parDefault,
                                      parHole9: pars[safe: 8]?.string ?? parDefault)
        
        card.texture = SKTexture(image: cardImage)
        infoPanel.texture = SKTexture(image: infoImage)
        
        let mask = SKSpriteNode(texture: nil)
        mask.size = (childNode(withName: "infoCropper")! as! SKSpriteNode).size
        mask.color = .black
        
        let crop = SKCropNode()
        crop.maskNode = mask
        crop.position = childNode(withName: "infoCropper")!.position
        infoPanel.position = CGPoint(x: 50, y: 0)
        infoPanel.removeFromParent()
        crop.addChild(infoPanel)
        
        addChild(crop)
        
        let par = HoleInfo.par(forHole: hole, in: course)
        
        if let strokes = player1Strokes[safe: hole-1] {
            token = ShotToken(forShots: strokes, onPar: par)
        } else {
            let strokesList = [Int](repeatElement(0, count: hole-1)) + player1Strokes
            token = ShotToken(forShots: strokesList[hole-1], onPar: par)
        }
        
        if let token = token {
            token.position = CGPoint(x: card.frame.maxX-token.size.width/1.5, y: card.frame.maxY*3+token.size.height/2)
        }
    }
    
    func showHoleInfo() {
        let slide = SKAction.moveBy(x: -50, y: 0, duration: 0.8)
        slide.timingMode = .easeOut
        
        infoPanel.run(slide)
    }
    
    func showToken() {
        guard let token = token else { return }
        let destination = CGPoint(x: card.frame.maxX-token.size.width/1.5, y: card.frame.maxY-token.size.height/2)
    
        let animationDuration: TimeInterval = 0.5
        
        let move = SKAction.move(to: destination, duration: animationDuration)
        move.timingMode = .easeInEaseOut
        token.run(move)
        
        let settings = UserDefaults.standard
        let isEffectsOn = settings.value(forKey: Options.effects.rawValue) as? Bool ?? true
    
        if isEffectsOn {
            let sound = SKAction.playSoundFileNamed("coinSound.wav", waitForCompletion: false)
            let delay = SKAction.wait(forDuration: animationDuration/2)
            let sequence = SKAction.sequence([delay, sound])
            token.run(sequence)
        }
        
    }
}
