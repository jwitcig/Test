//
//  MessagesViewController.swift
//  testGolf
//
//  Created by Developer on 12/16/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

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
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        isAwaitingResponse = true
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        isAwaitingResponse = false
        messageCancelled = true
        if let controller = gameController {
            throwAway(controller: controller)
        }
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
            if let controller = gameController {
                controller.tearDown()
                throwAway(controller: controller)
                gameController = nil
            }
            
            if let controller = courseController {
                throwAway(controller: controller)
                courseController = nil
            }
            
            let controller = createCourseSelectionController()
            controller.mainController = self
            courseController = controller
            present(controller)

        default:
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
