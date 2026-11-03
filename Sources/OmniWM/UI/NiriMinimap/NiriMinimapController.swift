// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import AppKit
import QuartzCore

@MainActor
final class NiriMinimapController {
    private struct Surface {
        let panel: NSPanel
        let view: NiriMinimapView
        var snapshot: NiriMinimapSnapshot?
        var mode: NiriMinimapVisibility = .off
        var hideTask: Task<Void, Never>?
    }

    private var lastAnimationUpdate: TimeInterval = 0
    private weak var controller: WMController?
    private var surfaces: [Monitor.ID: Surface] = [:]

    init(controller: WMController) {
        self.controller = controller
    }

    func updateForAnimation() {
        guard controller?.settings.niri.minimapVisibility != .off else { return }
        let time = CACurrentMediaTime()
        guard time - lastAnimationUpdate >= 1.0 / 30 else { return }
        lastAnimationUpdate = time
        update()
    }

    func update() {
        guard let controller, controller.hasStartedServices, controller.isEnabled,
              !controller.isLockScreenActive, !controller.isOverviewOpen(),
              !controller.mouseEventHandler.isInputSuppressed,
              controller.settings.niri.minimapVisibility != .off
        else {
            removeAll()
            return
        }
        let manager = controller.workspaceManager
        var activeIds: Set<Monitor.ID> = []
        for monitor in manager.monitors {
            guard let workspace = manager.activeWorkspaceOrFirst(on: monitor.id),
                  manager.activeLayoutKind(for: workspace.id) == .niri,
                  manager.spaceTopology.isDisplayShowingFullscreenSpace(on: monitor) == false,
                  !manager.hasPendingNativeFullscreenTransition,
                  let snapshot = snapshot(for: workspace.id, monitor: monitor, controller: controller),
                  !snapshot.tiles.isEmpty
            else { continue }
            activeIds.insert(monitor.id)
            var surface = surfaces[monitor.id] ?? makeSurface(for: monitor.id)
            let mode = controller.settings.niri.minimapVisibility
            let changed = surface.snapshot != snapshot || surface.mode != mode
            surface.snapshot = snapshot
            surface.mode = mode
            let frame = NiriMinimapGeometry.panelFrame(in: monitor.visibleFrame)
            if surface.panel.frame != frame { surface.panel.setFrame(frame, display: false) }
            surface.view.apply(snapshot)
            if changed || mode == .always {
                if !surface.panel.isVisible { surface.panel.orderFrontRegardless() }
            }
            surfaces[monitor.id] = surface
            if changed { scheduleHide(for: monitor.id) }
        }
        for id in Set(surfaces.keys).subtracting(activeIds) { remove(id) }
    }

    func removeAll() {
        for id in Array(surfaces.keys) { remove(id) }
    }

    private func remove(_ id: Monitor.ID) {
        guard let surface = surfaces.removeValue(forKey: id) else { return }
        surface.hideTask?.cancel()
        OwnedWindowRegistry.shared.unregister(surface.panel)
        surface.panel.orderOut(nil)
        surface.panel.close()
    }

    private func makeSurface(for id: Monitor.ID) -> Surface {
        let panel = NiriMinimapPanel(
            contentRect: CGRect(origin: .zero, size: NiriMinimapGeometry.size),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false
        )
        panel.isFloatingPanel = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        let view = NiriMinimapView(frame: CGRect(origin: .zero, size: NiriMinimapGeometry.size))
        view.setAccessibilityLabel(String(localized: "Workspace minimap"))
        view.onSelect = { [weak self] token in self?.select(token, on: id) }
        panel.contentView = view
        OwnedWindowRegistry.shared.register(panel, surfaceId: "niri-minimap-\(id)", policy: SurfacePolicy(
            kind: .utility, hitTestPolicy: .interactive, capturePolicy: .excluded,
            suppressesManagedFocusRecovery: false
        ))
        return Surface(panel: panel, view: view)
    }

