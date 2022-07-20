//
//  UserDefaults+.swift
//  HappyTimeWatch WatchKit Extension
//
//  Created by Patty Chang on 20/07/2022.
//

import Foundation

extension UserDefaults {
    
    var code: String {
        get {
            guard let value = value(forKey: Key.code.rawValue) as? String
            else { return "" }
            
            return value
        }
        set {
            set(newValue, forKey: Key.code.rawValue)
        }
    }
    
    var account: String {
        get {
            guard let value = value(forKey: Key.account.rawValue) as? String
            else { return "" }
            
            return value
        }
        set {
            set(newValue, forKey: Key.account.rawValue)
        }
    }
    
    var password: String {
        get {
            guard let value = value(forKey: Key.password.rawValue) as? String
            else { return "" }
            
            return value
        }
        set {
            set(newValue, forKey: Key.password.rawValue)
        }
    }
    
    var attendance: String {
        get {
            guard let value = value(forKey: Key.attendance.rawValue) as? String
            else { return "" }
            
            return value
        }
        set {
            set(newValue, forKey: Key.attendance.rawValue)
        }
    }
}

extension UserDefaults {
    
    enum Key: String {
        case code = "keyCode"
        case account = "keyAccount"
        case password = "keyPassword"
        case attendance = "keyAttendance"
    }
}
