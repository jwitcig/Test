//
//  Extensions.swift
//  MrPutt
//
//  Created by Developer on 1/15/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import Foundation
import SpriteKit

public extension SKRange {
    public var openInterval: Range<CGFloat> {
        return lowerLimit..<upperLimit
    }
    
    public var closedInterval: ClosedRange<CGFloat> {
        return lowerLimit...upperLimit
    }
}
