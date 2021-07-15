//
//  Coder.swift
//  coderdecoder1.1
//
//  Created by Иван Гаврилов on 07.07.2021.
//
//
import CommonCrypto
import UniformTypeIdentifiers
class Coder {
    struct CoderError: Error {
        enum ErrorKind {
            case encryptionError
            case decryptionError
            case derrivationError
            case initError
            case saveError
        }
        let message: String
        let kind: ErrorKind
    }
    var key: Data = Data()
    let iv : Data
    var rawdata: Data
    var fileUrl: String
    init(fileUrl: String, inputData: Data, encode: Bool, key: Data) throws {
        self.key = key
        self.rawdata = inputData
        self.fileUrl = fileUrl
        let sub = Substring(self.fileUrl)
        var ivi: [UInt8] = []
        for _ in 0...15 {
            ivi.append(UInt8.random(in: 1...16))
        }
        iv = Data(bytes: ivi, count: ivi.count)
        guard self.key.count != 0 else {
            throw CoderError(message: "Internal Error", kind: .initError)
        }
        if(sub.contains(".crypted") && !encode) {
            let format = ".crypted"
            let out = self.substring(string: self.fileUrl, sub: format)
            self.fileUrl = String(sub[..<sub.index(sub.startIndex, offsetBy: out)])
        } else if(encode) {
            self.fileUrl = self.fileUrl + ".crypted"
        } else {
            throw CoderError(message: "Internal Error", kind: .initError)
        }
    }
    func saveData() throws {
        if(!FileManager.default.fileExists(atPath: self.fileUrl)){
            let url: URL = URL(string: self.fileUrl)!
            try self.rawdata.write(to: url, options: .noFileProtection)
        } else {
            throw CoderError(message: "File already exists", kind: .saveError)
        }
    }
    func encrypt() throws {
        // Output buffer (with padding)
        let outputLength = self.rawdata.count + kCCBlockSizeAES128
        var outputBuffer = Array<UInt8>(repeating: 0,
                                        count: outputLength)
        var numBytesEncrypted = 0
        let status = CCCrypt(CCOperation(kCCEncrypt),
                             CCAlgorithm(kCCAlgorithmAES128),
                             CCOptions(kCCOptionPKCS7Padding),
                             Array(self.key),
                             kCCKeySizeAES128,
                             Array(iv),
                             Array(self.rawdata),
                             self.rawdata.count,
                             &outputBuffer,
                             outputLength,
                             &numBytesEncrypted)
        guard status == kCCSuccess else {
            throw CoderError(message: status.description, kind: .encryptionError)
        }
        let outputBytes = self.iv + outputBuffer.prefix(numBytesEncrypted)
        self.rawdata = Data(_: outputBytes)
    }
    func decrypt() throws {
        let iv = self.rawdata.prefix(kCCBlockSizeAES128)
        let cipherTextBytes = self.rawdata
                               .suffix(from: kCCBlockSizeAES128)
        let cipherTextLength = cipherTextBytes.count
        var outputBuffer = Array<UInt8>(repeating: 0,
                                        count: cipherTextLength)
        var numBytesDecrypted = 0
        let status = CCCrypt(CCOperation(kCCDecrypt),
                             CCAlgorithm(kCCAlgorithmAES128),
                             CCOptions(),
                             Array(self.key),
                             kCCKeySizeAES128,
                             Array(iv),
                             Array(cipherTextBytes),
                             cipherTextLength,
                             &outputBuffer,
                             cipherTextLength,
                             &numBytesDecrypted)
        guard status == kCCSuccess else {
            throw CoderError(message: status.description, kind: .decryptionError)
        }
        let outputBytes = outputBuffer.prefix(numBytesDecrypted)
        self.rawdata = Data(_: outputBytes)
        //self.rawdata = self.rawdata.subdata(in: iv.count..<self.rawdata.count)
    }
    private func substring(string: String, sub: String) -> Int{
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
