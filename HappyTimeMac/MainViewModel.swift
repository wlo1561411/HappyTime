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
    
    @Published var userList = [User]()
    @Published var log = [String]()

    private var cancellables = Set<AnyCancellable>()

    private var clockQueueArray = [Clock]()
    private let group = DispatchGroup()
    private let clockQueue = DispatchQueue(label: "clock")
    
    private let firestore = Firestore.firestore()
    private var isLogining = false

    private var token: String?
    
    init() {
        getUser()
        bindClock()
        clockCircle()
    }
}

// MARK: - controller

extension MainViewModel {
    
    private func clockCircle() {
        clockQueue.async {
            while true {
                guard !self.isLogining,
                      self.clockQueueArray.count > 0,
                      let clock = self.clockQueueArray.first else {
                         continue
                      }
                
                self.isLogining = true
                
                self.group.enter()
                self.clockProgress(clock: clock) {
                    self.group.leave()
                }
                
                self.group.notify(queue: .global()) {
                    self.clockQueueArray.remove(at: 0)
                    self.isLogining = false
                }
            }
        }
    }
    
    private func clockProgress(clock: Clock, handle: (() -> Void)?) {
        
        updateClock(id: clock.documentID ?? "", value: ["status": ClockSttus.queue.rawValue])
        
        guard let user = userList.first(where: { $0.name == clock.name }) else {
            updateClock(id: clock.documentID ?? "", value: ["status": ClockSttus.userNotFind.rawValue])
            handle?()
            return
        }
        
        login(user: user) { loginStatus in
            guard loginStatus == .success else {
                self.updateClock(id: clock.documentID ?? "", value: ["status": loginStatus.rawValue])
                handle?()
                return
            }
            self.clock(user: user, type: ClockType.init(rawValue: clock.clock) ?? .In) { clockStatus in
                self.updateClock(id: clock.documentID ?? "", value: ["status": clockStatus.rawValue])
                handle?()
            }
        }
        
    }
}


// MARK: - Firebase API

extension MainViewModel {
    
   private func bindClock() {
        firestore.collection("clocks").addSnapshotListener { allSnapshot, error in
            guard let allSnapshot = allSnapshot, !allSnapshot.metadata.isFromCache else { return }
            
            let dataArray = allSnapshot.documents.map { snapshot -> Dictionary<String, Any> in
                var data = snapshot.data()
                data["documentID"] = snapshot.documentID
                return data
            }
            
            guard let json = try? JSONSerialization.data(withJSONObject: dataArray),
                  let clockArray = try? JSONDecoder().decode([Clock].self, from: json) else { return }
            
            let clockQueueArray = clockArray.filter({ $0.status == ClockSttus.none.rawValue })
            
            clockQueueArray.forEach { clock in
                if !self.clockQueueArray.contains(where: { $0.documentID == clock.documentID }) {
                    self.clockQueueArray.append(clock)
                }
            }
        }
    }
    
    private func updateClock(id: String, value: [String: Any]) {
        firestore
            .collection("clocks")
            .document(id)
            .updateData(value)
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
                
//                dump(self.userList)
            }
    }
}


// MARK: - Combine API

extension MainViewModel {
    
    func login(user: User, handle: ((ClockSttus) -> Void)?) {
        token = ""
        WebService.shared.removeAllCookies()
        
        WebService
            .shared
            .login(code: "YIZHAO", account: user.id, password: user.password)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in
                self?.updateLog("\(user.name) logging in \(Date())")
            }, receiveOutput: { [weak self] token in
                self?.token = token
            }, receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.updateLog("\(user.name) logged \(Date())")
                    handle?(ClockSttus.success)
                case .failure(let error):
                    self?.updateLog("\(user.name) Login failure, \(error.localizedDescription) \(Date())")
                    handle?(ClockSttus.fail)
                }
            })
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    func clock(user: User, type: ClockType, handle: ((ClockSttus) -> Void)?) {
        WebService
            .shared
            .ipClock(type, token: token ?? "")
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] error in
                self?.updateLog("\(user.name) clocking \(Date())")
            }, receiveOutput: { _ in
                
            }, receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.updateLog("\(user.name) \(type.rawValue) success \(Date())")
                    handle?(ClockSttus.success)
                case .failure(let error):
                    self?.updateLog("clock failure, \(error.localizedDescription) \(Date())")
                    handle?(ClockSttus.fail)
                }
                
            })
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}

// MARK: - Log

extension MainViewModel {
    
    private func updateLog(_ log: String) {
        DispatchQueue.main.async { [weak self] in
            self?.log.append(log)
        }
    }
}
