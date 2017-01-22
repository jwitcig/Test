//
//  Structs.swift
//  MrPutt
//
//  Created by Developer on 1/21/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import UIKit

struct Shot {
    let power: CGFloat
    let angle: CGFloat
    let position: CGPoint
    
    var stroke: CGVector {
        return CGVector(dx: cos(angle) * power,
                        dy: sin(angle) * power)
    }
}
