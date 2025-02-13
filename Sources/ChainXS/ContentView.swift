//
//  ContentView.swift
//  ChainXS
//
//  Created by raidshift
//

import SwiftUI

extension NSTextField {
    override open var focusRingType: NSFocusRingType {
        get { .none }
        set {}
    }
}

struct Key: Equatable {
    var name: String
    var id: Int
}

struct UserProvidedKeys: Equatable {
    var key: String = ""
    var passphrase: String = ""
}

struct DerivationData: Equatable {
    var key: Data = .init()
    var path: String = ""
    var selectedLevel = 1
    var maxLevel = 1
    var selectedCount = 9
    var selectedKeys: [Int] = []
    var isExtendedKey = false
    var isPrivate = true
}

struct ContentView: View {
    @State var userProvidedKeys = UserProvidedKeys()
    @State var derivationData = DerivationData()
    @State var decomomposedDerivationPath = DecomposedDerivationPath(pathNodeIndexes: [], isPrivate: false)
    @State var mnemonicColor: Color = FAILURE
    @State var derivationpathColor: Color = FAILURE
    @State var results: [String] = []
    @State var isDisabledTextField = true
    @State var dividerSets = false
    @State var showingSheet = false
    @State var password: String = ""
    @State var document = EncDocument(text: "")
    @State var exporting = false
    @State var importing: Bool = false
    @State var alert = false
    @State var alertMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    HStack {
                        Text("Mnemonic or Extended Key").font(.headline)
                        Spacer()
                        Button(action: { userProvidedKeys.key = try! createMnemonic(16) }) { Text("🎲 12").font(.footnote).bold() }
                        Button(action: { userProvidedKeys.key = try! createMnemonic(24) }) { Text("🎲 18").font(.footnote).bold() }
                        Button(action: { userProvidedKeys.key = try! createMnemonic(32) }) { Text("🎲 24").font(.footnote).bold() }
                        Button(action: { userProvidedKeys.key = ""; userProvidedKeys.passphrase = "" }) { Text("✖️").font(.footnote).bold() }
                    }
                    Divider()
                    HStack {
                        CustomTextField(title: "enter password ...", text: $password).foregroundColor(SUCCESS).disabled(isDisabledTextField).frame(width: 120)
                        Button(action: {
                            let messageContainer = MessageContainer(key: userProvidedKeys.key.trimmingCharacters(in: .whitespaces), passphrase: userProvidedKeys.passphrase, path: derivationData.path, level: derivationData.selectedLevel)

                            let encoder = JSONEncoder()
                            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]

                            do {
                                var passwordData = try password.data(using: .utf8) ?? { throw NOXS_ERR.DATA }()
                                var cipherData: Data = try encoder.encode(messageContainer)
                                let ciphertext: Data = try encrypt(password: &passwordData, plaintext: &cipherData, ver: .X)
                                document = EncDocument(text: ciphertext.base64EncodedString())
                                exporting = true
                            } catch {
                                alertMessage = error.localizedDescription
                                alert = true
                            }
                        }) { Text("🔐").font(.footnote).bold() }
                            .disabled(password.isEmpty || derivationpathColor == FAILURE || mnemonicColor == FAILURE)
                            .fileExporter(
                                isPresented: $exporting,
                                document: document,
                                contentType: .data,
                                defaultFilename: DEFAULT_FILENAME
                            ) { result in
                                switch result {
                                case let .failure(error):
                                    alertMessage = error.localizedDescription
                                    alert = true
                                case .success:
                                    password = ""
                                }
                            }
                        Button(action: {
                            importing = true
                        }) { Text("🔓").font(.footnote).bold() }
                            .disabled(password.isEmpty)
                            .fileImporter(
                                isPresented: $importing,
                                allowedContentTypes: [.data]
                            ) { result in
                                switch result {
                                case let .success(fileURL):
                                    do {
                                        let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
                                        defer { if didStartAccessing { fileURL.stopAccessingSecurityScopedResource() }}
                                        let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                                        if try resourceValues.fileSize ?? { throw FILE_ERR.READ_SIZE }() > MAX_FILE_SIZE { throw FILE_ERR.SIZE }
                                        var passwordData = try password.data(using: .utf8) ?? { throw NOXS_ERR.DATA }()
                                        var cipherData = try Data(contentsOf: fileURL)
                                        cipherData = try Data(base64Encoded: cipherData) ?? { throw DATA_ERR.FORMAT_BASE64 }()
                                        let plaintext = try decrypt(password: &passwordData, ciphertext: &cipherData)

                                        do {
                                            let decoder = JSONDecoder()
                                            let message = try decoder.decode(MessageContainer.self, from: plaintext)
                                            userProvidedKeys.key = message.key
                                            userProvidedKeys.passphrase = message.passphrase
                                            derivationData.path = message.path
                                            derivationData.selectedLevel = message.level
                                            password = ""
                                        } catch {
                                            throw NOXS_ERR.DATA
                                        }

                                    } catch {
                                        alertMessage = error.localizedDescription
                                        alert = true
                                    }
                                case let .failure(error):
                                    alertMessage = error.localizedDescription
                                    alert = true
                                }
                            }
                            .alert(alertMessage, isPresented: $alert) {
                                Button("OK", role: .cancel) {}
                            }
                    }
                }
                CustomTextField(title: "enter mnemonic or extended key ...", text: $userProvidedKeys.key)
                    .foregroundColor(mnemonicColor)
                    .onChange(of: userProvidedKeys.key) { newValue in
                        // Filter to allow only letters, numbers and spaces
                        let filtered = newValue.filter { $0.isLetter || $0.isNumber || $0.isWhitespace }

                        // Tokenize by splitting on whitespace and filter out empty strings
                        let tokens = filtered.split { $0.isWhitespace }
                            .map(String.init)
                            .filter { !$0.isEmpty }

                        // Rejoin with single spaces and preserve trailing space if it exists
                        userProvidedKeys.key = tokens.joined(separator: " ") + (newValue.hasSuffix(" ") ? " " : "")
                    }
                    .disabled(isDisabledTextField)
                    .padding(8)
                if !derivationData.isExtendedKey && mnemonicColor != FAILURE {
                    Text("Mnemonic Passphrase").font(.headline)

                    CustomTextField(title: "enter optional mnemonic passphrase ...", text: $userProvidedKeys.passphrase)
                        .foregroundColor(SUCCESS)
                        .disabled(isDisabledTextField)
                        .padding(8)
                }
                HStack {
                    Text("Derivation Path").font(.headline)
                    Spacer()
                    Menu {
                        Button(action: { derivationData.path = DERIVATION_PATHS[.DEFAULT_PRIVATE_DERIVATION_PATH]!.path; derivationData.selectedLevel = DERIVATION_PATHS[.DEFAULT_PRIVATE_DERIVATION_PATH]!.atLevel }) { Text(DERIVATION_PATHS[.DEFAULT_PRIVATE_DERIVATION_PATH]!.desc) }
                        Button(action: { derivationData.path = DERIVATION_PATHS[.DEFAULT_PUBLIC_DERIVATION_PATH]!.path; derivationData.selectedLevel = DERIVATION_PATHS[.DEFAULT_PUBLIC_DERIVATION_PATH]!.atLevel }) { Text(DERIVATION_PATHS[.DEFAULT_PUBLIC_DERIVATION_PATH]!.desc) }
                        Divider()
                        Button(action: { derivationData.path = DERIVATION_PATHS[.BIP44_BTC_DERIVATION_PATH]!.path; derivationData.selectedLevel = DERIVATION_PATHS[.BIP44_BTC_DERIVATION_PATH]!.atLevel }) { Text(DERIVATION_PATHS[.BIP44_BTC_DERIVATION_PATH]!.desc) }
                        Button(action: { derivationData.path = DERIVATION_PATHS[.BIP44_ETH_DERIVATION_PATH]!.path; derivationData.selectedLevel = DERIVATION_PATHS[.BIP44_ETH_DERIVATION_PATH]!.atLevel }) { Text(DERIVATION_PATHS[.BIP44_ETH_DERIVATION_PATH]!.desc) }
                        Button(action: { derivationData.path = DERIVATION_PATHS[.BIP44_TRX_DERIVATION_PATH]!.path; derivationData.selectedLevel = DERIVATION_PATHS[.BIP44_TRX_DERIVATION_PATH]!.atLevel }) { Text(DERIVATION_PATHS[.BIP44_TRX_DERIVATION_PATH]!.desc) }
                        Button(action: { derivationData.path = DERIVATION_PATHS[.BIP44_KAS_DERIVATION_PATH]!.path; derivationData.selectedLevel = DERIVATION_PATHS[.BIP44_KAS_DERIVATION_PATH]!.atLevel }) { Text(DERIVATION_PATHS[.BIP44_KAS_DERIVATION_PATH]!.desc) }
                        Divider()
                        Button(action: { derivationData.path = DERIVATION_PATHS[.BIP49_BTC_DERIVATION_PATH]!.path; derivationData.selectedLevel = DERIVATION_PATHS[.BIP49_BTC_DERIVATION_PATH]!.atLevel }) { Text(DERIVATION_PATHS[.BIP49_BTC_DERIVATION_PATH]!.desc) }
                        Divider()
                        Button(action: { derivationData.path = DERIVATION_PATHS[.BIP84_BTC_DERIVATION_PATH]!.path; derivationData.selectedLevel = DERIVATION_PATHS[.BIP84_BTC_DERIVATION_PATH]!.atLevel }) { Text(DERIVATION_PATHS[.BIP84_BTC_DERIVATION_PATH]!.desc) }
                    } label: {
                        Text("...").fontWeight(.bold).font(.headline)
                    }
                    .menuIndicator(.hidden)
                    .fixedSize()
                }
                HStack {
                    CustomTextField(title: "enter derivation path ...", text: $derivationData.path)
                        .foregroundColor(derivationpathColor)
                        .disabled(isDisabledTextField)
                        .padding(8)
                    Text("Derive level").font(.headline)
                    Stepper("\(derivationData.selectedLevel)", value: $derivationData.selectedLevel, in: 1 ... derivationData.maxLevel).foregroundColor(derivationpathColor)
                }
                Divider()
                HStack {
                    Text("Columns").font(.headline)
                    ForEach(derivationData.selectedKeys, id: \.self) { id in
                        Button(action: {
                            derivationData.selectedKeys.removeAll { value in value == id }
                        }) {
                            Text("\(KEYS[id]!) ✖️").font(.footnote)
                        }.disabled(derivationData.selectedKeys.count < 1 ? true : false)
                    }
                    Menu {
                        ForEach(0 ... KEY_LAST_ELEMENT, id: \.self) { id in
                            Button(KEYS[id]!, action: {
                                derivationData.selectedKeys.append(id)
                            }).disabled(derivationData.selectedKeys.contains(id) || (id > PRIV_KEYS_AFTER && !decomomposedDerivationPath.isPrivate) ? true : false)

                            if id == PRIV_KEYS_AFTER {
                                Divider()
                            }
                        }
                    } label: {
                        Text("+").fontWeight(.bold).font(.headline)
                    }
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .disabled(derivationData.selectedKeys.count > 3 ? true : false)
                    Divider()
                    Text("Rows").font(.headline)
                    Stepper("\(derivationData.selectedCount)", value: $derivationData.selectedCount, in: 1 ... 50).foregroundColor(derivationpathColor)
                }
                VStack(alignment: .leading) {
                    ForEach(results, id: \.self) {
                        Text($0).textSelection(.enabled).foregroundColor(SUCCESS).font(MONO_FONT).lineLimit(1)
                    }
                }
                .padding(.top, 8)
                Spacer()
            }
            .padding(.horizontal)
            .onChange(of: userProvidedKeys) { _ in
                do {
                    derivationData.key = try createMnemonicSeed(mnemonic: userProvidedKeys.key, passPhrase: userProvidedKeys.passphrase)
                    derivationData.isPrivate = true
                    derivationData.isExtendedKey = false
                    mnemonicColor = SUCCESS
                    userProvidedKeys.key = userProvidedKeys.key.lowercased()

                } catch {
                    do {
                        let extendedKey = try decomposeExtendedKey(extendedKey: userProvidedKeys.key)
                        derivationData.key = extendedKey.key
                        derivationData.isPrivate = extendedKey.isPrivate
                        derivationData.isExtendedKey = true
                        mnemonicColor = SUCCESS
                        userProvidedKeys.passphrase = ""
                        if !extendedKey.isPrivate, decomomposedDerivationPath.isPrivate {
                            derivationData.path = DERIVATION_PATHS[.DEFAULT_PUBLIC_DERIVATION_PATH]!.path
                            derivationData.selectedLevel = DERIVATION_PATHS[.DEFAULT_PUBLIC_DERIVATION_PATH]!.atLevel
                        }
                    } catch {
                        derivationData.key = Data()
                        derivationData.isPrivate = true
                        derivationData.isExtendedKey = false
                        mnemonicColor = FAILURE
                    }
                }
                if mnemonicColor != SUCCESS { results = [] }
            }
            .onChange(of: derivationData) { _ in
                do {
                    decomomposedDerivationPath = try decomposeDerivationPath(derivationData.path, allowZeroNodeIndexes: false, allowPrivate: derivationData.isPrivate)
                    if derivationData.selectedLevel > decomomposedDerivationPath.pathNodeIndexes.count {
                        derivationData.selectedLevel = decomomposedDerivationPath.pathNodeIndexes.count
                    }
                    derivationData.maxLevel = decomomposedDerivationPath.pathNodeIndexes.count

                    if !decomomposedDerivationPath.isPrivate {
                        for key in derivationData.selectedKeys {
                            if key > PRIV_KEYS_AFTER {
                                derivationData.selectedKeys.removeAll { value in value == key }
                            }
                        }
                    }

                    derivationpathColor = SUCCESS
                } catch {
                    decomomposedDerivationPath = DecomposedDerivationPath(pathNodeIndexes: [], isPrivate: false)
                    derivationpathColor = FAILURE
                }

                if mnemonicColor == SUCCESS, derivationpathColor == SUCCESS {
                    let rootHDN: HDNode

                    if derivationData.isExtendedKey {
                        rootHDN = try! HDNode(extendedKey: userProvidedKeys.key)
                    } else {
                        let masterKey = try! createMasterKey(derivationData.key)
                        rootHDN = try! HDNode(key: masterKey.left, isPrivateKey: true, chainCode: masterKey.right)
                    }

                    var selectedCount = derivationData.selectedCount
                    var tmpDecomomposedDerivationPath = decomomposedDerivationPath

                    if selectedCount > 1 {
                        let max = tmpDecomomposedDerivationPath.maxChildrenDerivable(atIndex: derivationData.selectedLevel - 1)
                        if max < selectedCount {
                            selectedCount = max + 1
                        }
                    }

                    results = []
                    var maxIdx = decomomposedDerivationPath.pathNodeIndexes[derivationData.selectedLevel - 1] + UInt32(selectedCount - 1)
                    maxIdx = maxIdx >= HARDENED_KEY_TRESHOLD ? maxIdx - HARDENED_KEY_TRESHOLD : maxIdx

                    for i in 0 ..< selectedCount {
                        tmpDecomomposedDerivationPath.pathNodeIndexes[derivationData.selectedLevel - 1] = decomomposedDerivationPath.pathNodeIndexes[derivationData.selectedLevel - 1] + UInt32(i)
                        let strPath = tmpDecomomposedDerivationPath.toString()

                        var minIdx = decomomposedDerivationPath.pathNodeIndexes[derivationData.selectedLevel - 1] + UInt32(i)
                        minIdx = minIdx >= HARDENED_KEY_TRESHOLD ? minIdx - HARDENED_KEY_TRESHOLD : minIdx

                        let padCnt = "\(maxIdx)".count - "\(minIdx)".count
                        let strPathWithPad = strPath.padding(toLength: "\(strPath)".count + padCnt, withPad: " ", startingAt: 0)
                        let childHDN = try! rootHDN.ckdFromDerivationPath(decomomposedDerivationPath: tmpDecomomposedDerivationPath)

                        var result = strPathWithPad
                        for key in derivationData.selectedKeys {
                            result = "\(result)  \(try! childHDN.getKeyOrAddressByKey(key))"
                        }
                        results.append(result)
                    }
                }
            }
            .onAppear {
                userProvidedKeys.key = try! createMnemonic(16)
                userProvidedKeys.passphrase = ""
                derivationData.path = DERIVATION_PATHS[.DEFAULT_PRIVATE_DERIVATION_PATH]!.path
                derivationData.selectedLevel = DERIVATION_PATHS[.DEFAULT_PRIVATE_DERIVATION_PATH]!.atLevel
                derivationData.selectedKeys = [ETH_ADDRESS_KEY]
                Task {
                    isDisabledTextField = false
                }
            }
        }
        .frame(minWidth: MIN_W, minHeight: MIN_H)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
