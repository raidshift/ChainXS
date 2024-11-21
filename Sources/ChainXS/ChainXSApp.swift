//
//  ChainXSApp.swift
//  ChainXS
//
//  Created by raidshift
//

import SwiftUI
import UniformTypeIdentifiers

let MIN_W: CGFloat = 800
let MIN_H: CGFloat = 400

let SUCCESS = Color.green
let FAILURE = Color.red

let MONO_FONT = Font
    .system(size: 12)
    .monospaced()

let MONO_FONT_SM = Font
    .system(size: 10)
    .monospaced()

let DEFAULT_FILENAME = "key"
let MAX_FILE_SIZE = 10240

struct MessageContainer: Codable {
    var key: String
    var passphrase: String
    var path: String
    var level: Int
}

public enum FILE_ERR: Error {
    case READ_SIZE
    case SIZE
}

extension FILE_ERR: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .READ_SIZE:
            return NSLocalizedString("Unable to read files size", comment: "Unable to read file size")
        case .SIZE:
            return NSLocalizedString("File size exceeds limit of \(MAX_FILE_SIZE / 1024) KiB", comment: "File size exceeds limit of \(MAX_FILE_SIZE / 1024) KiB")
        }
    }
}

struct EncDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.data]
    }

    var text = ""

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

struct CustomTextField: View {
    var title: String
    var text: Binding<String>

    var body: some View {
        TextField(title, text: text)
            .lineLimit(1)
            .disableAutocorrection(true)
            .textFieldStyle(PlainTextFieldStyle())
    }
}

@main
struct ChainXSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
                .preferredColorScheme(.dark)
                .background(Color(red: 0.172, green: 0.315, blue: 0.378))
        }
        .commands {
            CommandGroup(replacing: .systemServices, addition: {})
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

func exitWithError(_ out: String) {
    (out + "\n").data(using: .utf8).map(FileHandle.standardError.write); exit(1)
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_: Notification) {
        do { try ChainXSContext.createSecp256k1Ctx() } catch { exitWithError(error.localizedDescription) }
        ChainXSContext.setNetwork(.MAIN)
        UserDefaults.standard.set(true, forKey: "NSDisabledDictationMenuItem")
        UserDefaults.standard.set(true, forKey: "NSDisabledCharacterPaletteMenuItem")
    }

    func applicationDidBecomeActive(_: Notification) {
        ["Help", "Window", "File"].forEach { name in
            NSApp.mainMenu?.item(withTitle: name).map { NSApp.mainMenu?.removeItem($0) }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_: Notification) {
        ChainXSContext.destroySecp256k1Ctx()
    }
}
