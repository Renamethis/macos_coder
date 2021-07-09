//
//  Document.swift
//  coderdecoder1.1
//
//  Created by Иван Гаврилов on 07.07.2021.
//

import SwiftUI
import UniformTypeIdentifiers

struct Document {
    static var readableContentTypes: [UTType] { [.plainText] }
    var rawdata: Data
    var coder: Coder
    var isCrypt: Bool = false
    var fileUrl: String = ""
    init(input: Data) {
        self.rawdata = input
        var ivi: [Int] = []
        for _ in 0...15 {
            ivi.append(Int.random(in: 0..<5))
        }
        let iv = Data(ivi.withUnsafeBufferPointer {Data(buffer: $0)})
        coder = Coder(iv: iv)
    }
    mutating func codeProcess(encode: Bool, passphrase: String, salt: String) throws -> Bool {
        do {
            let key = try coder.generateKey(passphrase: passphrase, salt: salt)
            if(key.count == 0) { return false }
            let crypted_data = try (encode) ? coder.encrypt(data: self.rawdata) : coder.decrypt(data: self.rawdata)
            self.rawdata = Data(crypted_data)
            let sub = Substring(self.fileUrl)
            if(sub.contains(".crypted") && !encode) {
                let format = ".crypted"
                let out = try self.substring(string: self.fileUrl, sub: format)
                self.fileUrl = String(sub[..<sub.index(sub.startIndex, offsetBy: out)])
                self.rawdata = self.rawdata.subdata(in: 112...self.rawdata.count-1)
            } else if(encode) {
                self.fileUrl = self.fileUrl + ".crypted"
            } else {
            }
            if(!FileManager.default.fileExists(atPath: self.fileUrl)){
                let url: URL = URL(string: self.fileUrl)!
                try self.rawdata.write(to: url, options: .noFileProtection)
            } else {
            }
        } catch {
            print("Error: ", error)
            return false
        }
        return true
    }
    private func substring(string: String, sub: String) throws -> Int{
        var i: Int = 0
        var length: Int = 0
        var index: Int = -1
        while (i < string.count) {
            length = 0
            for ch in sub {
                if(ch == string[string.index(string.startIndex, offsetBy: i)]) {
                    index = (index == -1) ? i: index
                    i+=1
                    length+=1
                } else {
                    length = 0
                    break
                }
                if(length == sub.count) {
                    return index
                }
            }
            index = -1
            i+=1
        }
        return -1;
    }

}
extension Data {
    func subdata(in range: ClosedRange<Index>) -> Data {
        return subdata(in: range.lowerBound ..< range.upperBound + 1)
    }
}
extension UTType {
    static var crypted: UTType {
        UTType(importedAs: "public.crypted")
    }
}
