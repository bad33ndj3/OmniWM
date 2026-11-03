// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import AppKit

struct DisplayRecord: Identifiable {
    let id: CGDirectDisplayID
    let name: String
    let frame: CGRect

    static func containing(_ frame: CGRect, in displays: [Self]) -> Self? {
        displays.sorted { $0.id < $1.id }.max { lhs, rhs in
            area(lhs.frame.intersection(frame)) < area(rhs.frame.intersection(frame))
        }.flatMap { area($0.frame.intersection(frame)) > 0 ? $0 : nil }
    }

    private static func area(_ rect: CGRect) -> CGFloat {
        rect.isNull ? 0 : rect.width * rect.height
    }

    static func diagramFrames(_ displays: [Self], size: CGSize) -> [CGDirectDisplayID: CGRect] {
        let bounds = displays.reduce(CGRect.null) { $0.union($1.frame) }
        guard !bounds.isNull, bounds.width > 0, bounds.height > 0,
              size.width > 0, size.height > 0 else { return [:] }
        let scale = min(size.width / bounds.width, size.height / bounds.height)
        return Dictionary(uniqueKeysWithValues: displays.map { display in
            (display.id, CGRect(
                x: (display.frame.minX - bounds.minX) * scale + (size.width - bounds.width * scale) / 2,
                y: (display.frame.minY - bounds.minY) * scale + (size.height - bounds.height * scale) / 2,
                width: display.frame.width * scale,
                height: display.frame.height * scale
            ))
        })
    }
}

struct WindowRecord: Identifiable {
    let id: CGWindowID
    let pid: pid_t
    let app: String
    let title: String
    let frame: CGRect
    let displayID: CGDirectDisplayID?

    init?(info: [String: Any], displays: [DisplayRecord], ownPID: pid_t) {
        guard let id = info[kCGWindowNumber as String] as? UInt32,
              let pid = info[kCGWindowOwnerPID as String] as? Int32,
              pid != ownPID,
              info[kCGWindowLayer as String] as? Int == 0,
              let bounds = info[kCGWindowBounds as String] as? [String: Any],
              let x = bounds["X"] as? NSNumber,
              let y = bounds["Y"] as? NSNumber,
              let width = bounds["Width"] as? NSNumber,
              let height = bounds["Height"] as? NSNumber else { return nil }
        let values = [x, y, width, height].map(\.doubleValue)
        guard values.allSatisfy({ $0.isFinite && abs($0) <= 10_000_000 }),
              width.doubleValue > 0, height.doubleValue > 0 else { return nil }
        let frame = CGRect(x: x.doubleValue, y: y.doubleValue, width: width.doubleValue, height: height.doubleValue)
        self.id = id
        self.pid = pid
        app = info[kCGWindowOwnerName as String] as? String ?? "Onbekende app"
        title = info[kCGWindowName as String] as? String ?? ""
        self.frame = frame
        displayID = DisplayRecord.containing(frame, in: displays)?.id
    }
}

@MainActor
@Observable
public final class Inventory {
    private(set) var displays: [DisplayRecord] = []
    private(set) var windows: [WindowRecord] = []
    private(set) var updatedAt: Date?
    private(set) var error: String?
    private(set) var titlesAvailable = false

    public init() {}

    func refreshAfterMove(windowID: CGWindowID, displayID: CGDirectDisplayID) async {
        _ = await Self.waitForDisplay(displayID) {
            self.refresh()
            return self.windows.first(where: { $0.id == windowID })?.displayID
        }
    }

    static func waitForDisplay(
        _ destination: CGDirectDisplayID,
        sample: () -> CGDirectDisplayID?
    ) async -> Bool {
        // WindowServer inventory can lag the app's AX acknowledgement; retry reads, never the move.
        for _ in 0 ..< 10 {
            guard !Task.isCancelled else { return false }
            if sample() == destination { return true }
            do {
                try await Task.sleep(for: .milliseconds(100))
            } catch {
                return false
            }
        }
        return false
    }

    public func refresh() {
        // CGDisplayBounds and CGWindowBounds share a top-left origin, unlike NSScreen.frame.
        displays = NSScreen.screens.compactMap { screen in
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32
            else { return nil }
            return DisplayRecord(id: id, name: screen.localizedName, frame: CGDisplayBounds(id))
        }
        guard let rows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
        ) as? [[String: Any]] else {
            windows = []
            updatedAt = nil
            error = "Vensters konden niet worden gelezen. Probeer opnieuw met Vernieuwen."
            return
        }
        windows = rows.compactMap {
            WindowRecord(info: $0, displays: displays, ownPID: ProcessInfo.processInfo.processIdentifier)
        }.sorted {
            $0.app == $1.app ? $0.id < $1.id : $0.app.localizedStandardCompare($1.app) == .orderedAscending
        }
        titlesAvailable = CGPreflightScreenCaptureAccess()
        updatedAt = Date()
        error = nil
    }
}
