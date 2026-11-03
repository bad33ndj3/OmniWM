// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import AppKit

@MainActor
final class NiriMinimapView: NSView {
    private var snapshot: NiriMinimapSnapshot?
    var onSelect: ((WindowToken) -> Void)?
    override var isFlipped: Bool {
        true
    }

    func apply(_ snapshot: NiriMinimapSnapshot) {
        guard snapshot != self.snapshot else { return }
        let tokensChanged = self.snapshot?.tiles.map(\.token) != snapshot.tiles.map(\.token)
        self.snapshot = snapshot
        needsDisplay = true
        if tokensChanged { subviews.forEach { $0.removeFromSuperview() } }
        let area = bounds.insetBy(dx: 8, dy: 8)
        for (index, tile) in snapshot.tiles.enumerated() {
            let button = tokensChanged ? NiriMinimapButton(frame: .zero) : subviews[index] as? NiriMinimapButton
            guard let button else { continue }
            button.frame = NiriMinimapGeometry.scaled(tile.frame, in: area)
            button.token = tile.token
            button.selected = tile.token == snapshot.selectedToken
            button.title = ""
            button.isBordered = false
            button.toolTip = tile.label
            button.setAccessibilityLabel(tile.label)
            button.setAccessibilityHelp(String(localized: "Focus and reveal this window"))
            button.target = self
            button.action = #selector(selectWindow(_:))
            if tokensChanged { addSubview(button) }
            button.needsDisplay = true
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let background = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 8, yRadius: 8)
        let opacity: CGFloat = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency ? 1 : 0.68
        NSColor.windowBackgroundColor.withAlphaComponent(opacity).setFill()
        background.fill()
        NSColor.labelColor.withAlphaComponent(0.18).setStroke()
        background.lineWidth = 1
        background.stroke()
        guard let snapshot else { return }
        let viewport = NiriMinimapGeometry.scaled(snapshot.viewport, in: bounds.insetBy(dx: 8, dy: 8))
        let outline = NSBezierPath(roundedRect: viewport.insetBy(dx: -3, dy: -3), xRadius: 3, yRadius: 3)
        NSColor.controlAccentColor.withAlphaComponent(0.75).setStroke()
        outline.lineWidth = 1
        outline.stroke()
    }

    @objc private func selectWindow(_ sender: NiriMinimapButton) {
        if let token = sender.token { onSelect?(token) }
    }
}

@MainActor
private final class NiriMinimapButton: NSButton {
    var token: WindowToken?
    var selected = false

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 1.5, dy: 1.5)
        let path = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)
        let color: NSColor = selected ? .controlAccentColor : .labelColor
        color.withAlphaComponent(selected ? 0.28 : 0.08).setFill()
        path.fill()
        color.withAlphaComponent(selected ? 1 : 0.55).setStroke()
        path.lineWidth = selected ? 1.5 : 1
        path.stroke()
    }
}

@MainActor
final class NiriMinimapPanel: NSPanel {
    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
}
