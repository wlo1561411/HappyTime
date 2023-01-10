//
//  AppManager.swift
//  HappyTime
//
//  Created by Finn Wu on 2022/1/3.
//

import UIKit

class AppManager {
    
    static let shared = AppManager()
    
    @Published var isReceivedNotification: Bool = false
}

// MARK: - Keychain

extension AppManager {
    
    func save(_ value: String, for key: String) {
        let value = value.data(using: String.Encoding.utf8)!
        let query: [String: Any] =
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: value
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { return print("Save error!!") }
    }
    
    func update(_ value: String, for key: String) {
        let value = value.data(using: String.Encoding.utf8)!
        let query: [String: Any] =
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: value
        ]
        
        let status = SecItemUpdate(query as CFDictionary, [String: AnyObject]() as CFDictionary)
        guard status == errSecSuccess else { return print("Update error!!") }
    }
    
    func query(for key: String) -> String? {
        let query: [String: Any] =
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue ?? false
        ]
        
        var retrivedData: AnyObject? = nil
        let _ = SecItemCopyMatching(query as CFDictionary, &retrivedData)
        
        guard let data = retrivedData as? Data else { return nil }
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
    func delete(for key: String) {
        let query: [String: Any] =
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else { return print("Remove error!!") }
    }
}
