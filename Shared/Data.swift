//
//  Data.swift
//  MrPutt
//
//  Created by Developer on 1/3/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import Foundation
import SpriteKit

class Action {
    enum Name: String {
        case wallHit = "Ball hits wall"
    }
    
    static var actions: NSDictionary? = {
        guard let path = Bundle.main.path(forResource: "Actions", ofType: "plist") else { return nil }
        return NSDictionary(contentsOfFile: path)
    }()
    
    static func key(for action: Action.Name) -> String {
        return actions?[action.rawValue] as? String ?? ""
    }
    
    static func with(name: Action.Name) -> SKAction {
        return SKAction(named: key(for: name))!
    }
}
