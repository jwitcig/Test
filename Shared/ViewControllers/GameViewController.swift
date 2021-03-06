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

import FirebaseAnalytics

enum Options: String {
    case gameMusic = "Music"
    case effects = "Effects"
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
    
    var hud: HUDView!
    
    var gameCompleted = false
    
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
        
        hud = HUDView.create(par: 0)
        toolsContainer.addSubview(hud)
        constrain(hud, toolsContainer) {
            $0.trailing == $1.trailing - 10
            
            $0.width == 120
            $0.height == 40
        }
        hud.isHidden = true
        
        menuHiddenConstraints = constrain(toolsContainer, settings, controls, hud) {
            $1.bottom == $0.top
            $2.bottom == $0.top
            $3.bottom == $0.top
        }
        
        constrain(toolsContainer, settings, controls) {
            $1.leading == $0.leading
            $2.leading == $1.trailing
            
            $1.width == 60
            $1.height == 60
            $2.size == $1.size
        }

        toolsContainer.layoutIfNeeded()
        
        menuHiddenConstraints.active = false
        
        constrain(toolsContainer, settings, controls, hud) {
            $1.top == $0.top
            $2.top == $0.top
            $3.top == $0.top + 10
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
//        scene = SKScene(fileNamed: "\(course.name)-Hole\(hole)")! as! PuttScene
        scene = SKScene(fileNamed: "Frost-Hole1")! as! PuttScene
        
        scene.course = course
        scene.holeNumber = hole
        
        let cycle = SessionCycle(started: started, finished: finished, generateSession: generateSession)

        scene.game = Putt(previousSession: previousSession, initial: previousSession?.initial, padding: nil, cycle: cycle)
        
        orientationManager?.requestPresentationStyle(.expanded)
        sceneView.presentScene(scene)

        let par = HoleInfo.par(forHole: hole, in: course)
        hud.parLabel.text = "\(par)"
        scene.hud = hud
        scene.hud.isHidden = false
        
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
                
        let music = InGameOptionView.create()
        music.optionName = Options.gameMusic.rawValue
        music.enabled = UserSettings.current.isMusicEnabled
        
        let effects = InGameOptionView.create()
        effects.optionName = "Effects"
        effects.enabled = UserSettings.current.isEffectsEnabled
    
        settingsPane.options = [music, effects]
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
                $0.width == $1.width * 0.8 ~ 900
                $0.height >= $1.height * 0.5 ~ 900
            
                $0.width <= 300
                $0.height <= 300
                
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
            FIRAnalytics.logEvent(withName: "SettingsShown", parameters: nil)
            
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
                $0.height == $1.height * 0.9 ~ 900
                
                $0.height <= 400
                
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
        
        if controlsPane.isShown {
            controlsPane.dismiss()
        } else if settingsPane?.isShown == true {
            settingsPane?.dismiss()
        } else {
            FIRAnalytics.logEvent(withName: "ControlsShown", parameters: nil)
            
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
    
    func removeHUD(duration: TimeInterval) {
        UIView.transition(with: scene.hud,
                          duration: duration,
                          options: .transitionCrossDissolve,
                          animations: { self.scene.hud.alpha = 0 },
                          completion: { _ in self.scene.hud.removeFromSuperview() })
    }
    
    func tearDown() {
        view.removeFromSuperview()
        scene.audio.backgroundMusic?.pause()
        sceneView.presentScene(nil)
    }
    
    deinit {
        print("GameViewController is gone!")
    }
    
    // MARK: Game Cycle
    
    func started() {
        
    }
    
    func finished(session: PuttSession) {
        gameCompleted = true
        
        let hole = session.initial.holeNumber
        
        let names = ("You", "Them")
        
        let player1Strokes = session.gameData.shots
        let player2Strokes = session.gameData.opponentShots

        if let winner = session.gameData.winner {
            switch winner {
            case .you:
                AudioPlayer.main.play("winGame", ofType: "wav")
            case .them:
                AudioPlayer.main.play("gameOver")
            case .tie:
                break
            }
        }
        
        let pars = [Int](repeatElement(3, count: 9))
        
        let removalDuration: TimeInterval = 1
        removeSettings(duration: removalDuration)
        removeHUD(duration: removalDuration)
        
        scene.preScorecardTearDown()
        
        let when = DispatchTime.now() + 0.6
        DispatchQueue.main.asyncAfter(deadline: when) { 
            self.scene.showScorecard(hole: hole, names: names, player1Strokes: player1Strokes, player2Strokes: player2Strokes, pars: pars) {
                
                self.scene.postScorecardTearDown()
                
                guard let message = PuttMessageWriter(data: session.dictionary,
                                                      session: session.messageSession)?.message else { return }
                let activeConversation = (self.messageSender as? MSMessagesAppViewController)?.activeConversation
                let layout = PuttMessageLayoutBuilder(session: session, conversation: activeConversation).generateLayout()
                
                self.messageSender?.send(message: message, layout: layout, completionHandler: nil)
                
                self.orientationManager?.requestPresentationStyle(.compact)
                
                self.showGameViewControllerViews()
                
                let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                let remove = SKAction.run {
                    self.sceneView.presentScene(nil)
                    self.scene = nil
                }
                self.scene.run(SKAction.sequence([fadeOut, remove]))
            }
        }
    }
    
    func generateSession() -> PuttSession {
        let strokes = scene.shots.count
        
        var shots = [strokes]
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
