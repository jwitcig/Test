//
//  GameViewController.swift
//  testGolf
//
//  Created by Kenny Testa Jr on 12/15/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import AVFoundation
import QuartzCore
import SpriteKit
import UIKit

import Cartography
import Game
import iMessageTools
import JWSwiftTools

import CoreImage

enum Options: String {
    case gameMusic = "Music"
}

class GameViewController: UIViewController {

    var sceneView: SKView {
        return view as! SKView
    }
    
    var toolsContainer = UIView()
    
    var scene: PuttScene!
    var opponentSession: PuttSession?
    
    var messageSender: MessageSender?
    var orientationManager: OrientationManager?
    
    var settingsPane: InGameMenuView?
    
    var blurredScene: SKEffectNode?
    
    var settings: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settings = Bundle(for: GameViewController.self).loadNibNamed("SettingsButton", owner: nil, options: nil)![0] as! UIButton
        
        settings.addTarget(self, action: #selector(GameViewController.menuLaunch(sender:)), for: .touchUpInside)

        toolsContainer.addSubview(settings)
        
        constrain(settings, toolsContainer) {
            $0.top == $1.top
            $0.leading == $1.leading
        }
        
        view.addSubview(toolsContainer)
        
        constrain(toolsContainer, view) {
            $0.leading == $1.leading
            $0.trailing == $1.trailing
            $0.top == $1.top
            $0.bottom == $1.bottom
        }
    
        
        let p1 = [Int](repeatElement(9, count: 9))
        let p2 = [Int](repeatElement(7, count: 9))
        
        let pars = [Int](repeatElement(3, count: 9))
        
        let scorecard = Scorecard(hole: 1, names: ("Jimmy", "John"), player1Strokes: p1, player2Strokes: p2, pars: pars)
        toolsContainer.addSubview(scorecard)
        
        constrain(scorecard, toolsContainer) {
            $0.width == $0.height * (235.0/356.0)

            $0.width == $1.width * 0.8 ~ 900
            $0.height == $1.height * 0.8 ~ 900

            $0.width <= $1.width * 0.8
            $0.height <= $1.height * 0.8

            $0.center == $1.center
        }
    }
    
    func configureScene(previousSession: PuttSession?, course: CoursePack.Type) {
        // setup any visuals with data specific to the previous session; if nil, start fresh
        opponentSession = previousSession
        
        var hole = previousSession?.initial.holeNumber ?? 2
        
        let yourCompletedCourses = previousSession?.instance.opponentShots.count ?? 0
        let theirCompletedCourses = previousSession?.instance.shots.count ?? 0
        
        if yourCompletedCourses == theirCompletedCourses, yourCompletedCourses > 0, yourCompletedCourses < 9 {
        
            hole += 1
        }
        
        scene = SKScene(fileNamed: "\(course.name)-Hole\(hole)")! as! PuttScene
        
        scene.course = course
        scene.hole = hole
        
        let cycle = SessionCycle(started: started, finished: finished, generateSession: generateSession)

        scene.game = Putt(previousSession: previousSession, initial: previousSession?.initial, padding: nil, cycle: cycle)
        
        HoleSetup.setup(scene, forHole: hole, inCourse: Frost.self)
    
        orientationManager?.requestPresentationStyle(.expanded)
        sceneView.presentScene(scene)
     
        hideGameViewControllerViews()
    }
    
    func hideGameViewControllerViews() {
        view.subviews.filter { $0 != toolsContainer }
                     .forEach { $0.isHidden = true }
    }
    
    func showGameViewControllerViews() {
        view.subviews.forEach { $0.isHidden = false }
    }
    
    func createSettingsPane() -> InGameMenuView {
        let settingsPane = InGameMenuView.create()
        
        let settings = UserDefaults.standard
        
        let music = InGameOptionView.create()
        music.optionName = Options.gameMusic.rawValue
        music.enabled = settings.value(forKey: music.optionName) as? Bool ?? true
        
        let effects = InGameOptionView.create()
        effects.optionName = "Effects"
        effects.enabled = settings.value(forKey: effects.optionName) as? Bool ?? true
        
        let hud = InGameOptionView.create()
        hud.optionName = "HUD"
        hud.enabled = settings.value(forKey: hud.optionName) as? Bool ?? true
        
        settingsPane.options = [music, effects, hud]
        return settingsPane
    }
    
