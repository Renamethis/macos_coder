//
//  Key.swift
//  coderdecoder1.1
//
//  Created by Иван Гаврилов on 14.07.2021.
//

import Foundation
class Key {
    private var key: Data
    var keySize: Int
    let account: String = "coderdecoder.key"
    init(size: Int) {
        self.keySize = size
        self.key = Data()
    }
    func loadKeychain() -> Bool {
        let getquery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                       kSecAttrAccount as String: account,
                                       kSecMatchLimit as String: kSecMatchLimitOne,
                                       kSecReturnData as String: kCFBooleanTrue!]
        var item:CFTypeRef?
        let status = SecItemCopyMatching(getquery as CFDictionary, &item)
        guard status == errSecSuccess else { return false }
        let queriedItem = item as! Data
        self.key = queriedItem
        return (queriedItem.count != 0)
    }
    func saveKeychain() -> Bool {
        var query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: account]
        var status = SecItemCopyMatching(query as CFDictionary, nil)
        switch(status) {
        case errSecSuccess:
            let attributes: [String: Any] = [kSecValueData as String: key]
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if status != errSecSuccess {
                return false
            }
        case errSecItemNotFound:
            var result: CFTypeRef? = nil
            query[String(kSecValueData)] = key
            status = SecItemAdd(query as CFDictionary, &result)
            if status != errSecSuccess {
                return false
            }
        default:
          return false
        }
        return true
    }
    func generateKey(keySize: Int) {
        var keybytes: [UInt8] = []
        for _ in 0...keySize - 1{
            keybytes.append(UInt8.random(in: 0..<255))
        }
        let key = Data(_: keybytes)
        self.key = key
    }
    func getKey() -> Data {
        return key
    }
}
