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
            Timber.self,
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

struct Timber: CoursePack {
    static let name = "Timber"
    static let holeCount = 9
    static let previewImage = #imageLiteral(resourceName: "timberPreview")
}

struct Nebula: CoursePack {
    static let name = "Nebula"
    static let holeCount = 9
    static let previewImage = #imageLiteral(resourceName: "nebulaPreview")
}

class HoleSetup {
    static func setup(_ scene: PuttScene, forHole hole: Int, inCourse course: CoursePack.Type) {

        let settings = UserDefaults.standard
        
        let music = AudioPlayer()
        music.play("HoleMusic")

        scene.audio.backgroundMusic = music
        
        let isMusicOn = settings.value(forKey: Options.gameMusic.rawValue) as? Bool ?? true
        if !isMusicOn {
            music.pause()
        }
        
        switch course {
            
        case is Frost.Type:
    
            if let snow = SKEmitterNode(fileNamed: "Snow") {
                snow.position = CGPoint(x: 400, y: 0)
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
            
        case is Timber.Type:
            
            switch hole {
            default:
                break
            }
            
        case is Nebula.Type:
            
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
    
    let number: Int
    let course: CoursePack.Type
    
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
    
    init(holeNumber: Int, course: CoursePack.Type) {
        self.number = holeNumber
        self.course = course
    }
}
