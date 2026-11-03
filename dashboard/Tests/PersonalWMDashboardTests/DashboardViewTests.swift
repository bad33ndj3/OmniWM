// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import AppKit
@testable import PersonalWMDashboard
import SwiftUI
import XCTest

final class DashboardViewTests: XCTestCase {
    @MainActor
    func testDashboardRendersAtMinimumAndDefaultSizesInBothAppearances() throws {
        _ = NSApplication.shared
        let inventory = Inventory()
        inventory.refresh()
        for dark in [false, true] {
            for size in [CGSize(width: 780, height: 580), CGSize(width: 1000, height: 780)] {
                let view = NSHostingView(rootView: DashboardView(inventory: inventory) {}
                    .environment(\.colorScheme, dark ? .dark : .light))
                view.frame = CGRect(origin: .zero, size: size)
                view.layoutSubtreeIfNeeded()
                XCTAssertLessThanOrEqual(view.fittingSize.width, size.width)
                let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
                view.cacheDisplay(in: view.bounds, to: bitmap)
                XCTAssertEqual(
                    Double(bitmap.pixelsWide) / Double(bitmap.pixelsHigh),
                    size.width / size.height,
                    accuracy: 0.001
                )
                let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                XCTAssertGreaterThan(png.count, 1000)
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("personal-wm-dashboard-\(dark ? "dark" : "light")-\(Int(size.width)).png")
                try png.write(to: url)
                print("Dashboard render: \(url.path)")
            }
        }
    }
}
