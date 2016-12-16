//
//  GameData.swift
//  testGolf
//
//  Created by Developer on 12/16/16.
//  Copyright © 2016 CodeWithKenny. All rights reserved.
//

import Foundation
import GameplayKit
import Messages
import SceneKit

import Game
import iMessageTools
import JWSwiftTools

struct Shot {
    let power: Float
    let angle: Float
    let position: SCNVector3
}

class Putt: Game, TypeConstraint {
    typealias Session = PuttSession
    typealias SceneType = SCNScene
    
    static let GameName = "Putt"
    
    let initial: PuttInitialData
    
    let padding: Padding?
    
    let lifeCycle: LifeCycle
    
    let previousSession: PuttSession?
    
    var shots: [Shot] = []

    init(previousSession: PuttSession?,
         initial: PuttInitialData?,
         padding: Padding?,
         cycle: LifeCycle) {
        
        self.initial = initial ?? PuttInitialData.random()
        
        self.padding = padding
        
        self.lifeCycle = cycle
        
        self.previousSession = previousSession
    }
    
    func start() {
        lifeCycle.start()
    }
    
    func finish() {
        lifeCycle.finish()
    }
    
    func shotTaken(shot: Shot) {
        shots.append(shot)
    }
}

struct PuttSession: SessionType, StringDictionaryRepresentable, Messageable {
    typealias Constraint = Putt
    typealias InitialData = PuttInitialData
    typealias InstanceData = PuttInstanceData
    typealias MessageWriterType = PuttMessageWriter
    typealias MessageLayoutBuilderType = PuttMessageLayoutBuilder
    
    typealias Scene = SCNScene
    
    let initial: InitialData
    let instance: InstanceData
    
    let ended: Bool
    
    let messageSession: MSSession?
    
    var dictionary: [String : String] {
        return instance.dictionary.merged(initial.dictionary).merged(["ended" : ended.string!])
    }
    
    public init(instance: InstanceData, initial: InitialData, ended: Bool = false, messageSession: MSSession?) {
        self.instance = instance
        self.initial = initial
        
        self.ended = ended
        
        self.messageSession = messageSession
    }
    
    public init?(dictionary: [String: String]) {
        guard let instance = InstanceData(dictionary: dictionary) else { return nil }
        guard let initial = InitialData(dictionary: dictionary) else { return nil }
        guard let ended = dictionary["ended"]?.bool else { return nil }
        
        self.instance = instance
        self.initial = initial
        
        self.ended = ended
        
        self.messageSession = nil
    }
}

extension PuttSession {
    var gameData: PuttInstanceData {
        return instance
    }
}

struct PuttInstanceData: InstanceDataType, StringDictionaryRepresentable {
    typealias Constraint = Putt
    
    let shots: [Int]
    let opponentShots: [Int]
    let winner: Team.OneOnOne?
    
    var dictionary: [String: String] {
        let shotsString = shots.reduce("") {$0 + "\($1)."}
        let opponentShotsString = opponentShots.reduce("") {$0 + "\($1)."}
        return [
            "instance-shots": shotsString,
            "instance-opponentShots": opponentShotsString,
            "instance-winner": winner?.rawValue ?? "incomplete",
        ]
    }
    
    init(shots: [Int], opponentShots: [Int]? = nil, winner: Team.OneOnOne?) {
        self.shots = shots
        self.opponentShots = opponentShots ?? []
        self.winner = winner
    }
    
    init?(dictionary: [String: String]) {
        guard let shots = dictionary["instance-shots"] else { return nil }
        guard let opponentShots = dictionary["instance-opponentShots"] else { return nil }
        guard let winner = dictionary["instance-winner"] else { return nil }
        
        let shotsList = shots.characters.split(separator: ".").map{String($0).int!}
        let opponentShotsList = opponentShots.characters.split(separator: ".").map{String($0).int!}
        
        self.init(shots: shotsList, opponentShots: opponentShotsList, winner: Team.OneOnOne(rawValue: winner))
    }
}

struct PuttInitialData: InitialDataType, StringDictionaryRepresentable {
    typealias Constraint = Putt
    
    let holeNumber: Int
    let holeSet: [Int]
    
    var dictionary: [String: String] {
        return [
            "initial-holeNumber": holeNumber.string!,
            "initial-holeSet": holeSet.map(String.init).joined(separator: ","),
        ]
    }
    
    init(holeNumber: Int, holeSet: [Int]) {
        self.holeNumber = holeNumber
        self.holeSet = holeSet
    }
    
    init?(dictionary: [String: String]) {
        guard let holeNumber = dictionary["initial-holeNumber"]?.int else { return nil }
        guard let holeSetString = dictionary["initial-holeSet"] else { return nil }
        let holeSet = holeSetString.components(separatedBy: ",").map{$0.int!}
        self.init(holeNumber: holeNumber, holeSet: holeSet)
    }
    
    static func random() -> PuttInitialData {
        return PuttInitialData(holeNumber: 1, holeSet: Array(1...9))
    }
}

struct PuttMessageReader: MessageReader, SessionSpecific {
    typealias SessionConstraint = PuttSession
    
    var message: MSMessage
    var data: [String: String]
    
    var session: SessionConstraint!
    
    init() {
        self.message = MSMessage()
        self.data = [:]
    }
    
    mutating func isValid(data: [String : String]) -> Bool {
        guard let ended = data["ended"]?.bool else { return false }
        guard let instance = SessionConstraint.InstanceData(dictionary: data) else { return false }
        guard let initial = SessionConstraint.InitialData(dictionary: data) else { return false }
        self.session = PuttSession(instance: instance, initial: initial, ended: ended, messageSession: message.session)
        return true
    }
}

struct PuttMessageWriter: MessageWriter {
    var message: MSMessage
    var data: [String: String]
    
    init() {
        self.message = MSMessage()
        self.data = [:]
    }
    
    func isValid(data: [String : String]) -> Bool {
        guard let _ = data["ended"]?.bool else { return false }
        guard let _ = data["initial-holeNumber"]?.int else { return false }
        guard let _ = data["initial-holeSet"] else { return false }
        guard let _ = data["instance-shots"] else { return false }
        guard let _ = data["instance-opponentShots"] else { return false }
        guard let _ = data["instance-winner"] else { return false }
        return true
    }
}

struct PuttMessageLayoutBuilder: MessageLayoutBuilder {
    let session: PuttSession
    init(session: PuttSession) {
        self.session = session
    }
    
    func generateLayout() -> MSMessageTemplateLayout {
        let layout = MSMessageTemplateLayout()
        layout.image = UIImage(named: "MessageImage")
        layout.caption = "Your turn."
        
        let winners = ["😀", "😘", "😏", "😎", "🤑", "😛", "😝", "😋"]
        let losers  = ["😬", "🙃", "😑", "😐", "😶", "😒", "🙄", "😳", "😞", "😠", "☹️"]
        
        if let winner = session.instance.winner {
            
            switch winner {
            case .you:
                let randomIndex = GKRandomDistribution(lowestValue: 0, highestValue: winners.count-1).nextInt()
                layout.caption = "I won! " + winners[randomIndex]
            case .them:
                let randomIndex = GKRandomDistribution(lowestValue: 0, highestValue: losers.count-1).nextInt()
                layout.caption = "You won. " + losers[randomIndex]
            case .tie:
                layout.caption = "We tied."
            }
        }
        return layout
    }
}
