//
//  ShotToken.swift
//  MrPutt
//
//  Created by Developer on 1/15/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import SpriteKit

class ShotToken: SKSpriteNode {
    
    static func image(forShots shots: Int, onPar par: Int) -> UIImage? {
        if shots == 1 {
            return #imageLiteral(resourceName: "Ace")
        } else if shots == par - 2 {
            return #imageLiteral(resourceName: "Eagle")
        } else if shots == par - 1 {
            return #imageLiteral(resourceName: "Birdie")
        }
        return nil
    }
    
    init?(forShots shots: Int, onPar par: Int) {
        guard let image = ShotToken.image(forShots: shots, onPar: par) else { return nil }
        super.init(texture: SKTexture(image: image),
                     color: .clear,
                      size: CGSize(width: 80, height: 80))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
