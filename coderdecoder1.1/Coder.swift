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
        }
        let message: CCCryptorStatus
        let kind: ErrorKind
    }
    var key: Data = Data()
    var iv: Data
    init(iv: Data) {
        self.iv = iv
    }
    func generateKey(passphrase: String, salt: String) throws -> Data {
        let rounds = UInt32(45_000)
        var outputBytes = Array<UInt8>(repeating: 0,
                                       count: kCCKeySizeAES128)
        let status = CCKeyDerivationPBKDF(
                         CCPBKDFAlgorithm(kCCPBKDF2),
                         passphrase,
                         passphrase.utf8.count,
                         salt,
                         salt.utf8.count,
                         CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),
                         rounds,
                         &outputBytes,
                         kCCKeySizeAES128)
        guard status == kCCSuccess else {
            throw CoderError(message: status, kind: .derrivationError)
        }
        self.key = Data(_: outputBytes)
        return Data(_: outputBytes)
    }
    func encrypt(data: Data) throws -> Data {
        // Output buffer (with padding)
        let outputLength = data.count + kCCBlockSizeAES128
        var outputBuffer = Array<UInt8>(repeating: 0,
                                        count: outputLength)
        var numBytesEncrypted = 0
        let status = CCCrypt(CCOperation(kCCEncrypt),
                             CCAlgorithm(kCCAlgorithmAES),
                             CCOptions(kCCOptionPKCS7Padding),
                             Array(self.key),
                             kCCKeySizeAES128,
                             Array(iv),
                             Array(data),
                             data.count,
                             &outputBuffer,
                             outputLength,
                             &numBytesEncrypted)
        guard status == kCCSuccess else {
            throw CoderError(message: status, kind: .encryptionError)
        }
        let outputBytes = self.iv + outputBuffer.prefix(numBytesEncrypted)
        return Data(_: outputBytes)
    }
    func decrypt(data cipherData: Data) throws -> Data {
        let iv = cipherData.prefix(kCCBlockSizeAES128)
        let cipherTextBytes = cipherData
                               .suffix(from: kCCBlockSizeAES128)
        let cipherTextLength = cipherTextBytes.count
        // Output buffer
        var outputBuffer = Array<UInt8>(repeating: 0,
                                        count: cipherTextLength)
        var numBytesDecrypted = 0
        let status = CCCrypt(CCOperation(kCCDecrypt),
                             CCAlgorithm(kCCAlgorithmAES),
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
            throw CoderError(message: status, kind: .decryptionError)
        }
        // Read output discarding any padding
        let outputBytes = outputBuffer.prefix(numBytesDecrypted)
        return Data(_: outputBytes)
    }
}
