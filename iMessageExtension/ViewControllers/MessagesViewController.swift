//
//  MessagesViewController.swift
//  testGolf
//
//  Created by Developer on 12/16/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import Messages
import UIKit

import iMessageTools

class MessagesViewController: MSMessagesAppViewController {
    fileprivate var gameController: UIViewController?
    
    var isAwaitingResponse = false
    
    var messageCancelled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func willBecomeActive(with conversation: MSConversation) {
        if let message = conversation.selectedMessage {
            handleStarterEvent(message: message, conversation: conversation)
        } else {
            let controller = storyboard!.instantiateViewController(withIdentifier: "CourseSelectionViewController") as! CourseSelectionViewController
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
    
    fileprivate func showWaitingForOpponent() {
        
    }
    
    func createGameController(fromReader reader: PuttMessageReader?, course: CoursePack.Type) -> GameViewController {
        let controller = storyboard!.instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
        controller.configureScene(previousSession: reader?.session, course: course)
        return controller
    }
}

extension MessagesViewController: iMessageCycle {
    func handleStarterEvent(message: MSMessage, conversation: MSConversation) {
        if let controller = gameController {
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
