//
//  UserSettings.swift
//  MrPutt
//
//  Created by Developer on 1/21/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import Foundation

class UserSettings {
    static var context = 0
    
    static let current = UserSettings()
    
    private let store = UserDefaults.standard
    
    var isMusicEnabled: Bool {
        get { return value(forOption: .gameMusic, withDefault: true) }
        set { set(value: newValue, forOption: .gameMusic) }
    }
    
    var isEffectsEnabled: Bool {
        get { return value(forOption: .effects, withDefault: true) }
        set { set(value: newValue, forOption: .effects) }
    }
    
    func value<T>(forOption option: Options, withDefault defaultValue: T) -> T {
        return store.value(forKey: option.rawValue) as? T ?? defaultValue
    }
    
    func set(value: Any?, forOption option: Options) {
        return store.set(value, forKey: option.rawValue)
    }
}
