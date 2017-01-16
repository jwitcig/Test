//
//  GameViewController.swift
//  testGolf
//
//  Created by Kenny Testa Jr on 12/15/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import AVFoundation
import Messages
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

let menuAnimationTime: TimeInterval = 0.5

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
    var controlsPane: UserControlsView?
    
    var blurredScene: SKEffectNode?
    
    var settings: UIButton!
    var controls: UIButton!
    
    var menuButtons: [UIButton] {
        return [settings, controls]
    }
    
    var menuHiddenConstraints: ConstraintGroup!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settings = Bundle(for: GameViewController.self).loadNibNamed("SettingsButton", owner: nil, options: nil)![0] as! UIButton
        
        controls = Bundle(for: GameViewController.self).loadNibNamed("ControlsButton", owner: nil, options: nil)![0] as! UIButton

        settings.addTarget(self, action: #selector(GameViewController.menuLaunch(sender:)), for: .touchUpInside)
        
        controls.addTarget(self, action: #selector(GameViewController.controlsLaunch(sender:)), for: .touchUpInside)

        view.addSubview(toolsContainer)
        
        constrain(toolsContainer, view) {
            $0.leading == $1.leading
            $0.trailing == $1.trailing
            $0.top == $1.top
            $0.bottom == $1.bottom
        }
        
        toolsContainer.addSubview(settings)
        toolsContainer.addSubview(controls)
        
        menuHiddenConstraints = constrain(toolsContainer, settings, controls) {
            $1.bottom == $0.top
            $2.bottom == $0.top
        }
        
        constrain(toolsContainer, settings, controls) {
            $1.leading == $0.leading
            $2.leading == $1.trailing
        }

        toolsContainer.layoutIfNeeded()
        
        menuHiddenConstraints.active = false
        
        constrain(toolsContainer, settings, controls) {
            $1.top == $0.top
            $2.top == $0.top
        }
        
        UIView.animate(withDuration: 0.4, delay: 2, usingSpringWithDamping: 0.6, initialSpringVelocity: 20, options: .curveEaseInOut, animations: toolsContainer.layoutIfNeeded, completion: nil)
        
        
        let waitingForOpponent = WaitingForOpponentView()
        view.addSubview(waitingForOpponent)
        
        constrain(waitingForOpponent, view) {
            $0.width == $1.width
            $0.height == $1.height
            $0.center == $1.center
        }
    }
    
    func configureScene(previousSession: PuttSession?, course: CoursePack.Type) {
        // setup any visuals with data specific to the previous session; if nil, start fresh
        opponentSession = previousSession
        
        var hole = previousSession?.initial.holeNumber ?? 1
        
        let yourCompletedCourses = previousSession?.instance.opponentShots.count ?? 0
        let theirCompletedCourses = previousSession?.instance.shots.count ?? 0
        
        if yourCompletedCourses == theirCompletedCourses, yourCompletedCourses > 0, yourCompletedCourses < 9 {
        
            hole += 1
        }
        scene = SKScene(fileNamed: "\(course.name)-Hole\(hole)")! as! PuttScene
        
        scene.course = course
        scene.holeNumber = hole
        
        let cycle = SessionCycle(started: started, finished: finished, generateSession: generateSession)

        scene.game = Putt(previousSession: previousSession, initial: previousSession?.initial, padding: nil, cycle: cycle)
        
        HoleSetup.setup(scene, forHole: hole, inCourse: course)
    
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
        let settingsPane = InGameMenuView.create(motionDuration: menuAnimationTime)
        
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
        blurred.setScale(scene.camera!.xScale)
        
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
                self.toggleMenus(on: false, duration: TimeInterval((self.settingsPane?.motionDuration ?? 1) / 2))
            }
            
            settingsPane.didFinishMotion = {
                self.toggleMenus(on: true, duration: TimeInterval((self.settingsPane?.motionDuration ?? 1) / 2))
            }
        }
        AudioPlayer.main.play("click")

        toolsContainer.layoutIfNeeded()
        
        if settingsPane.isShown {
            settingsPane.dismiss()
        } else if controlsPane?.isShown == true {
            controlsPane?.dismiss()
        } else {
            scene.isUserInteractionEnabled = false
            settingsPane.show()
            
            self.blurredScene = blur(node: scene, in: sceneView, withDuration: 1)
            settingsPane.dismissBlock = {
                if let blurred = self.blurredScene {
                    self.unblur(node: blurred, withDuration: 1, completion: blurred.removeFromParent)
                }
                self.scene.isUserInteractionEnabled = true
                
                self.toggleMenus(on: false, duration: TimeInterval(1))
            }
        }
    }
    
    func controlsLaunch(sender: Any) {
        let controlsPane = self.controlsPane ?? UserControlsView.create(motionDuration: menuAnimationTime)
        self.controlsPane = controlsPane
        
        if controlsPane.superview == nil {
            toolsContainer.addSubview(controlsPane)
            controlsPane.visibleConstraints.active = false
            controlsPane.hiddenConstraints.active = true
            
            constrain(controlsPane, toolsContainer) {
                $0.width == $0.height * 1221.0/2325.0
                $0.height == $1.height * 0.9
                
                $0.centerX == $1.centerX
            }
            
            controlsPane.willBeginMotion = {
                self.toggleMenus(on: false, duration: TimeInterval((self.controlsPane?.motionDuration ?? 1)/2))
            }
            
            controlsPane.didFinishMotion = {
                self.toggleMenus(on: true, duration: TimeInterval((self.controlsPane?.motionDuration ?? 1)/2))
            }
        }
        AudioPlayer.main.play("click")

        toolsContainer.layoutIfNeeded()
        
        if controlsPane.isShown  {
            controlsPane.dismiss()
        } else if settingsPane?.isShown == true {
            settingsPane?.dismiss()
        } else {
            scene.isUserInteractionEnabled = false
            controlsPane.show()
            
            self.blurredScene = blur(node: scene, in: sceneView, withDuration: 1)
            controlsPane.dismissBlock = {
                if let blurred = self.blurredScene {
                    self.unblur(node: blurred, withDuration: 1, completion: blurred.removeFromParent)
                }
                self.scene.isUserInteractionEnabled = true
            }
            
            let cancel = UITapGestureRecognizer(target: self, action: #selector(GameViewController.closeUserControlsMenu(recognizer:)))
            toolsContainer.addGestureRecognizer(cancel)
        }
    }
    
    func closeUserControlsMenu(recognizer: UITapGestureRecognizer) {
        controlsPane?.dismiss()
        
        recognizer.view?.removeGestureRecognizer(recognizer)
    }
    
    func toggleMenus(on: Bool, duration: TimeInterval) {
        menuButtons.forEach { button in
            UIView.transition(with: button,
                              duration: duration,
                              options: .transitionCrossDissolve,
                              animations: { button.isEnabled = on },
                              completion: nil)
        }
    }
    
    func removeSettings(duration: TimeInterval) {
        menuButtons.forEach { button in
            UIView.transition(with: button,
                              duration: duration,
                              options: .transitionCrossDissolve,
                              animations: { button.alpha = 0 },
                              completion: { _ in button.removeFromSuperview() })
        }
    }
    
    // MARK: Game Cycle
    
    func started() {
        
    }
    
    func finished(session: PuttSession) {
        let hole = session.initial.holeNumber
        
        let names = ("You", "Them")
        
        let player1Strokes = session.gameData.shots
        let player2Strokes = session.gameData.opponentShots

        if let winner = session.gameData.winner {
            switch winner {
            case .you:
                AudioPlayer.main.play("winGame")
            case .them:
                AudioPlayer.main.play("gameOver")
            case .tie:
                break
            }
        }
        
        let pars = [Int](repeatElement(3, count: 9))
        
        removeSettings(duration: TimeInterval(1))
        
        scene.preScorecardTearDown()
        
        let when = DispatchTime.now() + 1.5
        DispatchQueue.main.asyncAfter(deadline: when) { 
            self.scene.showScorecard(hole: hole, names: names, player1Strokes: player1Strokes, player2Strokes: player2Strokes, pars: pars) {
                
                guard let message = PuttMessageWriter(data: session.dictionary,
                                                      session: session.messageSession)?.message else { return }
                let activeConversation = (self.messageSender as? MSMessagesAppViewController)?.activeConversation
                let layout = PuttMessageLayoutBuilder(session: session, conversation: activeConversation).generateLayout()
                
                self.messageSender?.send(message: message, layout: layout, completionHandler: { error in
                })
                
                self.orientationManager?.requestPresentationStyle(.compact)
                
                self.showGameViewControllerViews()
                
                let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                let remove = SKAction.run {
                    self.sceneView.presentScene(nil)
                }
                self.scene.run(SKAction.sequence([fadeOut, remove]))
            }

        }
    }
    
    func generateSession() -> PuttSession {
        let strokes = scene.shots.count
        
        var shots = [strokes > 1 ? strokes : 0]
        var winner: Team.OneOnOne? = nil

        if let opponentSession = opponentSession {
            // your opponent's opponent is you
            shots = opponentSession.gameData.opponentShots + shots
            
            let yourShots = shots
            let theirShots = opponentSession.gameData.shots
            
            let yourScore = yourShots.reduce(0, +)
            let theirScore = theirShots.reduce(0, +)
        
            if yourShots.count == 9 && theirShots.count == 9 {
                winner = yourScore < theirScore  ? .you : .them
                winner = yourScore == theirScore ? .tie : winner
            }
        }
        
        let instance = PuttInstanceData(shots: shots, opponentShots: opponentSession?.gameData.shots, winner: winner)
        let initial = PuttInitialData(course: scene.course, holeNumber: scene.holeNumber, holeSet: Array(1...9))
        return PuttSession(instance: instance, initial: initial, ended: false, messageSession: opponentSession?.messageSession)
    }

}
