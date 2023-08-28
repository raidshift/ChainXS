//
//  SheetView.swift
//  ChainXS
//
//  Created by Laurenz Zielinski
//

import SwiftUI

struct SheetView: View {
    @Environment(\.dismiss) var dismiss

    @State var key: String
    @State var passphrase: String
    @State var path: String
    @State var password: String = ""
    @State var confirmPassword: String = ""

    @State var filename: String = ""

    init(key: String, passphrase: String, path: String) {
        // self.key = key
        _key = State(initialValue: key)
        _passphrase = State(initialValue: passphrase)
        _path = State(initialValue: path)
    }

    struct CustomSecureField: View {
        var title: String
        var text: Binding<String>

        var body: some View {
            TextField(title, text: text)
                .lineLimit(1)
                .disableAutocorrection(true)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(8)
                .cornerRadius(10)
        }
    }

    var body: some View {
        VStack {
            ScrollView {
                HStack {
                    VStack(alignment: .leading) {
                        Spacer()
                        Text("Encrypt & Save").font(.headline)
                        Spacer()
                        Text("key = \"\(key)\"").textSelection(.enabled).foregroundColor(SUCCESS).font(MONO_FONT).lineLimit(1)
                        Text("passphrase = \"\(passphrase)\"").textSelection(.enabled).foregroundColor(SUCCESS).font(MONO_FONT).lineLimit(1)
                        Text("path = \"\(path)\"").textSelection(.enabled).foregroundColor(SUCCESS).font(MONO_FONT).lineLimit(1)

                        Spacer()
                    }.padding(.horizontal)
                    Spacer()
                }
            }
            Divider().padding(.horizontal)

            VStack {
                CustomSecureField(title: "enter a password ...", text: $password)
                CustomSecureField(title: "confirm password ...", text: $confirmPassword)
            }.padding(.horizontal)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(.footnote)
                Spacer()
                Button("Encrypt & Save") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    if panel.runModal() == .OK {
                        filename = panel.url?.lastPathComponent ?? "<none>"
                    }
                }
                .font(.footnote)
            }.padding(.horizontal)
            Text("Enryption Param: AES-256-CBC RANDOM_IV(128) PKCS#5 PBKDF2 RANDOM_SALT(64) MD=SHA512 ITER=250000").font(.footnote).foregroundColor(.gray)
        }.background(Color(red: 0.172, green: 0.315, blue: 0.378)).frame(minWidth: 600, minHeight: 300, maxHeight: 300)
    }
}
