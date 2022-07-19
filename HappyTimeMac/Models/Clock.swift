//
//  Clock.swift
//  HappyTimeMac
//
//  Created by Wesley on 2022/1/18.
//

import Foundation

struct Clock {
    var documentID: String?
    var name: String
    var clock: String
    var status: Int
    
    static func empty() -> Clock {
        .init(documentID: "", name: "", clock: "", status: 0)
    }
}

extension Clock: Codable {}
