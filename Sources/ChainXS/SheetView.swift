//
//  SheetView.swift
//  ChainXS
//
//  Created by Laurenz Zielinski
//

import SwiftUI

struct SheetView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var key: String
    @Binding var passphrase: String
    @Binding var path: String
    @Binding var selectedLevel: Int
    @State var password: String = ""
    @State var confirmPassword: String = ""
    @State var filename: String = ""


    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading) {
                HStack {
                    Text("Encrypt & Save").font(.headline)
                }
            }.padding(.horizontal)
            ScrollView {
                HStack {
                    VStack {
                        Spacer()
                        Text("KEY = \"\(key)\"\n\nPASSPHRASE = \"\(passphrase)\"\n\nPATH = \"\(path)\"\n\nLEVEL = \"\(selectedLevel)\"")
                            .textSelection(.enabled)
                            .foregroundColor(SUCCESS)
                            .font(MONO_FONT)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(SUCCESS, lineWidth: 1)
                            )
                    }
                }.padding(.horizontal)
            }

            VStack(alignment: .leading) {
                Text("Password").font(.headline)
                CustomSecureField(title: "enter password ...", text: $password).foregroundColor(SUCCESS)
                Text("Password Confirmation").font(.headline)
                CustomSecureField(title: "confirm password ...", text: $confirmPassword).foregroundColor(SUCCESS)
            }.padding(.horizontal)
            Divider()
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(.footnote)
                Spacer()
                Button("Encrypt & Save") {
                    // let panel = NSOpenPanel()
                    // panel.allowsMultipleSelection = false
                    // panel.canChooseFiles = false
                    // panel.canChooseDirectories = true
                    // if panel.runModal() == .OK {
                    //     filename = panel.url?.lastPathComponent ?? "<none>"
                    // }
                    passphrase = "abc";
                }
                .font(.footnote)
            }.padding(.horizontal)
            Spacer()
            // Text("AES-256-CBC RAND_IV(128) PKCS#5 PBKDF2 SECRAND_SALT(64) MD=SHA512 ITER=250000").font(.footnote).foregroundColor(.gray)
        }.background(Color(red: 0.172, green: 0.315, blue: 0.378)).frame(minWidth: 600, maxWidth: 600, minHeight: 380, maxHeight: 380)
    }
}
