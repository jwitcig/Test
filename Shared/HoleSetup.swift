//
//  HoleSetup.swift
//  MrPutt
//
//  Created by Developer on 1/1/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import Foundation
import SpriteKit

protocol CoursePack {
    static var name: String { get }
    static var holeCount: Int { get }
    static var previewImage: UIImage { get }
}

struct Course {
    static func with(name: String) -> CoursePack.Type? {
        let packs: [CoursePack.Type] = [
            Frost.self,
            Blaze.self,
            Retro.self,
            Nebula.self,
        ]
        return packs.filter { $0.name == name }.first
    }
}

struct Frost: CoursePack {
    static let name = "Frost"
    static let holeCount = 9
    static let previewImage = #imageLiteral(resourceName: "frostPreview")
}

struct Blaze: CoursePack {
    static let name = "Blaze"
    static let holeCount = 9
    static let previewImage = #imageLiteral(resourceName: "blazePreview")
}

struct Retro: CoursePack {
    static let name = "Retro"
    static let holeCount = 9
    static let previewImage = #imageLiteral(resourceName: "retroPreview")
}

struct Nebula: CoursePack {
    static let name = "Nebula"
    static let holeCount = 9
    static let previewImage = #imageLiteral(resourceName: "nebulaPreview")
}

class HoleSetup {
    static func setup(_ scene: PuttScene, forHole hole: Int, inCourse course: CoursePack.Type) {

        let music = AudioPlayer()
        scene.audio.backgroundMusic = music
        music.play("Too Cool")
        scene.audio.backgroundMusic?.volume = 0.2

        if !UserSettings.current.isMusicEnabled {
            music.pause()
        }
        
        let holeSize = HoleData(holeNumber: hole, course: course).size
        
        switch course {
            
        case is Frost.Type:
    
            if let snow = SKEmitterNode(fileNamed: "Snow") {
                let density = snow.particleBirthRate / snow.particlePositionRange.dy
                snow.position = CGPoint(x: holeSize.width, y: 0)
                snow.particlePositionRange = CGVector(dx: 0, dy: holeSize.height)
                snow.particleBirthRate = density * snow.particlePositionRange.dy
                snow.advanceSimulationTime(TimeInterval(snow.particleLifetime))
                scene.addChild(snow)
            }
            
            switch hole {
            default:
                break
            }
            
        case is Blaze.Type:
            
            switch hole {
            default:
                break
            }
            case is Retro.Type:
            
            
            switch hole {
            default:
                break
            }
            
        case is Nebula.Type:

            if let smallAsteroids = SKEmitterNode(fileNamed: "AsteroidSmall") {
                let density = smallAsteroids.particleBirthRate / smallAsteroids.particlePositionRange.dy
                
                smallAsteroids.position = CGPoint(x: -holeSize.width, y: 0)
                smallAsteroids.particlePositionRange = CGVector(dx: 0, dy: holeSize.height*2)
                smallAsteroids.particleBirthRate = density * smallAsteroids.particlePositionRange.dy
                smallAsteroids.advanceSimulationTime(TimeInterval(smallAsteroids.particleLifetime))
                scene.addChild(smallAsteroids)
            }
            
            if let largeAsteroids = SKEmitterNode(fileNamed: "AsteroidLarge") {
                let density = largeAsteroids.particleBirthRate / largeAsteroids.particlePositionRange.dy
                
                largeAsteroids.position = CGPoint(x: -holeSize.width, y: 0)
                largeAsteroids.particlePositionRange = CGVector(dx: 0, dy: holeSize.height*2)
                largeAsteroids.particleBirthRate = density * largeAsteroids.particlePositionRange.dy
                largeAsteroids.advanceSimulationTime(TimeInterval(largeAsteroids.particleLifetime))
                scene.addChild(largeAsteroids)
            }
            
            switch hole {
            default:
                break
            }

        default:
            fatalError("fatal error: unimplemented course pack")
        
        }
    }
}

class HoleInfo {
    
    static let parsDefault = 3
    
    static func par(forHole hole: Int, in course: CoursePack.Type) -> Int {
        guard let path = Bundle.main.path(forResource: "HolePars", ofType: "plist") else {
            return HoleInfo.parsDefault
        }
        guard let allPars = NSDictionary(contentsOfFile: path) else {
            return HoleInfo.parsDefault
        }
        guard let coursePars = allPars[course.name] as? Array<Int> else {
            return HoleInfo.parsDefault
        }
        return coursePars[safe: hole] ?? HoleInfo.parsDefault
    }
}

