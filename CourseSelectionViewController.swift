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
    
    @IBOutlet weak var contentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "carbon_fibre"))
        
        let frost = CoursePreviewView.create()
        frost.courseName = "Frost"
        frost.courseHoleCount = 9
        frost.backgroundImage = #imageLiteral(resourceName: "whiteout_preview_background")
        frost.fontShadowColor = UIColor(red: 74/255.0, green: 104/255.0, blue: 168/255.0, alpha: 0.5)
        
        let blaze = CoursePreviewView.create()
        blaze.courseName = "Blaze"
        blaze.courseHoleCount = 9
        blaze.backgroundImage = #imageLiteral(resourceName: "blaze_preview_background")
        blaze.fontShadowColor = UIColor(red: 64/255.0, green: 41/255.0, blue: 19/255.0, alpha: 0.5)

        let timber = CoursePreviewView.create()
        timber.courseName = "Timber"
        timber.courseHoleCount = 9
        timber.backgroundImage = #imageLiteral(resourceName: "test")

//        timber.backgroundImage = #imageLiteral(resourceName: "timber_preview_background")
        timber.fontShadowColor = UIColor(red: 20/255.0, green: 40/255.0, blue: 3/255.0, alpha: 0.5)
        
        let previews = [
            frost,
            blaze,
            timber,
        ]
        
        let height: CGFloat = 100
        let verticalSpacing: CGFloat = 10
        for (index, preview) in previews.enumerated() {
            contentView.addSubview(preview)
            constrain(preview, contentView) {
                $0.width == $1.width * 0.9
                $0.height == height
                
                $0.top == $1.top + (verticalSpacing + height) * CGFloat(index)
                
                $0.centerX == $1.centerX
            }
        }
    }
    
}
