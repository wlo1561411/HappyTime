//
//  MainViewModel.swift
//  HappyTimeMac
//
//  Created by Wesley on 2022/1/17.
//

import Foundation
import SwiftUI
import Combine
import Firebase

class MainViewModel: ObservableObject {
    
    typealias WebError = WebService.WebServiceError
    typealias ApiType = WebService.ApiType
    
    @Published var userList = [User]()
    
    @Published var log = [String]()
    
    private var cancellables = Set<AnyCancellable>()
    private var token: String?
    
    private let clockQueue = DispatchQueue(label: "clock")
    
    let firestore = Firestore.firestore()
    
    init() {
        bindClock()
    }
    

    
    func bindClock() {
        
        firestore.collection("clocks").addSnapshotListener { allSnapshot, error in
            if let allSnapshot = allSnapshot, !allSnapshot.metadata.isFromCache {
                
                let dataArray = allSnapshot.documents.map {
                    $0.data()
                }
                
                guard let json = try? JSONSerialization.data(withJSONObject: dataArray),
                      let clockArray = try? JSONDecoder().decode([Clock].self, from: json) else { return }
                
                let clockQueueArray = clockArray.filter({ !$0.expired && !$0.queue })
                
                clockQueueArray.forEach {
                    self.log.append("\($0.name) \($0.clock)")
                    self.progessClock(name: $0.name)
                }
                
            }
        }
    }
    
    func progessClock(name: String) {
        
        clockQueue.sync {
            
            if let user = userList.first(where: { $0.name == name }) {
                
                login(name: user.name, id: user.id, password: user.password)
                
            }
            
        }
        
        
    }

    
    func addData(id: String, name: String, password: String) {
        
        firestore
            .collection("users")
            .addDocument(data: ["id": id, "name": name, "password": password]) { error in
                self.getData()
            }
    }
    
    
    func getData() {
        
        firestore
            .collection("users")
            .getDocuments { allSnapshot, error in
                
                if let allSnapshot = allSnapshot {
                    
                    let dataArray = allSnapshot.documents.map {
                        $0.data()
                    }
                    
                    guard let json = try? JSONSerialization.data(withJSONObject: dataArray),
                          let userArray = try? JSONDecoder().decode([User].self, from: json) else { return }
                    
                    self.userList = userArray
                }
            }
        
    }
    
}


// MARK: - Action

extension MainViewModel {
    
    
    
}

// MARK: - Combine API

extension MainViewModel {
    
    func login(name: String, id: String, password: String) {
        
        WebService.shared.removeAllCookies()
        
        WebService
            .shared
            .login(code: "YIZHAO", account: id, password: password)
        //            .receive(on: DispatchQueue.global())
            .handleEvents(receiveSubscription: { _ in
                self.log.append("Loging...")
            }, receiveOutput: { token in
                self.token = token
            }, receiveCompletion: { completion in
                switch completion {
                case .finished:
                    self.log.append("\(name) login")
                case .failure(let error):
                    self.log.append("Login failure, \(error.localizedDescription)")
                }
            })
            
        
    }
    
    func clock(_ type: ClockType) {

        let _ = WebService
            .shared
            .ipClock(type, token: token ?? "")
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] error in
                
            }, receiveOutput: { [weak self] response in
                
            }, receiveCompletion: { [weak self] completion in
   
            })
            .eraseToAnyPublisher()
        
    }
    
 
}

