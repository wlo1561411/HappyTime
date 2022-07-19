//
//  MainViewModel.swift
//  HappyTimeMac
//
//  Created by Wesley on 2022/1/17.
//

import Foundation
import SwiftUI
import Combine
import FirebaseDatabase

class MainViewModel_Realtime: ObservableObject {
    
    typealias WebError = WebService.WebServiceError
    
    @Published var userList = [User]()
    @Published var log = [String]()

    private var cancellables = Set<AnyCancellable>()

    private var clockQueueArray = [Clock]()
    private let group = DispatchGroup()
    private let clockQueue = DispatchQueue(label: "clock")
    
    private var isLogining = false

    private var token: String?
    
    private let reference = Database.database().reference()
    private var handle: DatabaseHandle?
    
    init() {
        getUser()
        bindClock()
        clockCircle()
    }
}

// MARK: - controller

extension MainViewModel_Realtime {
    
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

extension MainViewModel_Realtime {
    
   private func bindClock() {
       handle = reference.child("clocks").observe(.value, with: { [unowned self] snapshot in

           if let data = try? JSONSerialization.data(withJSONObject: snapshot.value),
              let json = try? JSONDecoder().decode([String: Clock].self, from: data) {

               let clocks = json.map {
                   Clock.init(documentID: $0.key, name: $0.value.name, clock: $0.value.clock, status: $0.value.status)
               }

               let clockQueueArray = clocks.filter({ $0.status == ClockSttus.none.rawValue })

               clockQueueArray.forEach { clock in
                   if !self.clockQueueArray.contains(where: { $0.documentID == clock.documentID }) {
                       self.clockQueueArray.append(clock)
                   }
               }
           }
       })
    }
    
    private func updateClock(id: String, value: [String: Any]) {
        reference.child("clocks")
            .child(id)
            .updateChildValues(value)
    }
    
    private func deleteClock(id: String) {
        reference.child("clocks")
            .child(id)
            .removeValue()
    }
    
   private func addUser(id: String, name: String, password: String) {
       reference.child("users")
           .childByAutoId()
           .setValue([
            "id": id,
            "name": name,
            "password": password
           ], withCompletionBlock: { [weak self] _, _ in
               self?.getUser()
           })
    }
    
    private func getUser() {
        reference.child("users").getData { error, snapshot in

            if let data = try? JSONSerialization.data(withJSONObject: snapshot.value),
               let json = try? JSONDecoder().decode([String: User].self, from: data) {

                let arr = json.values.map { $0 }

                self.userList = arr
            }
        }
    }
}


// MARK: - Combine API

extension MainViewModel_Realtime {
    
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

extension MainViewModel_Realtime {
    
    private func updateLog(_ log: String) {
        DispatchQueue.main.async { [weak self] in
            self?.log.append(log)
        }
    }
}
