//
//  ContentView.swift
//  coderdecoder1.1
//
//  Created by Иван Гаврилов on 07.07.2021.
//

import SwiftUI
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
    @State private var doc: Document = Document(input: Data())
    @State private var isImporting: Bool = false
    @State private var isExporting: Bool = false
    @State private var isLoaded:Bool = false
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
            Text("Choose encrypt/decrypt mode")
            CheckBoxView(checked: $checked, buttonLabel: $buttonLabel, text: mode1, change: mode2)
            HStack {
                Text("Passphrase: ")
                TextField("Enter passphrase", text: $passphrase)
            }
            HStack {
                Text("Salt Word:    ")
                TextField("Enter salt word", text: $salt)
            }
            HStack {
                Button(action: {
                    isImporting = true
                    isExporting = false
                }, label: {
                    Text(buttonLabel)
                }).disabled(self.salt == "" || self.passphrase == "")
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
                self.doc.rawdata = input
                self.doc.fileUrl = selectedFile.absoluteString
                self.isLoaded = true
                self.info = "Code process failed"
                let isWorking: Bool = try self.doc.codeProcess(encode: !self.checked, passphrase: self.passphrase, salt: self.salt)
                if(isWorking) {
                    self.info = ((self.checked) ? self.mode2 : self.mode1) + " processed successfully"
                }
            } catch {
                print("Unable to read file contents")
                print(error.localizedDescription)
                self.info = "Error: " + error.localizedDescription
            }
        }
        .frame(maxWidth: 320, maxHeight: 190)
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
