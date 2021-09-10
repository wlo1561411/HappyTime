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
    
    enum ApiType {
        case login
        case clock(type: ClockType)
        case attendance
        
        /// This thing should belong viewModel?
        var title: String {
            switch self {
            case .login:
                return "登入"
            case .clock(let type):
                return type.chinese
            case .attendance:
                return "讀取出勤紀錄"
            }
        }
    }
    
    enum WebServiceError: Error {
        case invalidURL(error: URLError)
        case invalidSession
        case invalidToken
        case invalidValue
        case httpResponseFail(response: HTTPURLResponse)
        case httpResponseError
        case requestFail(error: Error)
        
        /// This thing should belong viewModel?
        var message: String {
            switch self {
            case .invalidURL(_):
                return "請檢查輸入欄位。"
            case .invalidSession,
                 .invalidToken,
                 .invalidValue,
                 .httpResponseFail(_),
                 .httpResponseError,
                 .requestFail(_):
                return "請稍後再次嘗試或重新登入。"
            }
        }
    }
    
    static let shareInstance = WebService()
    
    private let host = "cloud.nueip.com"
}

// MARK: - Combine

extension WebService {
    
    func login(code: String,
               account: String,
               password: String) -> AnyPublisher<String, WebServiceError> {
        
        Just([
            "inputCompany": code,
            "inputID": account,
            "inputPassword": password
        ])
        .print("Login API")
        .tryMap { [weak self] dictionary -> URLRequest in
            guard let self = self else { throw WebServiceError.invalidURL(error: URLError(.badURL)) }
            return self.buildFormDataRequest(
                url: try self.buildURL(from: .login),
                from: dictionary
            )
        }
        .map {
            URLSession
                .shared
                .dataTaskPublisher(for: $0)
        }
        .flatMap{ $0.mapError { $0 as Error } }
        .tryMap(handleOutput(_:))
        .tryMap(parseLoginToken(from:))
        .mapError { $0 as? WebServiceError ?? WebServiceError.requestFail(error: $0) }
        .eraseToAnyPublisher()
    }
    
    func clock(_ type: ClockType,
               token: String,
               latitude: Double,
               longitude: Double) -> AnyPublisher<ClockResponse, WebServiceError> {
        
        Just([
            "action": "add",
            "id": type.param,
            "token": token ,
            "lat": latitude,
            "lng": longitude
        ])
        .print("Clock API")
        .tryMap { [weak self] dictionary -> URLRequest in
            guard let self = self else { throw WebServiceError.invalidURL(error: URLError(.badURL)) }
            return self.buildFormDataRequest(
                url: try self.buildURL(from: .clock(type: type)),
                from: dictionary
            )
        }
        .map {
            URLSession
                .shared
                .dataTaskPublisher(for: $0)
        }
        .flatMap{ $0.mapError { $0 as Error } }
        .tryMap(handleOutput(_:))
        .decode(type: ClockResponse.self, decoder: JSONDecoder())
        .mapError { $0 as? WebServiceError ?? WebServiceError.requestFail(error: $0) }
        .eraseToAnyPublisher()
    }
    
    func getAttendance() -> AnyPublisher<AttendanceResponse, WebServiceError> {
        
        Just([
            "action": "attendance",
            "loadinBatch": 1,
            "loadBatchGroupNum": 6000,
            "loadBatchNumber": 1,
            "work_status": "1,4"
        ])
        .print("Attendance API")
        .tryMap { [weak self] dictionary -> URLSession.DataTaskPublisher in
            guard let self = self else { throw WebServiceError.invalidURL(error: URLError(.badURL)) }
            return try self.createAttendanceSession()
                .dataTaskPublisher(
                    for: self.buildFormDataRequest(
                        url: try self.buildURL(from: .attendance),
                        from: dictionary
                    )
                )
        }
        .flatMap { $0.mapError { $0 as Error } }
        .tryMap(handleOutput(_:))
        .tryMap(parseAttendance(from:))
        .mapError { $0 as? WebServiceError ?? WebServiceError.requestFail(error: $0) }
        .eraseToAnyPublisher()
    }
}

// MARK: - Other

private extension WebService {
    
    func handleOutput(_ output: URLSession.DataTaskPublisher.Output) throws -> Data {
        guard let httpResponse = output.response as? HTTPURLResponse else { throw WebServiceError.httpResponseError }
        
        if 200 ..< 300 ~= httpResponse.statusCode {
            return output.data
        }
        else {
            throw WebServiceError.httpResponseFail(response: httpResponse)
        }
    }
    
    func createCookie(name: String, value: String) -> HTTPCookie? {
        HTTPCookie(
            properties:
                [
                    .name: name,
                    .value: value,
                    .domain: "cloud.nueip.com",
                    .path: "/"
                ]
        )
    }
    
    func parseLoginToken(from data: Data) throws -> String {
        guard let string = String(data: data, encoding: .utf8) else { throw WebServiceError.invalidToken }
        
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
            throw WebServiceError.invalidToken
        }
        catch {
            print(error.localizedDescription)
            throw WebServiceError.invalidToken
        }
        
        guard let _token = token else {
            throw WebServiceError.invalidToken
        }
        
        return _token
    }
    
    func parseAttendance(from data: Data) throws -> AttendanceResponse {
        /// Because the response use user_sn to define the key of element, so cant use decoder to decode
        if let dictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let data = dictionary["data"] as? [String: Any],
           let date = data[getTodayString()] as? [String: Any],
           let userSN = date.map({ $0.value }).first as? [String: Any],
           let userData = try? JSONSerialization.data(withJSONObject: userSN, options: []),
           let attendance = try? JSONDecoder().decode(AttendanceResponse.self, from: userData) {
        
            return attendance
        }
        else {
            throw WebServiceError.invalidValue
        }
    }
    
    func buildURL(from type: ApiType) throws -> URL {
        var component = URLComponents()
        component.scheme = "https"
        component.host = host
        
        switch type {
        case .login:
            component.path = "/login/index/param"
        case .clock(_):
            component.path = "/time_clocks/ajax"
        case .attendance:
            component.path = "/attendance_record/ajax"
        }
        
        guard let url = component.url else { throw WebServiceError.invalidURL(error: URLError(.badURL)) }
        return url
    }
    
    func buildFormDataRequest(url: URL, from formDictionary: [String: Any]) -> URLRequest {
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
    
    func createAttendanceSession() throws -> URLSession {
        let config = URLSession.shared.configuration
        
        guard let start = createCookie(name: "Search_42_date_start", value: getTodayString()),
              let end = createCookie(name: "Search_42_date_end", value: getTodayString())
        else {
            throw WebServiceError.invalidSession
        }
        
        config.httpCookieStorage?.setCookie(start)
        config.httpCookieStorage?.setCookie(end)
        
        return URLSession(configuration: config)
    }
    
    func getTodayString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        
        return dateFormatter.string(from: Date())
    }
}
