// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import AppKit
import CoreTransferable
@testable import PersonalWMDashboard
import UniformTypeIdentifiers
import XCTest

final class WindowDragTests: XCTestCase {
    func testDragExportsDataThatTheDropDestinationCanImport() {
        let exported = WindowDrag.exportedContentTypes(visibility: .ownProcess)
        let imported = WindowDrag.importedContentTypes()
        XCTAssertFalse(exported.isEmpty)
        XCTAssertTrue(exported.allSatisfy { $0.conforms(to: .data) })
        XCTAssertTrue(exported.contains { imported.contains($0) })
    }

    func testNativeItemProviderRecognizesAndLoadsTheDraggedWindow() async throws {
        let provider = NSItemProvider()
        provider.register(WindowDrag(pid: 42, windowID: 7))
        XCTAssertTrue(provider.hasItemConformingToTypeIdentifier(UTType.json.identifier))
        let restored: WindowDrag = try await withCheckedThrowingContinuation { continuation in
            _ = provider.loadTransferable(type: WindowDrag.self) { result in
                continuation.resume(with: result)
            }
        }
        XCTAssertEqual(restored.pid, 42)
        XCTAssertEqual(restored.windowID, 7)
    }

    private let displays = [
        DisplayRecord(id: 1, name: "Laptop", frame: CGRect(x: 0, y: 0, width: 1440, height: 900)),
        DisplayRecord(id: 2, name: "Empty monitor", frame: CGRect(x: 1440, y: 0, width: 1440, height: 900))
    ]

    func testDropResolvesExactWindowOnAnEmptyDestination() throws {
        let window = try window()
        let drag = WindowDrag(pid: window.pid, windowID: window.id)
        let decoded = try JSONDecoder().decode(WindowDrag.self, from: JSONEncoder().encode(drag))
        XCTAssertEqual(decoded.window(in: [window], to: 2, displays: displays)?.id, window.id)
    }

    func testDropRejectsSameScreenRemovedMonitorAndStaleWindow() throws {
        let window = try window()
        let drag = WindowDrag(pid: window.pid, windowID: window.id)
        XCTAssertNil(drag.window(in: [window], to: 1, displays: displays))
        XCTAssertNil(drag.window(in: [window], to: 3, displays: displays))
        XCTAssertNil(drag.window(in: [], to: 2, displays: displays))
        XCTAssertNil(WindowDrag(pid: 999, windowID: window.id)
            .window(in: [window], to: 2, displays: displays))
        XCTAssertNil(WindowDrag(pid: window.pid, windowID: 999)
            .window(in: [window], to: 2, displays: displays))
    }

    private func window() throws -> WindowRecord {
        try XCTUnwrap(WindowRecord(info: [
            kCGWindowNumber as String: UInt32(7),
            kCGWindowOwnerPID as String: Int32(42),
            kCGWindowLayer as String: 0,
            kCGWindowOwnerName as String: "Test app",
            kCGWindowBounds as String: CGRect(x: 10, y: 20, width: 800, height: 600).dictionaryRepresentation
        ], displays: displays, ownPID: 99))
    }
}
