//
//  ChainXSApp.swift
//  ChainXS
//
//  Created by Laurenz Zielinski
//

import SwiftUI

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
                .background(Color.init(red: 0.172, green: 0.315, blue: 0.378))
        }
        .commands {
            CommandGroup(replacing: .systemServices, addition: {})
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_: Notification) {
        ChainXSContext.createSecp256k1Ctx()
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
