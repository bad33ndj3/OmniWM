// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import CoreGraphics
import Foundation
@testable import OmniWM
import XCTest

@MainActor
final class MonitorRoutingWorkspaceTests: XCTestCase {
    private func makeSettings() -> SettingsStore {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("OmniWMRoutingTests-\(UUID().uuidString)", isDirectory: true)
        addTeardownBlock {
            if FileManager.default.fileExists(atPath: root.path) {
                try FileManager.default.removeItem(at: root)
            }
        }
        return SettingsStore(
            persistence: SettingsFilePersistence(
                directory: root.appendingPathComponent("config", isDirectory: true),
                startWatching: false,
                deferSaves: false
            ),
            runtimeState: RuntimeStateStore(
                directory: root.appendingPathComponent("state", isDirectory: true),
                deferSaves: false
            ),
            autosaveEnabled: false
        )
    }

    private func makeMonitor(_ displayId: CGDirectDisplayID, _ name: String, _ frame: CGRect) -> Monitor {
        Monitor(
            id: .init(displayId: displayId),
            displayId: displayId,
            frame: frame,
            visibleFrame: frame,
            hasNotch: false,
            name: name
        )
    }

    private func routing(
        _ displayId: CGDirectDisplayID,
        _ name: String,
        _ column: Int,
        _ row: Int
    ) -> MonitorRoutingSettings {
        MonitorRoutingSettings(monitorName: name, monitorDisplayId: displayId, gridColumn: column, gridRow: row)
    }

