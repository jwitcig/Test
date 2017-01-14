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
import iMessageTools

class MessagesViewController: MSMessagesAppViewController {
    fileprivate var courseController: CourseSelectionViewController?
    fileprivate var gameController: GameViewController?
    
    var isAwaitingResponse = false
    
    var messageCancelled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func willBecomeActive(with conversation: MSConversation) {
        if let message = conversation.selectedMessage {
            handleStarterEvent(message: message, conversation: conversation)
        } else {
            let controller = createCourseSelectionController()
            courseController = controller
            present(controller)
        }
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
    
    override func viewWillDisappear(_ animated: Bool) {
        let controllers: [UIViewController?] = [
            courseController, gameController
        ]
        controllers.forEach {
            if let controller = $0 {
                throwAway(controller: controller)
            }
        }
        
        let icon = UIImageView(image: #imageLiteral(resourceName: "LogoForCollapsedViewController"))
        icon.contentMode = .scaleAspectFit
        view.addSubview(icon)
        
        constrain(icon, view) {
            $0.center == $1.center
            $0.size == $1.size
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
        
        isAwaitingResponse = false
        
        gameController = createGameController(fromReader: reader, course: reader.session.initial.course)
        present(gameController!)
    }
    
}

extension MessagesViewController: MessageSender { }
