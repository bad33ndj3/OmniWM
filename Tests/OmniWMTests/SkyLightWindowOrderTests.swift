// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import CoreGraphics
@testable import OmniWM
import XCTest

final class SkyLightWindowOrderTests: XCTestCase {
    @MainActor
    func testCoverageRequiresEligibleWindowAboveTargetWithPartialOverlap() {
        let target = windowInfo(id: 100, frame: CGRect(x: 8, y: 38, width: 1424, height: 854))
        let floating = windowInfo(id: 101, frame: CGRect(x: 258, y: 0, width: 740, height: 900))
        let secondFloating = windowInfo(id: 103, frame: CGRect(x: 300, y: 40, width: 500, height: 700))
        let distant = windowInfo(id: 101, frame: CGRect(x: 1600, y: 38, width: 200, height: 200))
        let edge = windowInfo(id: 101, frame: CGRect(x: 1428, y: 38, width: 200, height: 200))

        XCTAssertEqual(SkyLight.hasOverlappingWindowsAbove(100, among: [101], in: [floating, target]), true)
        XCTAssertEqual(
            SkyLight.overlappingWindowIdsAbove(100, among: [101, 103], in: [floating, secondFloating, target]),
            [101, 103]
        )
        XCTAssertEqual(SkyLight.hasOverlappingWindowsAbove(100, among: [101], in: [target, floating]), false)
        XCTAssertEqual(SkyLight.hasOverlappingWindowsAbove(100, among: [102], in: [floating, target]), false)
        XCTAssertEqual(SkyLight.hasOverlappingWindowsAbove(100, among: [101], in: [distant, target]), false)
        XCTAssertEqual(SkyLight.hasOverlappingWindowsAbove(100, among: [101], in: [edge, target]), false)
    }

    @MainActor
    func testCoverageRequiresReadableTargetAndCandidateFrames() {
        let target = windowInfo(id: 100, frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        let unreadable: [String: Any] = [kCGWindowNumber as String: UInt32(101)]

        XCTAssertNil(SkyLight.hasOverlappingWindowsAbove(100, among: [101], in: []))
        XCTAssertNil(SkyLight.hasOverlappingWindowsAbove(101, among: [100], in: [target, unreadable]))
        XCTAssertNil(SkyLight.hasOverlappingWindowsAbove(100, among: [101], in: [unreadable, target]))
    }

    private func windowInfo(id: UInt32, frame: CGRect) -> [String: Any] {
        [kCGWindowNumber as String: id, kCGWindowBounds as String: frame.dictionaryRepresentation]
    }

    func testOrderingModesMatchSkyLightContract() {
        XCTAssertEqual(SkyLightWindowOrder.above.rawValue, 1)
        XCTAssertEqual(SkyLightWindowOrder.out.rawValue, 0)
        XCTAssertEqual(SkyLightWindowOrder.below.rawValue, -1)
    }
}