    func blur(node: SKNode, in view: SKView, withDuration duration: TimeInterval) -> SKEffectNode {
        let blur = CIFilter(name: "CIGaussianBlur")!
        let radius: CGFloat = 10.0
        blur.setValue(0, forKey: kCIInputRadiusKey)
        
        let effect = SKEffectNode()
        effect.shouldEnableEffects = true
        effect.filter = blur
        
        let animateBlur = SKAction.customAction(withDuration: duration) { node, elapsed in
            blur.setValue(radius * elapsed/CGFloat(duration), forKey: kCIInputRadiusKey)
        }
        effect.run(animateBlur)
        
        let blurred = SKSpriteNode(texture: view.texture(from: node))
        blurred.position = scene.camera!.position
        
        effect.addChild(blurred)
        node.addChild(effect)
        
        return effect
    }
    
    func unblur(node: SKEffectNode, withDuration duration: TimeInterval, completion: @escaping ()->Void) {
        let radius = node.filter?.value(forKey: kCIInputRadiusKey) as? CGFloat ?? 0
        
        let unblur = SKAction.customAction(withDuration: duration) { node, elapsed in
            (node as? SKEffectNode)?.filter?.setValue(radius - radius * elapsed/CGFloat(duration), forKey: kCIInputRadiusKey)
        }
        
        let completed = SKAction.run(completion)
        let sequence = SKAction.sequence([unblur, completed])
        node.run(sequence)
    }
    
    func menuLaunch(sender: Any) {
        let settingsPane = self.settingsPane ?? createSettingsPane()
        self.settingsPane = settingsPane
        
        if settingsPane.superview == nil {
            toolsContainer.addSubview(settingsPane)
            settingsPane.visibleConstraints.active = false
            settingsPane.hiddenConstraints.active = true
            
            constrain(settingsPane, toolsContainer) {
                $0.width == $1.width * 0.8
                $0.height >= $1.height * 0.5
                
                $0.centerX == $1.centerX
            }
            
            settingsPane.willBeginMotion = {
                self.settings.isEnabled = false
            }
            
            settingsPane.didFinishMotion = {
                self.settings.isEnabled = true
            }
            
            self.blurredScene = blur(node: scene, in: sceneView, withDuration: 1)
            settingsPane.dismissBlock = {
                if let blurred = self.blurredScene {
                    self.unblur(node: blurred, withDuration: 1, completion: blurred.removeFromParent)
                }
                self.settingsPane = nil
                self.scene.isUserInteractionEnabled = true
            }
        }
        
        toolsContainer.setNeedsLayout()
    
        if settingsPane.isShown {
            settingsPane.dismiss()
        } else {
            scene.isUserInteractionEnabled = false
            settingsPane.show()
        }
    }
    
    // MARK: Game Cycle
    
    func started() {
        
    }
    
    func finished(session: PuttSession) {
        guard let message = PuttMessageWriter(data: session.dictionary,
                                           session: session.messageSession)?.message else { return }
        
        let layout = PuttMessageLayoutBuilder(session: session).generateLayout()
        
        
        messageSender?.send(message: message, layout: layout, completionHandler: { error in
        })
        
        orientationManager?.requestPresentationStyle(.compact)
        
        showGameViewControllerViews()
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.run {
            self.sceneView.presentScene(nil)
        }
        scene.run(SKAction.sequence([fadeOut, remove]))
    }
    
    func generateSession() -> PuttSession {
        var shots = [scene.shots.count]
        var winner: Team.OneOnOne? = nil

        if let opponentSession = opponentSession {
            // your opponent's opponent is you
            shots = opponentSession.gameData.opponentShots + shots
            
            let yourScore = shots.reduce(0, +)
            let theirScore = opponentSession.gameData.shots.reduce(0, +)
            
            winner = yourScore < theirScore  ? .you : .them
            winner = yourScore == theirScore ? .tie : winner
        }
        
        let instance = PuttInstanceData(shots: shots, opponentShots: opponentSession?.gameData.shots, winner: winner)
        let initial = PuttInitialData(course: scene.course, holeNumber: scene.hole, holeSet: [1, 2, 3])
        return PuttSession(instance: instance, initial: initial, ended: false, messageSession: opponentSession?.messageSession)
    }

}
