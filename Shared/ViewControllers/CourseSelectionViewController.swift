//
//  CourseSelectionViewController.swift
//  MrPutt
//
//  Created by Developer on 1/1/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import UIKit

import iMessageTools

import Cartography

class CourseSelectionViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    let contentView = UIView()
    
    var messageSender: MessageSender?
    var orientationManager: OrientationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(contentView)
        constrain(contentView, scrollView) {
            $0.leading == $1.leading
            $0.trailing == $1.trailing
            $0.top == $1.top
            $0.bottom == $1.bottom
            
            $0.width == $1.width
        }
        
        let playBlock: (CoursePack.Type)->Void = { course in
            let controller = self.storyboard!.instantiateViewController(withIdentifier: "GameViewController") as! GameViewController
            
            controller.messageSender = self.messageSender
            controller.orientationManager = self.orientationManager
            controller.configureScene(previousSession: nil, course: course)
            self.present(controller)
        }
        
        let frost = CoursePreviewView.create(course: Frost.self as CoursePack.Type)
        frost.playPressedBlock = playBlock
        
        let blaze = CoursePreviewView.create(course: Blaze.self)
        blaze.playPressedBlock = playBlock
        
        let timber = CoursePreviewView.create(course: Timber.self)
        timber.playPressedBlock = playBlock
        
        let previews = [
            frost,
            blaze,
            timber,
        ]
        
        previews.forEach(contentView.addSubview)
        
        if let first = previews.first {
            constrain(first, contentView) {
                $0.width == $1.width * 0.9
                $0.height == 100

                $0.top == $1.top + 65
                
                $0.centerX == $1.centerX
            }
        }
        
        if let last = previews.last {
            constrain(last, contentView) {
                $0.bottom == $1.bottom + 20
            }
        }
        
        for (index, preview) in previews[0..<previews.count].enumerated() {
            if (0..<previews.count).contains(index-1) {
                let previous = previews[index-1]
                
                constrain(preview, previous) {
                    $0.width == $1.width
                    $0.height == $1.height
                    
                    $0.top == $1.bottom + 20
                    $0.centerX == $1.centerX
                }
            }
        }
    }
    
}
