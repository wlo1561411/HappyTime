//
//  File.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/8/24.
//

import Foundation

enum ClockType: String {
    case In
    case Out
    
    var param: Int {
        switch self {
        case .In:
            return 1
        case .Out:
            return 2
        }
    }
    
    var chinese: String {
        switch self {
        case .In:
            return "打上班卡"
        case .Out:
            return "打下班卡"
        }
    }
}

/**
 {
     "status": "success",
     "message": "GPS打卡成功",
     "datetime": "2021-08-24 15:59:43",
     "time": "15:59:43",
     "rulesn": "51704021",
     "display_view": false,
     "display_overtime": false
 }
 
 {
     "status": "fail",
     "message": "GPS打卡失敗（超出允許距離）"
 }
 */

struct ClockResponse: Codable {
    let status: String?
    let message: String?
    let datetime: String?
    let time: String?
    
    var isSuccess: Bool {
        if status == "success" {
            return true
        }
        else if status == "fail" {
            return false
        }
        
        return false
    }
}
