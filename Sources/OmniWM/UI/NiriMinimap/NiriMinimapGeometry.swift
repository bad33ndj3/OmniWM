// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import CoreGraphics
import Foundation

enum NiriMinimapVisibility: String, Codable, CaseIterable {
    case off
    case whileNavigating
    case always
}

struct NiriMinimapTile: Equatable {
    let token: WindowToken
    let frame: CGRect
    let label: String
}

struct NiriMinimapSnapshot: Equatable {
    let workspaceId: WorkspaceDescriptor.ID
    let tiles: [NiriMinimapTile]
    let viewport: CGRect
    let selectedToken: WindowToken?
}

enum NiriMinimapGeometry {
    static let size = CGSize(width: 140, height: 54)

    static func panelFrame(in visibleFrame: CGRect) -> CGRect {
        CGRect(
            x: visibleFrame.maxX - size.width - 16,
            y: visibleFrame.maxY - size.height - 16,
            width: size.width,
            height: size.height
        )
    }

    static func normalized(_ frame: CGRect, in content: CGRect) -> CGRect? {
        guard content.width > 0, content.height > 0,
              !content.isInfinite, !content.isNull,
              frame.width > 0, frame.height > 0,
              !frame.isInfinite, !frame.isNull
        else { return nil }
        let clipped = frame.intersection(content)
        guard !clipped.isNull, !clipped.isEmpty else { return nil }
        return CGRect(
            x: (clipped.minX - content.minX) / content.width,
            y: (clipped.minY - content.minY) / content.height,
            width: clipped.width / content.width,
            height: clipped.height / content.height
        )
    }

    static func scaled(_ normalized: CGRect, in bounds: CGRect) -> CGRect {
        CGRect(
            x: bounds.minX + normalized.minX * bounds.width,
            y: bounds.minY + normalized.minY * bounds.height,
            width: normalized.width * bounds.width,
            height: normalized.height * bounds.height
        )
    }
}
