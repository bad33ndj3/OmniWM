// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import AppKit
@testable import PersonalWMDashboard
import XCTest

final class InventoryTests: XCTestCase {
    @MainActor
    func testMoveRefreshWaitsForTheWindowServerDestination() async {
        var samples: [CGDirectDisplayID?] = [1, 1, 2]
        var reads = 0
        let confirmed = await Inventory.waitForDisplay(2) {
            reads += 1
            return samples.removeFirst()
        }
        XCTAssertTrue(confirmed)
        XCTAssertEqual(reads, 3)
    }

    @MainActor
    func testMoveRefreshStopsWhenTheWindowDoesNotAppear() async {
        var reads = 0
        let confirmed = await Inventory.waitForDisplay(2) {
            reads += 1
            return nil
        }
        XCTAssertFalse(confirmed)
        XCTAssertEqual(reads, 10)
    }

    private let displays = [
        DisplayRecord(id: 1, name: "Laptop", frame: CGRect(x: 0, y: 0, width: 1440, height: 900)),
        DisplayRecord(id: 2, name: "Portret", frame: CGRect(x: 1440, y: -800, width: 1080, height: 1920))
    ]

    func testPhysicalArrangementKeepsNegativeOriginsAndAspectRatio() throws {
        let frames = DisplayRecord.diagramFrames(displays, size: CGSize(width: 504, height: 384))
        let laptop = try XCTUnwrap(frames[1])
        let portrait = try XCTUnwrap(frames[2])
        XCTAssertEqual(laptop.width, 288, accuracy: 0.001)
        XCTAssertEqual(portrait.height, 384, accuracy: 0.001)
        XCTAssertEqual(laptop.maxX, portrait.minX, accuracy: 0.001)
        XCTAssertGreaterThan(laptop.minY, portrait.minY)
        XCTAssertTrue(DisplayRecord.diagramFrames([], size: .zero).isEmpty)
    }

    func testWindowUsesLargestOverlapAndRetainsPosition() throws {
        let frame = CGRect(x: 1400, y: 50, width: 800, height: 600)
        let window = try XCTUnwrap(WindowRecord(info: row(frame: frame), displays: displays, ownPID: 99))
        XCTAssertEqual(window.displayID, 2)
        XCTAssertEqual(window.frame, frame)
        XCTAssertEqual(window.title, "")
        XCTAssertEqual(window.app, "Testapp")
        XCTAssertNil(DisplayRecord.containing(CGRect(x: -1000, y: 0, width: 10, height: 10), in: displays))
    }

    func testRejectsOwnWindowsOverlaysAndMalformedBounds() {
        XCTAssertNil(WindowRecord(info: row(), displays: displays, ownPID: 42))
        var overlay = row()
        overlay[kCGWindowLayer as String] = 3
        XCTAssertNil(WindowRecord(info: overlay, displays: displays, ownPID: 99))
        var malformed = row()
        malformed[kCGWindowBounds as String] = ["X": "invalid"]
        XCTAssertNil(WindowRecord(info: malformed, displays: displays, ownPID: 99))
        XCTAssertNil(WindowRecord(info: row(frame: .zero), displays: displays, ownPID: 99))
        var infinite = row()
        infinite[kCGWindowBounds as String] = ["X": Double.infinity, "Y": 0, "Width": 800, "Height": 600]
        XCTAssertNil(WindowRecord(info: infinite, displays: displays, ownPID: 99))
    }

    private func row(frame: CGRect = CGRect(x: 10, y: 20, width: 800, height: 600)) -> [String: Any] {
        [
            kCGWindowNumber as String: UInt32(7),
            kCGWindowOwnerPID as String: Int32(42),
            kCGWindowLayer as String: 0,
            kCGWindowOwnerName as String: "Testapp",
            kCGWindowBounds as String: frame.dictionaryRepresentation
        ]
    }
}
