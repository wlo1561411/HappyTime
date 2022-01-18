//
//  Clock.swift
//  HappyTimeMac
//
//  Created by Wesley on 2022/1/18.
//

import Foundation

struct Clock: Codable {
    var name: String
    var clock: String
    var expired: Bool
    var queue: Bool
}
