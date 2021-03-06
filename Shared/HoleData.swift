//
//  AD.swift
//  MrPutt
//
//  Created by Developer on 1/20/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import PocketSVG
import SWXMLHash

import SpriteKit

class HoleData {
    let url: URL
    let data: Data
    let xml: XMLIndexer
    
    let holeNumber: Int
    let course: CoursePack.Type
    
    lazy var size: CGSize = {
        let svg: XMLIndexer = self.xml["svg"]
        let width = try! (svg.value(ofAttribute: "width") as String).int!
        let height = try! (svg.value(ofAttribute: "height") as String).int!
        return CGSize(width: width, height: height)
    }()
    
    init(holeNumber: Int, course: CoursePack.Type) {
        self.holeNumber = holeNumber
        self.course = course
        
        let coursePrefix = course.name.lowercased()
        
        let fileName = "\(coursePrefix)Hole\(holeNumber)-\(holeNumber)"
        let bundle = Bundle(for: HoleData.self)
        self.url = bundle.url(forResource: fileName, withExtension: "svg")!
        self.data = try! Data(contentsOf: url)
        self.xml = SWXMLHash.parse(data)
    }
    
    lazy var holeLocation: CGPoint = {
        let hole = self.allIn(indexer: self.xml).filter {
            var id = ""
            do {
                id = try $0.value(ofAttribute: "id") as String
            } catch { }
            
            return id.contains("end")
            }[0]
        let x = CGFloat((try! hole.value(ofAttribute: "x") as String).double!)
        let y = CGFloat((try! hole.value(ofAttribute: "y") as String).double!)
        return CGPoint(x: x-self.size.width/2, y: -(y-self.size.height/2))
    }()
    
    lazy var ballLocation: CGPoint = {
        let ball = self.allIn(indexer: self.xml).filter {
            var id = ""
            do {
                id = try $0.value(ofAttribute: "id") as String
            } catch { }
            
            return id.contains("ball")
            }[0]
        
        let x = CGFloat((try! ball.value(ofAttribute: "x") as String).double!)
        let y = CGFloat((try! ball.value(ofAttribute: "y") as String).double!)
        return CGPoint(x: x-self.size.width/2, y: -(y-self.size.height/2))
    }()
    
    func allIn(indexer: XMLIndexer, withName name: String? = nil) -> [XMLIndexer] {
        var indexers: [XMLIndexer] = indexer.children
        
        for child in indexer.children {
            indexers.append(contentsOf: allIn(indexer: child, withName: name))
        }
        
        if let name = name {
            return indexers.filter {
                ($0.element?.name == name) == true
            }
        }
        return indexers
    }
    
    lazy var beziers: [String] = {
        let allPaths = self.allIn(indexer: self.xml, withName: "path")
        
        let strings: [String] = allPaths.map {
            $0.element!.description
        }
        
        var corrected: [String] = strings.map {
            guard let startRange = $0.range(of: "stroke=") else { return $0 }
            
            let start = $0.index(before: startRange.lowerBound)
            
            guard let end = $0.range(of: ")\"", options: .caseInsensitive, range: start..<$0.endIndex, locale: nil) else { return $0 }
            
            return $0.replacingCharacters(in: start..<end.upperBound, with: "")
        }
        
        corrected = corrected.map {
            guard let startRange = $0.range(of: "fill=") else { return $0 }
            
            let start = $0.index(before: startRange.lowerBound)
            
            guard let end = $0.range(of: ")\"", options: .caseInsensitive, range: start..<$0.endIndex, locale: nil) else { return $0 }
            
            return $0.replacingCharacters(in: start..<end.upperBound, with: "")
        }
        return corrected
    }()
    
