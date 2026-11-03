// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import AppKit
@testable import OmniWM
import XCTest

@MainActor
final class NiriMinimapTests: XCTestCase {
    func testLegacySettingsStayOffAndVisibilityRoundTrips() throws {
        var export = SettingsExport.defaults()
        export.niri.minimapVisibility = nil
        let legacy = try SettingsTOMLCodec.decode(SettingsTOMLCodec.encode(export))
        let settings = NiriSettings()
        settings.minimapVisibility = .always
        settings.apply(legacy.niri, baseline: .defaults())
        XCTAssertEqual(settings.minimapVisibility, .off)
        for mode in NiriMinimapVisibility.allCases {
            export.niri.minimapVisibility = mode
            let decoded = try SettingsTOMLCodec.decode(SettingsTOMLCodec.encode(export))
            settings.apply(decoded.niri, baseline: .defaults())
            XCTAssertEqual(settings.minimapVisibility, mode)
            XCTAssertEqual(settings.export(), decoded.niri)
        }
    }

    func testPanelStaysInsideTopRightOnOffsetDisplays() {
        for frame in [
            CGRect(x: -1920, y: 900, width: 1920, height: 1080),
            CGRect(x: 100, y: -1200, width: 1080, height: 1920)
        ] {
            let panel = NiriMinimapGeometry.panelFrame(in: frame)
            XCTAssertEqual(frame.maxX - panel.maxX, 16)
            XCTAssertEqual(frame.maxY - panel.maxY, 16)
            XCTAssertTrue(frame.contains(panel))
            XCTAssertEqual(panel.width, 140)
        }
    }

    func testOverscrollAndPortraitViewportNormalizeWithoutLosingDestinations() throws {
        let content = CGRect(x: -100, y: 0, width: 1200, height: 600)
        let viewport = try XCTUnwrap(NiriMinimapGeometry.normalized(
            CGRect(x: -100, y: 0, width: 600, height: 600), in: content
        ))
        XCTAssertEqual(viewport.minX, 0)
        XCTAssertEqual(viewport.width, 0.5)
        let tile = try XCTUnwrap(NiriMinimapGeometry.normalized(
            CGRect(x: 800, y: 0, width: 300, height: 300), in: content
        ))
        XCTAssertEqual(tile.maxX, 1)
        XCTAssertEqual(tile.height, 0.5)
        let portrait = try XCTUnwrap(NiriMinimapGeometry.normalized(
            CGRect(x: 0, y: 600, width: 300, height: 600),
            in: CGRect(x: 0, y: 0, width: 600, height: 1800)
        ))
        XCTAssertEqual(portrait.width, 0.5)
        XCTAssertEqual(portrait.minY, 1.0 / 3, accuracy: 0.0001)
        XCTAssertEqual(portrait.height, 1.0 / 3, accuracy: 0.0001)
        XCTAssertNil(NiriMinimapGeometry.normalized(.zero, in: content))
        XCTAssertNil(NiriMinimapGeometry.normalized(content, in: .null))
    }

    func testOutlinesHaveAccessibleClickTargetsWithoutMakingPanelKey() {
        _ = NSApplication.shared
        let panel = NiriMinimapPanel(
            contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false
        )
        XCTAssertFalse(panel.canBecomeKey)
        XCTAssertFalse(panel.canBecomeMain)
        let token = WindowToken(pid: 42, windowId: 7)
        let view = NiriMinimapView(frame: CGRect(origin: .zero, size: NiriMinimapGeometry.size))
        panel.contentView = view
        var selected: WindowToken?
        view.onSelect = { selected = $0 }
        view.apply(NiriMinimapSnapshot(
            workspaceId: UUID(),
            tiles: [.init(token: token, frame: CGRect(x: 0, y: 0, width: 0.5, height: 1), label: "Editor")],
            viewport: CGRect(x: 0, y: 0, width: 0.5, height: 1), selectedToken: token
        ))
        let button = view.subviews.first as? NSButton
        XCTAssertEqual(button?.accessibilityLabel(), "Editor")
        button?.performClick(nil)
        XCTAssertEqual(selected, token)
    }
}
