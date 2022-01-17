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
    
    @Published var list = [User]()
    
    @Published var name: String = ""
    @Published var id: String = ""
    @Published var password: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    private var token: String? {
        didSet {
           
        }
    }
    
    func addData(id: String, name: String, password: String) {
        
        let db = Firestore.firestore()
        
        db.collection("users").addDocument(data: ["id": id, "name": name, "password": password]) { error in
            
            if error == nil {
                
                self.getData()
            }
            else {
                
            }
            
        }
        
    }
    
    func getData() {
        
        let db = Firestore.firestore()
        
        db.collection("users").getDocuments { snapshot, error in
            
            if error == nil {
                   
                if let snapshot = snapshot {
                    dump(snapshot)
                    DispatchQueue.main.async {
                        self.list = snapshot.documents.map { data in
                            return User(id: data["id"] as? String ?? "",
                                        name: data["name"] as? String ?? "",
                                        password: data["password"] as? String ?? "")
                        }
                    }
                }
                
            }
            else {
                
                
            }
        }
        
    }
    
}

// MARK: - Combine API

extension MainViewModel {
    
    func login() {
        
        WebService.shared.removeAllCookies()
        
        let login = WebService
            .shared
            .login(code: "YIZHAO", account: id, password: password)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] _ in
//                self?.isLoading = true
            }, receiveOutput: { [weak self] token in
                guard let self = self else { return }
                
                self.token = token
            }, receiveCompletion: { [weak self] completion in
  
            })
            .eraseToAnyPublisher()
        
        getAttendance(upsteam: login)
    }
    
    func clock(_ type: ClockType) {

        let clock = WebService
            .shared
            .ipClock(type, token: token ?? "")
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { [weak self] error in
                
            }, receiveOutput: { [weak self] response in
                
            }, receiveCompletion: { [weak self] completion in
   
            })
            .eraseToAnyPublisher()
        
        getAttendance(upsteam: clock)
    }
    
    func getAttendance<T>(upsteam: AnyPublisher<T, WebError>) {
        
        let getAttendance = WebService
            .shared
            .getAttendance()
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] attendance in

            }, receiveCompletion: { [weak self] completion in

            })
            .eraseToAnyPublisher()
        
        upsteam
            .flatMap { _ in getAttendance }
            .sink(receiveCompletion: { _ in }
                  ,receiveValue: { _ in })
            .store(in: &cancellables)
    }
}

