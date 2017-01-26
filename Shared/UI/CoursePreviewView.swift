//
//  CoursePreviewView.swift
//  MrPutt
//
//  Created by Developer on 1/1/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import UIKit

class CoursePreviewView: UIView {
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var courseNameLabel: UILabel!
    @IBOutlet weak private var courseHoleCountLabel: UILabel!

    @IBOutlet weak private var playButton: UIButton!
    
    var course: CoursePack.Type!
    
    var playPressedBlock: (CoursePack.Type)->Void = { _ in }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        layer.cornerRadius = 14
        layer.masksToBounds = true
    }
    
    static func create(course: CoursePack.Type) -> CoursePreviewView {
        let bundle = Bundle(for: CoursePreviewView.self)
        let preview = bundle.loadNibNamed("CoursePreviewView", owner: nil, options: nil)!.first! as! CoursePreviewView
        preview.course = course
        
        preview.courseNameLabel.text = course.name
        preview.courseHoleCountLabel.text = course.holeCount.string! + " Holes"
        preview.imageView.image = course.previewImage
        
        preview.playButton.setImage(#imageLiteral(resourceName: "play"), for: [.selected, .highlighted])
        return preview
    }
    
    @IBAction func playPressed(sender: Any) {
        playPressedBlock(course)
    }
}
