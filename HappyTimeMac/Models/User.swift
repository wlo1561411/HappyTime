//
//  User.swift
//  HappyTimeMac
//
//  Created by Wesley on 2022/1/17.
//

import Foundation

struct User: Identifiable, Codable {
    
    var id: String
    var name: String
    var password: String
    
}
