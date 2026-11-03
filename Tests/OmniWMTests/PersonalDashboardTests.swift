// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import AppKit
@testable import OmniWM
import XCTest

@MainActor
final class PersonalDashboardTests: XCTestCase {
    func testReopeningTheAppShowsTheDashboard() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settings = SettingsStore(
            persistence: SettingsFilePersistence(directory: directory, startWatching: false, deferSaves: false),
            runtimeState: RuntimeStateStore(directory: directory.appendingPathComponent("state"), deferSaves: false),
            autosaveEnabled: false
        )
        let controller = WMController(settings: settings)
        let bootstrap = AppBootstrapState()
        bootstrap.settings = settings
        bootstrap.controller = controller
        let previousBootstrap = AppDelegate.sharedBootstrap
        AppDelegate.sharedBootstrap = bootstrap
        defer {
            controller.personalDashboardController.dismiss()
            AppDelegate.sharedBootstrap = previousBootstrap
        }
        let delegate: any NSApplicationDelegate = AppDelegate()
        XCTAssertEqual(delegate.applicationShouldHandleReopen?(NSApplication.shared, hasVisibleWindows: false), false)
        XCTAssertEqual(controller.focusPolicyEngine.activeLease?.owner, .personalDashboard)
    }

    func testSourceFallbackUsesClosestWindowWithStableTieBreak() {
        let near = WindowToken(pid: 100, windowId: 2)
        let far = WindowToken(pid: 100, windowId: 3)
        let moved = CGRect(x: 500, y: 0, width: 100, height: 100)
        let nearFrame = CGRect(x: 600, y: 0, width: 100, height: 100)
        let farFrame = CGRect(x: 100, y: 0, width: 100, height: 100)
        XCTAssertEqual(
            PersonalDashboardController.nearest(to: moved, candidates: [(far, farFrame), (near, nearFrame)]),
            near
        )
        XCTAssertEqual(
            PersonalDashboardController.nearest(to: moved, candidates: [(far, nearFrame), (near, nearFrame)]),
            near
        )
        XCTAssertNil(PersonalDashboardController.nearest(to: moved, candidates: []))
    }

    func testDashboardLeasePausesHoverUntilReleased() {
        let engine = FocusPolicyEngine()
        engine.screenshotSelectionActiveProvider = { false }
        engine.beginLease(owner: .personalDashboard, reason: "personal_dashboard", duration: nil)
        XCTAssertFalse(engine.evaluate(.focusFollowsMouse).allowsFocusChange)
        engine.beginLease(owner: .nativeMenu, reason: "menu", duration: nil)
        engine.endLease(owner: .nativeMenu)
        XCTAssertFalse(engine.evaluate(.focusFollowsMouse).allowsFocusChange)
        engine.endLease(owner: .personalDashboard)
        XCTAssertTrue(engine.evaluate(.focusFollowsMouse).allowsFocusChange)
    }

    func testDismissDropsCachedHoverBeforeReleasingTheLease() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settings = SettingsStore(
            persistence: SettingsFilePersistence(directory: directory, startWatching: false, deferSaves: false),
            runtimeState: RuntimeStateStore(directory: directory.appendingPathComponent("state"), deferSaves: false),
            autosaveEnabled: false
        )
        let controller = WMController(settings: settings)
        controller.mouseEventHandler.state.latestFocusFollowsMouseSample = .init(
            location: CGPoint(x: 10, y: 10), modifiersRawValue: 0, windowIdUnderPointer: nil
        )
        controller.focusPolicyEngine.beginLease(owner: .personalDashboard, reason: "test", duration: nil)
        controller.personalDashboardController.dismiss()
        XCTAssertFalse(controller.mouseEventHandler.hasLatestFocusFollowsMouseSample)
        XCTAssertNil(controller.focusPolicyEngine.activeLease)
    }
}
