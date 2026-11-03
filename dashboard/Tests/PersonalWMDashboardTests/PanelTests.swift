// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import AppKit
@testable import PersonalWMDashboard
import XCTest

final class PanelTests: XCTestCase {
    @MainActor
    func testEscapeHidesOnlyTheDashboardPanel() throws {
        _ = NSApplication.shared
        let panel = DashboardPanel(
            contentRect: CGRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.nonactivatingPanel], backing: .buffered, defer: false
        )
        panel.isReleasedWhenClosed = false
        defer { panel.close() }
        panel.orderFront(nil)
        XCTAssertTrue(panel.isVisible)
        panel.sendEvent(try key(code: 53, characters: "\u{1b}"))
        XCTAssertFalse(panel.isVisible)
    }

    @MainActor
    func testCommandRCallsRefreshOnce() throws {
        _ = NSApplication.shared
        let panel = DashboardPanel(
            contentRect: CGRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.nonactivatingPanel], backing: .buffered, defer: false
        )
        panel.isReleasedWhenClosed = false
        defer { panel.close() }
        var refreshes = 0
        panel.refresh = { refreshes += 1 }
        panel.sendEvent(try key(code: 15, characters: "r", modifiers: .command))
        XCTAssertEqual(refreshes, 1)
    }

    @MainActor
    private func key(code: UInt16, characters: String, modifiers: NSEvent.ModifierFlags = []) throws -> NSEvent {
        try XCTUnwrap(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: modifiers,
            timestamp: 0, windowNumber: 0, context: nil,
            characters: characters, charactersIgnoringModifiers: characters,
            isARepeat: false, keyCode: code
        ))
    }
}