    private func scheduleHide(for id: Monitor.ID) {
        surfaces[id]?.hideTask?.cancel()
        guard surfaces[id]?.mode == .whileNavigating else { return }
        surfaces[id]?.hideTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .seconds(2.2)) } catch { return }
            guard let self, let surface = surfaces[id] else { return }
            if surface.panel.frame.contains(NSEvent.mouseLocation) {
                scheduleHide(for: id)
            } else {
                surface.panel.orderOut(nil)
            }
        }
    }

    private func select(_ token: WindowToken, on id: Monitor.ID) {
        guard let controller, controller.isEnabled, !controller.isLockScreenActive,
              !controller.isOverviewOpen(), !controller.mouseEventHandler.isInputSuppressed,
              let snapshot = surfaces[id]?.snapshot,
              snapshot.tiles.contains(where: { $0.token == token }),
              controller.workspaceManager.activeWorkspace(on: id)?.id == snapshot.workspaceId,
              let entry = controller.workspaceManager.entry(for: token),
              entry.workspaceId == snapshot.workspaceId,
              controller.isManagedWindowDisplayable(entry),
              !controller.workspaceManager.hasPendingNativeFullscreenTransition,
              let node = controller.niriEngine?.findNode(for: token, in: snapshot.workspaceId)
        else { return }
        controller.mouseEventHandler.state.latestFocusFollowsMouseSample = nil
        controller.workspaceManager.withNiriViewportState(for: snapshot.workspaceId) { state in
            controller.niriLayoutHandler.activateNode(node, in: snapshot.workspaceId, state: &state)
        }
        scheduleHide(for: id)
    }

    private func snapshot(
        for workspaceId: WorkspaceDescriptor.ID, monitor: Monitor, controller: WMController
    ) -> NiriMinimapSnapshot? {
        guard let engine = controller.niriEngine else { return nil }
        let working = controller.niriWorkingFrame(for: monitor)
        let gap = controller.innerGap(for: monitor)
        let orientation = controller.settings.monitors.effectiveOrientation(for: monitor)
        let horizontal = orientation == .horizontal
        let projection = engine.projectedGeometrySnapshot(
            in: workspaceId, workingFrame: working, gaps: gap, orientation: orientation
        )
        let state = controller.workspaceManager.niriViewportState(for: workspaceId)
        guard let anchor = engine.projectedViewportAnchor(state: state, geometry: projection, in: workspaceId)
        else { return nil }
        let offset = controller.workspaceManager.animationDriver.liveViewOffset(
            in: workspaceId, semanticOffset: state.viewOffset
        ) ?? state.viewOffset
        let viewStart = anchor.primaryPosition + offset
        let primary = horizontal ? working.width : working.height
        let secondary = horizontal ? working.height : working.width
        var tiles: [NiriMinimapTile] = []
        var contentEnd: CGFloat = 0
        for geometry in projection.columns {
            let column = geometry.projectedColumn
            let span = engine.projectedPrimarySpan(
                for: column, workingFrame: working, gap: gap, orientation: orientation
            )
            contentEnd = max(contentEnd, geometry.primaryPosition + span)
            for (index, window) in column.windows.enumerated() {
                guard controller.isManagedWindowDisplayable(window.token) else { continue }
                // Show tab members separately so every window remains a clickable destination.
                let tabbed = column.column.isTabbed && column.windows.count > 1
                let offset = tabbed ? CGFloat(index) * secondary / CGFloat(column.windows.count)
                    : geometry.secondaryOffsets[index]
                let crossSpan = tabbed ? secondary / CGFloat(column.windows.count)
                    : (horizontal ? window.resolvedHeight : window.resolvedWidth) ?? secondary
                let frame = horizontal
                    ? CGRect(x: geometry.primaryPosition, y: offset, width: span, height: crossSpan)
                    : CGRect(x: offset, y: geometry.primaryPosition, width: crossSpan, height: span)
                tiles.append(NiriMinimapTile(
                    token: window.token, frame: frame,
                    label: controller.appInfoCache.name(for: window.token.pid) ?? String(localized: "Window")
                ))
            }
        }
        let start = min(0, viewStart)
        let end = max(contentEnd, viewStart + primary)
        let content = horizontal
            ? CGRect(x: start, y: 0, width: end - start, height: secondary)
            : CGRect(x: 0, y: start, width: secondary, height: end - start)
        let viewport = horizontal
            ? CGRect(x: viewStart, y: 0, width: primary, height: secondary)
            : CGRect(x: 0, y: viewStart, width: secondary, height: primary)
        guard let normalizedViewport = NiriMinimapGeometry.normalized(viewport, in: content) else { return nil }
        return NiriMinimapSnapshot(
            workspaceId: workspaceId,
            tiles: tiles.compactMap { tile in
                NiriMinimapGeometry.normalized(tile.frame, in: content).map {
                    NiriMinimapTile(token: tile.token, frame: $0, label: tile.label)
                }
            },
            viewport: normalizedViewport,
            selectedToken: state.selectedNodeId.flatMap { engine.findNode(by: $0, in: workspaceId) as? NiriWindow }?
                .token
        )
    }
}
