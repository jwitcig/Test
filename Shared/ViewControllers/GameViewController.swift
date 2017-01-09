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
    
    var toolsView = UIView()
    
    var opponentSession: PuttSession?
    
    var scene: PuttScene!
    
    var world = SKNode()
    
    var messageSender: MessageSender?
    var orientationManager: OrientationManager?
    
    lazy var settingsPane: InGameMenuView  = {
        return Bundle(for: GameViewController.self).loadNibNamed("InGameMenuView", owner: nil, options: nil)![0] as! InGameMenuView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settings = Bundle(for: GameViewController.self).loadNibNamed("SettingsButton", owner: nil, options: nil)![0] as! UIButton
        
        settings.addTarget(self, action: #selector(GameViewController.menuLaunch(sender:)), for: .touchUpInside)

        toolsView.addSubview(settings)
        
        constrain(settings, toolsView) {
            $0.bottom == $1.bottom
            $0.trailing == $1.trailing
        }
        
        view.addSubview(toolsView)
        
        constrain(toolsView, view) {
            $0.leading == $1.leading
            $0.trailing == $1.trailing
            $0.top == $1.top
            $0.bottom == $1.bottom
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
        view.subviews.filter { $0 != toolsView }
                     .forEach { $0.isHidden = true }
    }
    
    func showGameViewControllerViews() {
        view.subviews.forEach { $0.isHidden = false }
    }
    
    func menuLaunch(sender: Any) {
        if settingsPane.superview == nil {
            let blurFilter = CIFilter(name: "CIGaussianBlur")!
            let blurRadius: CGFloat = 10.0
            let blurDuration: CGFloat = 1.0
            blurFilter.setValue(0, forKey: kCIInputRadiusKey)
            
            let blurEffect = SKEffectNode()
            blurEffect.shouldEnableEffects = true
            blurEffect.filter = blurFilter
            
            let animateBlur = SKAction.customAction(withDuration: TimeInterval(blurDuration)) { node, elapsed in
                blurFilter.setValue(blurRadius * elapsed/blurDuration, forKey: kCIInputRadiusKey)
            }
            blurEffect.run(animateBlur)
            
            let blurredNode = SKSpriteNode(texture: sceneView.texture(from: scene))
            blurredNode.position = scene.camera!.position
            
            blurEffect.addChild(blurredNode)
            scene.addChild(blurEffect)
            
            settingsPane.dismissBlock = {
                
                let action = SKAction.customAction(withDuration: TimeInterval(blurDuration)) { node, elapsed in
                    blurFilter.setValue(blurRadius - blurRadius * elapsed/blurDuration, forKey: kCIInputRadiusKey)
                }
                
                let finished = SKAction.run {
                    blurEffect.removeFromParent()
                }
                
                self.scene.run(SKAction.sequence([action, finished]))
            }
            
            toolsView.addSubview(settingsPane)
            
            constrain(settingsPane, toolsView) {
                $0.width == $1.width * 0.8
                $0.height >= $1.height * 0.5
                
                $0.centerX == $1.centerX
            }
            
            let settings = UserDefaults.standard
            
            let music = createInGameOptionView()
            music.optionName = Options.gameMusic.rawValue
            music.enabled = settings.value(forKey: music.optionName) as? Bool ?? true
            
            let effects = createInGameOptionView()
            effects.optionName = "Effects"
            effects.enabled = settings.value(forKey: effects.optionName) as? Bool ?? true
            
            let hud = createInGameOptionView()
            hud.optionName = "HUD"
            hud.enabled = settings.value(forKey: hud.optionName) as? Bool ?? true
            
            settingsPane.options = [music, effects, hud]
        }
    
        if settingsPane.isVisible {
            settingsPane.dismiss()
        } else {
            settingsPane.show()
        }
    }
    
    func createInGameOptionView() -> InGameOptionView {
        return Bundle(for: InGameMenuView.self).loadNibNamed("InGameOptionView", owner: nil, options: nil)![0] as! InGameOptionView
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
