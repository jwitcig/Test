//
//  TimeKeeper.swift
//  MrPutt
//
//  Created by Developer on 1/21/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import Foundation

class ClockTimer {
    var startTime: TimeInterval? = nil
    var endTime: TimeInterval? = nil
    
    var elapsedTime: TimeInterval? {
        guard let startTime = startTime, let endTime = endTime else { return nil }
        return endTime - startTime
    }
    
    func start() {
        // cant start multiple times, maintains current value
        startTime = startTime ?? Date().timeIntervalSince1970
    }
    
    func stop() {
        // cant stop if hasnt been started
        endTime = startTime != nil ? Date().timeIntervalSince1970 : nil
    }
    
    func restart() {
        startTime = Date().timeIntervalSince1970
        endTime = nil
    }
}

class Stopwatch {
    let duration: TimeInterval
    var startTime: TimeInterval?
    
    // can be set before expiration if completed before time runs out
    var endTime: TimeInterval? = nil
    
    // time at which the duration has run out
    var runOutTime: TimeInterval? {
        guard let startTime = startTime else { return nil }
        return startTime + duration
    }
    
    var elapsedTime: TimeInterval? {
        guard let start = startTime else { return nil }
        if let end = endTime {
            return end - start
        }
        return Date().timeIntervalSince1970 - start
    }
    
    var updateLoopTimer: Timer? = nil
    var updateLoop: (()->Void)? = nil
    
    init(duration: TimeInterval, update: (()->Void)? = nil) {
        self.duration = duration
        self.updateLoop = update
    }
    
    func start() {
        // cant start multiple times, maintains current value
        startTime = startTime ?? Date().timeIntervalSince1970
        
        if let update = updateLoop {
            updateLoopTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: {_ in update()})
        }
    }
    
    func stop() {
        // cant stop if hasnt been started
        endTime = startTime != nil ? Date().timeIntervalSince1970 : nil
        updateLoopTimer?.invalidate()
        updateLoopTimer = nil
    }
    
    func restart() {
        startTime = Date().timeIntervalSince1970
        endTime = nil
        updateLoopTimer?.invalidate()
        updateLoopTimer = nil
    }
}
