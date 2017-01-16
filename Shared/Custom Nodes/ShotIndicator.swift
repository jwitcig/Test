//
//  ShotIndicator.swift
//  MrPutt
//
//  Created by Developer on 1/13/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import SpriteKit

extension UIColor {
    var r: CGFloat {
        return cgColor.components?[0] ?? 0
    }
    var g: CGFloat {
        return cgColor.components?[1] ?? 0
    }
    var b: CGFloat {
        return cgColor.components?[2] ?? 0
    }
}

class ShotIndicator: SKNode { }
