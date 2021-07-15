//
//  ContentView.swift
//  coderdecoder1.1
//
//  Created by Иван Гаврилов on 07.07.2021.
//

import SwiftUI
import UniformTypeIdentifiers
import CommonCrypto
var key: Key = Key(size: kCCKeySizeAES128)
struct CheckBoxView: View {
    @Binding var checked: Bool
    @Binding var buttonLabel: String
    @State var text: String
    @State var change: String
    var body: some View {
        HStack() {
            Text(text)
            Image(systemName: checked ? "checkmark.square.fill" : "square")
                .foregroundColor(checked ? Color.blue : Color.secondary)
                .onTapGesture {
                    self.checked.toggle()
                    let buf: String = self.text
                    self.text = self.change
                    self.change = buf
                    self.buttonLabel = "Browse file to " + self.text.lowercased()
                }
        }
    }
}
struct ContentView: View {
    @State private var isImporting: Bool = false
    @State private var isExporting: Bool = false
    @State private var isGenerated: Bool = key.loadKeychain()
    @State var checked = false
    @State var outfile: String = ""
    @State var passphrase: String = ""
    @State var salt: String = ""
    @State var buttonLabel: String = "Browse file to encryption"
    @State var info: String = ""
    var mode1: String = "Encryption"
    var mode2: String = "Decryption"
    var body: some View {
        VStack() {
            Text("Choose encrypt/decrypt mode").padding(.top)
            HStack() {
            CheckBoxView(checked: $checked, buttonLabel: $buttonLabel, text: mode1, change: mode2)
            }
            HStack {
                Button(action: {
                    key.generateKey(keySize: kCCKeySizeAES128)
                    if(!key.saveKeychain()) {
                        info = "Failed to save key"
                        return
                    }
                    info = "Key generated and saved successfully"
                    self.isGenerated = true
                }, label: {
                    Text("Generate Key")
                })
                Button(action: {
                    isImporting = true
                }, label: {
                    Text(buttonLabel)
                }).disabled(!self.isGenerated)
            }
            Text(info)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [checked ? .crypted : .data],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile: URL = try result.get().first else { self.info = "Error with file selecting"; return }
                let input: Data = try Data(contentsOf: selectedFile)
                let code = try Coder(fileUrl: selectedFile.absoluteString, inputData: input, encode: !checked, key: key.getKey())
                _ = (self.checked) ? try code.decrypt() : try code.encrypt()
                try code.saveData()
                self.info = "Code process failed"
                self.info = ((self.checked) ? self.mode2 : self.mode1) + " processed successfully"
            } catch {
                print("Unable to read file contents")
                print(error.localizedDescription)
                self.info = "Error: " + error.localizedDescription
            }
        }.frame(maxWidth: 350, maxHeight: 110)
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
extension UTType {
    static var crypted: UTType {
        UTType(importedAs: "public.crypted")
    }
}
extension View {
    @ViewBuilder func isHidden(_ hidden: Bool, remove: Bool = false) -> some View {
        if hidden {
            if !remove {
                self.hidden()
            }
        } else {
            self
        }
    }
}
