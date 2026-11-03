// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import AppKit

@MainActor
public final class DashboardPanel: NSPanel {
    public var refresh: (() -> Void)?
    public var hide: (() -> Void)?

    override public var canBecomeKey: Bool {
        true
    }

    override public func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            if event.keyCode == 53 {
                if let hide { hide() } else { orderOut(nil) }
                return
            }
            if event.charactersIgnoringModifiers == "r",
               event.modifierFlags.intersection([.command, .control, .option, .shift]) == .command
            {
                refresh?()
                return
            }
        }
        super.sendEvent(event)
    }
}
