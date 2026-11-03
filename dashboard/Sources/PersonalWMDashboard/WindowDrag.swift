// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import AppKit
import CoreTransferable
import UniformTypeIdentifiers

struct WindowDrag: Codable, Transferable {
    let pid: pid_t
    let windowID: CGWindowID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
            .visibility(.ownProcess)
    }

    func window(
        in windows: [WindowRecord],
        to destination: CGDirectDisplayID,
        displays: [DisplayRecord]
    ) -> WindowRecord? {
        guard displays.contains(where: { $0.id == destination }) else { return nil }
        return windows.first { $0.id == windowID && $0.pid == pid && $0.displayID != destination }
    }
}