    func testMacOSModeMatchesGeometryNeighbors() {
        let manager = WorkspaceManager(settings: makeSettings())
        let left = makeMonitor(1, "L", CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let right = makeMonitor(2, "R", CGRect(x: 1920, y: 0, width: 1920, height: 1080))
        manager.applyMonitorConfigurationChange([left, right])

        XCTAssertEqual(manager.adjacentMonitor(from: left.id, direction: .right)?.id, right.id)
        XCTAssertEqual(manager.adjacentMonitor(from: right.id, direction: .left)?.id, left.id)
        XCTAssertNil(manager.adjacentMonitor(from: left.id, direction: .up))
    }

    func testMacOSModeRoutesTheCornerTouchHomePortraitLayout() {
        let manager = WorkspaceManager(settings: makeSettings())
        let laptop = makeMonitor(1, "Laptop", CGRect(x: 0, y: 0, width: 1512, height: 982))
        let wide = makeMonitor(2, "Wide", CGRect(x: 1512, y: 982, width: 3440, height: 1440))
        let portrait = makeMonitor(3, "Portrait", CGRect(x: 4952, y: 2422, width: 1080, height: 1920))
        manager.applyMonitorConfigurationChange([laptop, wide, portrait])

        XCTAssertEqual(manager.adjacentMonitor(from: laptop.id, direction: .right)?.id, wide.id)
        XCTAssertEqual(manager.adjacentMonitor(from: wide.id, direction: .right)?.id, portrait.id)
        XCTAssertEqual(manager.adjacentMonitor(from: wide.id, direction: .up)?.id, portrait.id)
        XCTAssertNil(manager.adjacentMonitor(from: laptop.id, direction: .left))
    }

    func testMacOSModeRoutesUpToEitherOfficeScreenWithStableTieBreak() {
        let manager = WorkspaceManager(settings: makeSettings())
        let laptop = makeMonitor(1, "Laptop", CGRect(x: 0, y: 0, width: 1512, height: 982))
        let left = makeMonitor(20, "Left", CGRect(x: -1164, y: 982, width: 1920, height: 1080))
        let right = makeMonitor(10, "Right", CGRect(x: 756, y: 982, width: 1920, height: 1080))
        manager.applyMonitorConfigurationChange([laptop, right, left])

        XCTAssertEqual(manager.adjacentMonitor(from: laptop.id, direction: .up)?.id, left.id)
    }

    func testMacOSModePrefersOverlappingEdgesToACloserDiagonalMonitor() {
        let manager = WorkspaceManager(settings: makeSettings())
        let source = makeMonitor(1, "Source", CGRect(x: 0, y: 0, width: 100, height: 100))
        let overlapping = makeMonitor(2, "Overlapping", CGRect(x: 500, y: 50, width: 100, height: 100))
        let closer = makeMonitor(3, "Closer", CGRect(x: 80, y: 110, width: 50, height: 50))
        manager.applyMonitorConfigurationChange([source, closer, overlapping])

        XCTAssertEqual(manager.adjacentMonitor(from: source.id, direction: .right)?.id, overlapping.id)
    }

    func testMacOSModeAcceptsGappedForwardScreensOutsideThe45DegreeCone() {
        let manager = WorkspaceManager(settings: makeSettings())
        let source = makeMonitor(1, "Source", CGRect(x: 0, y: 0, width: 100, height: 100))
        let diagonal = makeMonitor(2, "Diagonal", CGRect(x: 110, y: 300, width: 100, height: 100))
        manager.applyMonitorConfigurationChange([source, diagonal])

        XCTAssertEqual(manager.adjacentMonitor(from: source.id, direction: .right)?.id, diagonal.id)
    }

    func testMacOSModeChoosesClosestCenterWhenForwardScreensDoNotOverlap() {
        let manager = WorkspaceManager(settings: makeSettings())
        let source = makeMonitor(1, "Source", CGRect(x: 0, y: 0, width: 100, height: 100))
        let smallerGap = makeMonitor(2, "Smaller gap", CGRect(x: 110, y: 300, width: 100, height: 100))
        let closerCenter = makeMonitor(3, "Closer center", CGRect(x: 190, y: 100, width: 100, height: 100))
        manager.applyMonitorConfigurationChange([source, smallerGap, closerCenter])

        XCTAssertEqual(manager.adjacentMonitor(from: source.id, direction: .right)?.id, closerCenter.id)
    }

    func testMacOSModeDoesNotWrapAtAnEdgeUnlessRequested() {
        let manager = WorkspaceManager(settings: makeSettings())
        let right = makeMonitor(1, "Right", CGRect(x: 100, y: 0, width: 100, height: 100))
        let left = makeMonitor(2, "Left", CGRect(x: -100, y: 0, width: 100, height: 100))
        manager.applyMonitorConfigurationChange([right, left])

        XCTAssertNil(manager.adjacentMonitor(from: right.id, direction: .right))
        XCTAssertEqual(manager.adjacentMonitor(from: right.id, direction: .right, wrapAround: true)?.id, left.id)
    }

    func testMacOSModeRoutesOffsetStackedMonitorsByForwardCenter() {
        let manager = WorkspaceManager(settings: makeSettings())
        let top = makeMonitor(1, "Top", CGRect(x: 100, y: 1080, width: 1920, height: 1080))
        let bottom = makeMonitor(2, "Bottom", CGRect(x: 0, y: 0, width: 1920, height: 1080))
        manager.applyMonitorConfigurationChange([top, bottom])

        XCTAssertEqual(manager.adjacentMonitor(from: top.id, direction: .left)?.id, bottom.id)
        XCTAssertEqual(manager.adjacentMonitor(from: bottom.id, direction: .right)?.id, top.id)
        XCTAssertEqual(manager.adjacentMonitor(from: top.id, direction: .down)?.id, bottom.id)
        XCTAssertEqual(manager.adjacentMonitor(from: bottom.id, direction: .up)?.id, top.id)
    }

    func testCustomRoutingDivergesFromMacOSGeometry() {
        let settings = makeSettings()
        let manager = WorkspaceManager(settings: settings)
        let top = makeMonitor(1, "Top", CGRect(x: 0, y: 1080, width: 1920, height: 1080))
        let bottom = makeMonitor(2, "Bottom", CGRect(x: 0, y: 0, width: 1920, height: 1080))
        manager.applyMonitorConfigurationChange([top, bottom])

        XCTAssertNil(manager.adjacentMonitor(from: top.id, direction: .right))

        settings.monitors.routingMode = .custom
        settings.monitors.arrangements = [MonitorArrangement(monitors: [
            routing(1, "Top", 0, 0),
            routing(2, "Bottom", 1, 0)
        ])]

        XCTAssertEqual(manager.adjacentMonitor(from: top.id, direction: .right)?.id, bottom.id)
        XCTAssertEqual(manager.adjacentMonitor(from: bottom.id, direction: .left)?.id, top.id)
        XCTAssertNil(manager.adjacentMonitor(from: top.id, direction: .down))
    }

    func testCustomModeFallsBackToMacOSWhenLayoutMissing() {
        let settings = makeSettings()
        let manager = WorkspaceManager(settings: settings)
        let left = makeMonitor(1, "L", CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let right = makeMonitor(2, "R", CGRect(x: 1920, y: 0, width: 1920, height: 1080))
        manager.applyMonitorConfigurationChange([left, right])

        settings.monitors.routingMode = .custom
        settings.monitors.arrangements = []

        XCTAssertEqual(manager.adjacentMonitor(from: left.id, direction: .right)?.id, right.id)
    }

    func testSeedLayoutReproducesMacOSNeighbors() {
        let topLeft = makeMonitor(1, "TL", CGRect(x: 0, y: 1080, width: 1920, height: 1080))
        let topRight = makeMonitor(2, "TR", CGRect(x: 1920, y: 1080, width: 1920, height: 1080))
        let bottomLeft = makeMonitor(3, "BL", CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let bottomRight = makeMonitor(4, "BR", CGRect(x: 1920, y: 0, width: 1920, height: 1080))
        let monitors = [topLeft, topRight, bottomLeft, bottomRight]
        let layout = MonitorRouting.seedLayout(from: monitors)

        XCTAssertEqual(
            MonitorRouting.gridAdjacent(
                from: topLeft,
                direction: .right,
                layout: layout,
                monitors: monitors,
                wrapAround: false
            ),
            .monitor(topRight)
        )
        XCTAssertEqual(
            MonitorRouting.gridAdjacent(
                from: topLeft,
                direction: .down,
                layout: layout,
                monitors: monitors,
                wrapAround: false
            ),
            .monitor(bottomLeft)
        )
        XCTAssertEqual(
            MonitorRouting.gridAdjacent(
                from: bottomRight,
                direction: .up,
                layout: layout,
                monitors: monitors,
                wrapAround: false
            ),
            .monitor(topRight)
        )
    }

    func testCustomArrangementsSurviveHomeWorkHomeAndSettingsReload() throws {
        let settings = makeSettings()
        let manager = WorkspaceManager(settings: settings)
        let laptop = makeMonitor(1, "Laptop", CGRect(x: 0, y: 0, width: 1440, height: 900))
        let home = makeMonitor(2, "Home", CGRect(x: 1440, y: 0, width: 1920, height: 1080))
        let work = makeMonitor(3, "Work", CGRect(x: 1440, y: 0, width: 1920, height: 1080))
        settings.monitors.routingMode = .custom
        manager.applyMonitorConfigurationChange([laptop, home])
        settings.monitors.storeRoutingLayout(
            [routing(1, "Laptop", 0, 1), routing(2, "Home", 0, 0)],
            for: [laptop, home]
        )
        let homeArrangement = settings.monitors.arrangements[0]
        XCTAssertEqual(manager.adjacentMonitor(from: laptop.id, direction: .up), home)
        XCTAssertNil(manager.adjacentMonitor(from: laptop.id, direction: .right))

        manager.applyMonitorConfigurationChange([laptop, work])
        XCTAssertEqual(manager.adjacentMonitor(from: laptop.id, direction: .right), work)
        XCTAssertEqual(manager.adjacentMonitor(from: laptop.id, direction: .up), work)
        settings.monitors.storeRoutingLayout(
            [routing(1, "Laptop", 0, 0), routing(3, "Work", 1, 0)],
            for: [laptop, work]
        )
        XCTAssertEqual(settings.monitors.arrangements.count, 2)
        XCTAssertEqual(settings.monitors.arrangements[0], homeArrangement)
        manager.applyMonitorConfigurationChange([home, laptop])
        XCTAssertEqual(manager.adjacentMonitor(from: laptop.id, direction: .up), home)
        XCTAssertNil(manager.adjacentMonitor(from: laptop.id, direction: .right))

        let reloaded = makeSettings()
        reloaded.applyExport(try SettingsTOMLCodec.decode(SettingsTOMLCodec.encode(settings.toExport())))
        let restarted = WorkspaceManager(settings: reloaded)
        restarted.applyMonitorConfigurationChange([home, laptop])
        XCTAssertEqual(reloaded.monitors.arrangements, settings.monitors.arrangements)
        XCTAssertEqual(restarted.adjacentMonitor(from: laptop.id, direction: .up), home)
        restarted.applyMonitorConfigurationChange([laptop, work])
        XCTAssertEqual(restarted.adjacentMonitor(from: laptop.id, direction: .right), work)
    }
}