    func parse(scene: SKScene) {
        let paths: [SVGBezierPath] = beziers.map {
            SVGBezierPath.paths(fromSVGString: $0).first! as! SVGBezierPath
        }
        
        for path in paths {
            let layer = CAShapeLayer()
            layer.path = path.cgPath
            
            let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: -size.width/2, y: -size.height/2)
            
            let pathCopy = CGMutablePath()
            pathCopy.addPath(path.cgPath, transform: transform)
            
            layer.lineWidth = 2
            layer.strokeColor = path.svgAttributes["stroke"] as! CGColor?
            layer.fillColor = path.svgAttributes["fill"] as! CGColor?
            
            let physics = SKNode()
            physics.name = "wall"
            physics.position = CGPoint(x: 0, y: 0)
            physics.physicsBody = SKPhysicsBody(edgeLoopFrom: pathCopy)
            physics.physicsBody?.isDynamic = false
            physics.physicsBody?.collisionBitMask = Category.ball.rawValue
            scene.addChild(physics)
        }
        
        var image: UIImage!
        
        switch course {
            
        case is Frost.Type:
            switch holeNumber {
            case 1:
                image = FrostStyleKit.imageOfFrostHole1
            case 2:
                image = FrostStyleKit.imageOfFrostHole2
            case 3:
                image = FrostStyleKit.imageOfFrostHole3
            case 4:
                image = FrostStyleKit.imageOfFrostHole4
            case 5:
                image = FrostStyleKit.imageOfFrostHole5
            case 6:
                image = FrostStyleKit.imageOfFrostHole6
            case 7:
                image = FrostStyleKit.imageOfFrostHole7
            case 8:
                image = FrostStyleKit.imageOfFrostHole8
            case 9:
                image = FrostStyleKit.imageOfFrostHole9
            default:
                fatalError()
            }
        case is Blaze.Type:
            switch holeNumber {
            case 1:
                image = BlazeStyleKit.imageOfBlazeHole1
            case 2:
                image = BlazeStyleKit.imageOfBlazeHole2
            case 3:
                image = BlazeStyleKit.imageOfBlazeHole3
            case 4:
                image = BlazeStyleKit.imageOfBlazeHole4
            case 5:
                image = BlazeStyleKit.imageOfBlazeHole5
            case 6:
                image = BlazeStyleKit.imageOfBlazeHole6
            case 7:
                image = BlazeStyleKit.imageOfBlazeHole7
            case 8:
                image = BlazeStyleKit.imageOfBlazeHole8
            case 9:
                image = BlazeStyleKit.imageOfBlazeHole9
            default:
                fatalError()
            }
        case is Retro.Type:
            switch holeNumber {
            case 1:
                image = RetroStyleKit.imageOfRetroHole1
            case 2:
                image = RetroStyleKit.imageOfRetroHole2
            case 3:
                image = RetroStyleKit.imageOfRetroHole3
            case 4:
                image = RetroStyleKit.imageOfRetroHole4
            case 5:
                image = RetroStyleKit.imageOfRetroHole5
            case 6:
                image = RetroStyleKit.imageOfRetroHole6
            case 7:
                image = RetroStyleKit.imageOfRetroHole7
            case 8:
                image = RetroStyleKit.imageOfRetroHole8
            case 9:
                image = RetroStyleKit.imageOfRetroHole9
            default:
                fatalError()
            }

        case is Nebula.Type:
            switch holeNumber {
            case 1:
                image = NebulaStyleKit.imageOfNebulaHole1
            case 2:
                image = NebulaStyleKit.imageOfNebulaHole2
            case 3:
                image = NebulaStyleKit.imageOfNebulaHole3
            case 4:
                image = NebulaStyleKit.imageOfNebulaHole4
            case 5:
                image = NebulaStyleKit.imageOfNebulaHole5
            case 6:
                image = NebulaStyleKit.imageOfNebulaHole6
            case 7:
                image = NebulaStyleKit.imageOfNebulaHole7
            case 8:
                image = NebulaStyleKit.imageOfNebulaHole8
            case 9:
                image = NebulaStyleKit.imageOfNebulaHole9
            default:
                fatalError()
            }
            
        default:
            fatalError()
        }
        
        let texture = SKTexture(image: image)
        
        let sprite = SKSpriteNode(texture: texture)
        sprite.zPosition = -1
        sprite.position = CGPoint(x: 0, y: 0)
        scene.addChild(sprite)
    }
}
