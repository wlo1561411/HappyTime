//
//  WebService.swift
//  HappyTime
//
//  Created by Finn Wu on 2021/8/19.
//

import Foundation
import SwiftSoup
import Combine

class WebService {
    
    static let shareInstance = WebService()
    
    private let loginDomain = "https://cloud.nueip.com/login/index/param"
    private let clockDomain = "https://cloud.nueip.com/time_clocks/ajax"
    private let attendanceDomain = "https://cloud.nueip.com/attendance_record/ajax"
    
    func login(code: String,
               account: String,
               password: String,
               completion: @escaping ((Bool, String?) -> Void)) {
        
        guard let request = buildFormDataRequest(
                urlString: loginDomain,
                from:  [
                    "inputCompany": code,
                    "inputID": account,
                    "inputPassword": password
                ])
        else {
            completion(false, nil)
            return
        }
                        
        URLSession
            .shared
            .dataTask(with: request) { [weak self] data, response, error in
                
                guard let data = data,
                      let token = self?.parseLoginToken(from: data) else {
                    completion(false, nil)
                    return
                }
                
                completion(true, token)
        }
        .resume()
    }
    
    func clock(_ type: ClockType,
               token: String?,
               latitude: Double,
               longitude: Double,
               completion: @escaping ((Bool, String?) -> Void)) {
        
        guard let token = token,
              let request = buildFormDataRequest(
                urlString: clockDomain,
                from:  [
                    "action": "add",
                    "id": type.param,
                    "token": token,
                    "lat": latitude,
                    "lng": longitude
                ])
        else {
            completion(false, nil)
            return
        }
        
        URLSession
            .shared
            .dataTask(with: request) { data, response, error in
                
                guard let data = data,
                      let clockResponse = try? JSONDecoder().decode(ClockResponse.self, from: data) else {
                    completion(false, nil)
                    return
                }
                
                completion(clockResponse.isSuccess, clockResponse.message)
        }
        .resume()
    }
    
    func login(code: String,
               account: String,
               password: String) -> AnyPublisher<String?, Error>? {
        
        guard let request = buildFormDataRequest(
                urlString: loginDomain,
                from:  [
                    "inputCompany": code,
                    "inputID": account,
                    "inputPassword": password
                ])
        else {
            return nil
        }
        
        return URLSession
            .shared
            .dataTaskPublisher(for: request)
            .print("Login API")
//            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .tryMap(handleOutput)
            .map{ self.parseLoginToken(from: $0) }
            .eraseToAnyPublisher()
    }
    
    func clock(_ type: ClockType,
               token: String?,
               latitude: Double,
               longitude: Double) -> AnyPublisher<ClockResponse, Error>? {
        
        guard let request = buildFormDataRequest(
                urlString: clockDomain,
                from:  [
                    "action": "add",
                    "id": type.param,
                    "token": token ?? "",
                    "lat": latitude,
                    "lng": longitude
                ])
        else {
            return nil
        }
        
        return URLSession
            .shared
            .dataTaskPublisher(for: request)
            .print("Clock API")
            .receive(on: DispatchQueue.main)
            .tryMap(handleOutput)
            .decode(type: ClockResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    func getAttendance() -> AnyPublisher<String?, Error>? {
        guard let request = buildFormDataRequest(
                urlString: attendanceDomain,
                from:  [
                    "action": "attendance",
                    "loadinBatch": 1,
                    "loadBatchGroupNum": 6000,
                    "loadBatchNumber": 1,
                    "work_status": "1,4"
                ])
        else {
            return nil
        }
        
        let config = URLSession.shared.configuration
        let cookieS = HTTPCookie(properties: [.name: "Search_42_date_start", .value: "2021-08-25", .domain: "cloud.nueip.com", .path: "/"])!
        let cookieE = HTTPCookie(properties: [.name: "Search_42_date_end", .value: "2021-08-26", .domain: "cloud.nueip.com", .path: "/"])!
        
        config.httpCookieStorage?.setCookie(cookieS)
        config.httpCookieStorage?.setCookie(cookieE)
        
        let session = URLSession(configuration: config)
        
        return session
            .dataTaskPublisher(for: request)
            .print("Attendance API")
            .receive(on: DispatchQueue.main)
            .tryMap(handleOutput)
            .map{ String(data: $0, encoding: .utf8) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Other

extension WebService {
    
    func parseLoginToken(from data: Data) -> String? {
        guard let string = String(data: data, encoding: .utf8) else { return nil }
        
        var token: String?
        
        do {
            let body: Document = try SwiftSoup.parseBodyFragment(string)
            let mobileView = try body.getElementsByClass("mobile_view").array()
            
            for elemet in mobileView {
                for input in try elemet.getElementsByTag("input").array() {
                    if try input.attr("name") == "token" {
                        token = try input.val()
                    }
                }
            }
        }
        catch Exception.Error(_, let message) {
            print(message)
        }
        catch {
            print(error.localizedDescription)
        }
        
        return token
    }
    
    func handleOutput(_ output: URLSession.DataTaskPublisher.Output) throws -> Data {
        guard let httpResponse = output.response as? HTTPURLResponse,
              200 ..< 300 ~= httpResponse.statusCode
        else {
            throw URLError(.badServerResponse)
        }
        
        return output.data
    }
    
    func buildFormDataRequest(urlString: String, from formDictionary: [String: Any]) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        
        let boundary = "Boundary+\(arc4random())\(arc4random())"
        var body = Data()
        
        for item in formDictionary {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(item.key)\"\r\n\r\n")
            body.appendString("\(item.value)\r\n")
        }
        
        request.httpBody = body
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        return request
    }
}
