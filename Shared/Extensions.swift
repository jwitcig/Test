//
//  Extensions.swift
//  MrPutt
//
//  Created by Developer on 1/21/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import SpriteKit

public extension SKRange {
    public var openInterval: Range<CGFloat> {
        return lowerLimit..<upperLimit
    }
    
    public var closedInterval: ClosedRange<CGFloat> {
        return lowerLimit...upperLimit
    }
}

public extension CGPoint {
    public func angle(toPoint point: CGPoint) -> CGFloat {
        let origin = CGPoint(x: point.x - self.x, y: point.y - self.y)
        let radians = CGFloat(atan2f(Float(origin.y), Float(origin.x)))
        let corrected = radians < 0 ? radians + 2 * .pi : radians
        return corrected
    }
    
    public func distance(toPoint point: CGPoint) -> CGFloat {
        return sqrt( pow(self.x-point.x, 2) + pow(self.y - point.y, 2) )
    }
}

public extension CGVector {
    public var magnitude: CGFloat {
        return sqrt( dx*dx + dy*dy )
    }
    
    public var normalized: CGVector {
        return CGVector(dx: dx/magnitude, dy: dy/magnitude)
    }
}

public func +(vector: CGVector, vector2: CGVector) -> CGVector {
    return CGVector(dx: vector.dx+vector2.dx, dy: vector.dy+vector2.dy)
}

public func -(vector: CGVector, vector2: CGVector) -> CGVector {
    return CGVector(dx: vector.dx-vector2.dx, dy: vector.dy-vector2.dy)
}

infix operator •

public func •(vector: CGVector, vector2: CGVector) -> CGFloat {
    return vector.dx*vector2.dx + vector.dy*vector2.dy
}

public func *(vector: CGVector, scalar: CGFloat) -> CGVector {
    return CGVector(dx: vector.dx*scalar, dy: vector.dy*scalar)
}

public func /(vector: CGVector, scalar: CGFloat) -> CGVector {
    return CGVector(dx: vector.dx/scalar, dy: vector.dy/scalar)
}
