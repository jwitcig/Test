//
//  CourseSelectionViewController.swift
//  MrPutt
//
//  Created by Developer on 1/1/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import UIKit

import Cartography

class CourseSelectionViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    let contentView = UIView()
    
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
            $0.height >= $1.height
        }
        
//        view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "carbon_fibre"))
        
        let playBlock = {
            
        }
        
        let frost = CoursePreviewView.create()
        frost.courseName = "Frost"
        frost.courseHoleCount = 9
        frost.backgroundImage = #imageLiteral(resourceName: "whiteout_preview_background")
        frost.playPressedBlock = playBlock
        
        let blaze = CoursePreviewView.create()
        blaze.courseName = "Blaze"
        blaze.courseHoleCount = 9
        blaze.backgroundImage = #imageLiteral(resourceName: "blaze_preview_background")
        blaze.playPressedBlock = playBlock
        
        let timber = CoursePreviewView.create()
        timber.courseName = "Timber"
        timber.courseHoleCount = 9
        timber.backgroundImage = #imageLiteral(resourceName: "test")
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
                $0.bottom == $1.bottom
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
