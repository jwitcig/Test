//
//  MessagesViewController.swift
//  testGolf
//
//  Created by Developer on 12/16/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import AVFoundation
import Messages
import UIKit

import Cartography
import Firebase
import FirebaseDatabase
import iMessageTools

class MessagesViewController: MSMessagesAppViewController {
    var courseController: CourseSelectionViewController?
    var gameController: GameViewController?
    
    var isAwaitingResponse = false
    
    var messageCancelled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if FIRApp.defaultApp() == nil {
            FIRApp.configure()
        }
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryAmbient, with: [.mixWithOthers])
            try session.setActive(true, with: [])
        } catch {
            print(error)
        }
        
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(AudioPlayer.playInterrupt(notification:)),
//                                               name: NSNotification.Name.AVAudioSessionInterruption,
//                                               object: session)
    }
    
    override func willBecomeActive(with conversation: MSConversation) {
        if let message = conversation.selectedMessage {
            handleStarterEvent(message: message, conversation: conversation)
        } else {
            let controller = createCourseSelectionController()
            controller.mainController = self
            courseController = controller
            present(controller)
        }
    }
    
    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        handleStarterEvent(message: message, conversation: conversation)
        
        FIRAnalytics.logEvent(withName: "OpenMessage", parameters: nil)
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        isAwaitingResponse = true
        
        FIRAnalytics.logEvent(withName: "GameSent", parameters: nil)
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        isAwaitingResponse = false
        messageCancelled = true
        if let controller = gameController {
            throwAway(controller: controller)
        }
        
        FIRAnalytics.logEvent(withName: "SendCancelled", parameters: nil)
    }
    
    fileprivate func showWaitingForOpponent() {
        if let controller = gameController {
            throwAway(controller: controller)
        }
        if let controller = courseController {
            throwAway(controller: controller)
        }
        
        let controller = createGameController()
        gameController = controller
        
        present(controller)
        
        FIRAnalytics.logEvent(withName: "WaitingScreenShown", parameters: nil)
    }
    
    func createGameController(fromReader reader: PuttMessageReader? = nil, course: CoursePack.Type? = nil) -> GameViewController {
        let controller = storyboard!.instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
        controller.messageSender = self
        controller.orientationManager = self
        
        guard let parser = reader, let course = course else { return controller }
        
        controller.configureScene(previousSession: parser.session, course: course)
        return controller
    }
    
    func createCourseSelectionController() -> CourseSelectionViewController {
        let controller = storyboard!.instantiateViewController(withIdentifier: "CourseSelectionViewController") as! CourseSelectionViewController
        controller.messageSender = self
        controller.orientationManager = self
        return controller
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        
        switch presentationStyle {
            
        case .compact:
            let params = [
                "game_finished": (gameController?.gameCompleted ?? true) as NSObject
            ]
            FIRAnalytics.logEvent(withName: "AppCollapsed", parameters: params)
            
        case .expanded:
            break
        }
        
    }
}

extension MessagesViewController: iMessageCycle {
    func handleStarterEvent(message: MSMessage, conversation: MSConversation) {
        if let controller = gameController {
            throwAway(controller: controller)
        }
        
        if let controller = courseController {
            throwAway(controller: controller)
        }
        
        guard !MSMessage.isFromCurrentDevice(message: message, conversation: conversation) else {
            showWaitingForOpponent()
            return
        }
        
        guard let reader = PuttMessageReader(message: message) else {
            return
        }
        
        guard !reader.session.ended else {
            courseController = createCourseSelectionController()
            courseController?.mainController = self
            present(courseController!)
            return
        }
        
        isAwaitingResponse = false
        
        gameController = createGameController(fromReader: reader, course: reader.session.initial.course)
        present(gameController!)
    }
    
}

extension MessagesViewController: MessageSender { }
