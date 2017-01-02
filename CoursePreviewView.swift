//
//  CoursePreviewView.swift
//  MrPutt
//
//  Created by Developer on 1/1/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import UIKit

class CoursePreviewView: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var courseNameLabel: UILabel!
    
    var courseName: String {
        get { return courseNameLabel.text ?? "" }
        set { courseNameLabel.text = courseName }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
