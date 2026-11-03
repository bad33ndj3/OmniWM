// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import AppKit
import SwiftUI

@main
enum DashboardApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = DashboardDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
final class DashboardDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let panel = DashboardPanel(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 720),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered, defer: false
        )
        panel.title = "OmniWM Dashboard Dev · Alleen kijken"
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        let inventory = Inventory()
        panel.refresh = inventory.refresh
        panel
            .contentView = NSHostingView(rootView: DashboardView(inventory: inventory) { [weak panel] in
                panel?.orderOut(nil)
            })
        panel.center()
        self.panel = panel

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "Werkruimte")
        let menu = NSMenu()
        menu.addItem(withTitle: "Toon werkruimte", action: #selector(show), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Stop dashboard", action: #selector(quit), keyEquivalent: "q")
        for item in menu.items { item.target = self }
        item.menu = menu
        statusItem = item
        show()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        show()
        return true
    }

    @objc private func show() {
        panel?.makeKeyAndOrderFront(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
