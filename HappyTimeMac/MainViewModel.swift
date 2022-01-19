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
    
    private let actions = CurrentValueSubject<[AnyPublisher<String, WebError>], Never>([])
    
    private let group = DispatchGroup()
    
    private var isLogining = false
    
    let firestore = Firestore.firestore()
    
    init() {
        getUser()
        bindClock()
        clockCircle()
        actions
//            .flatMap(maxPublishers: .max(1), { $0 })
            .sink { publishers in
                Publishers.Sequence(sequence: publishers)
                    .flatMap(maxPublishers: .max(1), { $0 })
                    .sink { _ in
                        
                    } receiveValue: { [unowned self] token in
                        self.token = token
                    }
                    .store(in: &self.cancellables)
        }
            .store(in: &cancellables)
    }
  
}

// MARK: - controller

extension MainViewModel {
    
    func clockCircle() {
        
        while true {
            
            guard !isLogining else { return }
            
            isLogining = true

            
            
            
        }
        
    }
    
    
    func clockProgress(name: String) {

        
        
        
        
        
        if let user = userList.first(where: { $0.name == name }) {
            actions.value += [self.loginPublisher(user: user)]
//            login(name: user.name, id: user.id, password: user.password)
        }
    }
}


// MARK: - Firebase API

extension MainViewModel {
    
    func bindClock() {
        
        firestore.collection("clocks").addSnapshotListener { allSnapshot, error in
            guard let allSnapshot = allSnapshot, !allSnapshot.metadata.isFromCache else { return }
            
            let dataArray = allSnapshot.documents.map { snapshot -> Dictionary<String, Any> in
                var data = snapshot.data()
                data["documentID"] = snapshot.documentID
                return data
            }
            
            guard let json = try? JSONSerialization.data(withJSONObject: dataArray),
                  let clockArray = try? JSONDecoder().decode([Clock].self, from: json) else { return }
            
            let clockQueueArray = clockArray.filter({ !$0.expired && !$0.queue })
            
            clockQueueArray.forEach {
                self.log.append("\($0.name) \($0.clock) \(Date())")
                self.updateClock(id: $0.documentID)
                self.clockProgress(name: $0.name)
            }
        }
    }
    
    private func updateClock(id: String) {
        firestore
            .collection("clocks")
            .document(id)
            .updateData(["queue":true])
    }
    
    private func deleteClock(id: String) {
        firestore
            .collection("clocks")
            .document(id)
            .delete()
    }
    
   private func addUser(id: String, name: String, password: String) {
        firestore
            .collection("users")
            .addDocument(data: ["id": id, "name": name, "password": password]) { error in
                self.getUser()
            }
    }
    
    private func getUser() {
        firestore
            .collection("users")
            .getDocuments { allSnapshot, error in
                guard let allSnapshot = allSnapshot else { return }
                let dataArray = allSnapshot.documents.map {
                    $0.data()
                }
                
                guard let json = try? JSONSerialization.data(withJSONObject: dataArray),
                      let userArray = try? JSONDecoder().decode([User].self, from: json) else { return }
                
                self.userList = userArray
            }
    }
    
}

// MARK: - Combine API

extension MainViewModel {
    
    func login(user: User) {
        
        WebService.shared.removeAllCookies()
        
        WebService
            .shared
            .login(code: "YIZHAO", account: user.id, password: user.password)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in
                self?.log.append("Loging...")
            }, receiveOutput: { [weak self] token in
                self?.token = token
            }, receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.log.append("\(user.name) login")
                case .failure(let error):
                    self?.log.append("Login failure, \(error.localizedDescription)")
                }
            })
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    func loginPublisher(user: User) -> AnyPublisher<String, WebError> {
        
        WebService.shared.removeAllCookies()
        
        return WebService
            .shared
            .login(code: "YIZHAO", account: user.id, password: user.password)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in
                self?.log.append("Loging...")
            }, receiveOutput: { [weak self] token in
                self?.token = token
            }, receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.log.append("\(user.name) login")
                case .failure(let error):
                    self?.log.append("Login failure, \(error.localizedDescription)")
                }
            })
            .eraseToAnyPublisher()
    }
    
    func clock(_ type: ClockType) {
        
       WebService
            .shared
            .ipClock(type, token: token ?? "")
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] error in
                self?.log.append("clocking")
            }, receiveOutput: { _ in
                
            }, receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.log.append("\(type.chinese)")
                case .failure(let error):
                    self?.log.append("Login failure, \(error.localizedDescription)")
                }
            })
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        
    }
    
 
 
}

