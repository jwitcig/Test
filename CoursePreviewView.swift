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
    
    var playPressedBlock: ()->Void = { }
    
    var courseName: String {
        get { return courseNameLabel.text ?? "" }
        set { courseNameLabel.text = newValue }
    }
    
    var courseHoleCount: Int {
        get { return courseHoleCountLabel.text?.int ?? 0 }
        set { courseHoleCountLabel.text = newValue.string! }
    }
    
    var backgroundImage: UIImage? {
        get { return imageView.image }
        set { imageView.image = newValue }
    }
    
    var fontShadowColor: UIColor? {
        get { return nil }
        set {
            courseNameLabel.shadowColor = newValue
            courseHoleCountLabel.shadowColor = newValue
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        layer.cornerRadius = 14
        layer.masksToBounds = true
    }
    
    static func create() -> CoursePreviewView {
        let bundle = Bundle(for: CoursePreviewView.self)
        let preview = bundle.loadNibNamed("CoursePreviewView", owner: nil, options: nil)!.first! as! CoursePreviewView
        
        preview.playButton.setImage(#imageLiteral(resourceName: "PlayButton"), for: [.selected, .highlighted])
        return preview
    }
    
    @IBAction func playPressed(sender: Any) {
        playPressedBlock()
    }
}
