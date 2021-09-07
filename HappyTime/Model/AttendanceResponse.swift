//
//  AttendanceResponse.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/9/3.
//

import Foundation

// MARK: - AttendanceResponse
struct AttendanceResponse: Codable {
    let punch: Punch?
}

// MARK: - Punch
struct Punch: Codable {
    let onPunch, offPunch: [PunchElement]?
    
    var allPunches: [PunchElement] {
        (onPunch ?? []) + (offPunch ?? [])
    }
}

// MARK: - PunchElement
struct PunchElement: Codable, Hashable {
    let workTime: String
    let type: String

    var chinese: String? {
        switch type {
        case "onPunch":
            return "上班時間"
        case "offPunch":
            return "下班時間"
        default:
            return nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case workTime = "work_time"
        case type
    }
}
