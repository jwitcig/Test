//
//  EntityManager.swift
//  MrPutt
//
//  Created by Developer on 1/22/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import GameplayKit
import SpriteKit

class EntityManager {

    var entities: [GKEntity] = []
    
    let world: SKNode
    
    init(world: SKNode) {
        self.world = world
    }
    
    func add(entity: GKEntity) {
        entities.append(entity)
        if let visual = entity.component(ofType: RenderComponent.self) {
            world.addChild(visual.node)
        }
    }
    
    func remove(entity: GKEntity) {
        if let index = entities.index(of: entity) {
            entities.remove(at: index)
        }
        
        if let visual = entity.component(ofType: RenderComponent.self), let _ = visual.parent {
            visual.node.removeFromParent()
        }
    }
}
