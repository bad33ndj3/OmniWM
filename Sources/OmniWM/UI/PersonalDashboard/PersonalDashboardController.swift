// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import AppKit
import PersonalDashboardKit
import SwiftUI

@MainActor
final class PersonalDashboardController: NSObject, NSWindowDelegate {
    private weak var controller: WMController?
    private var panel: DashboardPanel?
    private let inventory = Inventory()
    private var restoreToken: WindowToken?
    private var restoreWorkspaceName: String?
    private var isMoving = false

    init(controller: WMController) {
        self.controller = controller
    }

    func show() {
        guard let controller, controller.isEnabled, !controller.isLockScreenActive else { return }
        if panel == nil {
            let panel = DashboardPanel(
                contentRect: NSRect(x: 0, y: 0, width: 1000, height: 780),
                styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
                backing: .buffered, defer: false
            )
            panel.title = "Je werkruimte"
            panel.level = .floating
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
            panel.delegate = self
            panel.refresh = inventory.refresh
            panel.hide = { [weak self] in self?.dismiss() }
            panel.contentView = NSHostingView(rootView: DashboardView(
                inventory: inventory,
                moveWindow: { [weak self] pid, windowID, displayID in
                    guard let self else { return "Het dashboard is gesloten." }
                    return await self.move(pid: pid, windowID: windowID, to: displayID)
                },
                focusWindow: { [weak self] pid, windowID in
                    guard let self else { return "Het dashboard is gesloten." }
                    return self.focus(pid: pid, windowID: windowID)
                },
                hide: { [weak self] in self?.dismiss() }
            ))
            panel.center()
            controller.ownedWindowRegistry.register(panel)
            self.panel = panel
        }
        guard panel?.isVisible != true else {
            panel?.makeKeyAndOrderFront(nil)
            return
        }
        restoreToken = controller.workspaceManager.selectedManagedToken
        restoreWorkspaceName = controller.activeWorkspace()?.name
        controller.focusPolicyEngine.beginLease(owner: .personalDashboard, reason: "personal_dashboard", duration: nil)
        inventory.refresh()
        panel?.makeKeyAndOrderFront(nil)
    }

    func toggle() {
        if panel?.isVisible == true { dismiss() } else { show() }
    }

    func dismiss() {
        guard !isMoving, let controller else { return }
        panel?.orderOut(nil)
        // Discard the cached hover sample before releasing the lease; only a new move may restore hover focus.
        controller.mouseEventHandler.state.latestFocusFollowsMouseSample = nil
        controller.focusPolicyEngine.endLease(owner: .personalDashboard)
        controller.releaseStaleOwnedSurfaceFocus()
        if let restoreToken,
           controller.workspaceManager.workspace(for: restoreToken)
               .flatMap({ controller.workspaceManager.descriptor(for: $0)?.name }) == restoreWorkspaceName
        {
            controller.focusWindow(restoreToken, origin: .keyboardOrProgrammatic)
        } else if let restoreWorkspaceName {
            _ = controller.workspaceNavigationHandler.switchWorkspace(rawWorkspaceID: restoreWorkspaceName)
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        dismiss()
        return false
    }

    func focus(pid: pid_t, windowID: CGWindowID) -> String? {
        guard !isMoving, let controller, controller.isEnabled, !controller.isLockScreenActive,
              panel?.isVisible == true else { return "Focussen is nu niet beschikbaar." }
        let manager = controller.workspaceManager
        let token = WindowToken(pid: pid, windowId: Int(windowID))
        guard let entry = manager.entry(for: token),
              controller.isManagedWindowDisplayable(entry),
              let monitor = manager.monitor(for: entry.workspaceId),
              manager.activeWorkspace(on: monitor.id)?.id == entry.workspaceId,
              !manager.hasPendingNativeFullscreenTransition,
              let workspaceName = manager.descriptor(for: entry.workspaceId)?.name
        else { return "Dit venster is niet meer beschikbaar. Vernieuw het overzicht." }
        restoreToken = token
        restoreWorkspaceName = workspaceName
        dismiss()
        return nil
    }

    private func move(pid: pid_t, windowID: CGWindowID, to displayID: CGDirectDisplayID) async -> String {
        guard !isMoving, let controller, controller.isEnabled, !controller.isLockScreenActive,
              panel?.isVisible == true else { return "Verplaatsen is nu niet beschikbaar." }
        let manager = controller.workspaceManager
        let token = WindowToken(pid: pid, windowId: Int(windowID))
        guard let entry = manager.entry(for: token),
              controller.isManagedWindowDisplayable(entry),
              let sourceMonitor = manager.monitor(for: entry.workspaceId),
              manager.activeWorkspace(on: sourceMonitor.id)?.id == entry.workspaceId,
              let targetMonitor = manager.monitors.first(where: { $0.displayId == displayID }),
              targetMonitor.id != sourceMonitor.id,
              let targetWorkspace = manager.activeWorkspace(on: targetMonitor.id),
              manager.spaceTopology.isDisplayShowingFullscreenSpace(on: targetMonitor) == false,
              !manager.hasPendingNativeFullscreenTransition,
              let before = entry.axRef.flatMap({ try? AXWindowService.frame($0) })
        else {
            return "Venster of doelscherm is gewijzigd. Vernieuw het overzicht."
        }
        isMoving = true
        defer { isMoving = false }
        let sourceID = entry.workspaceId
        let sourceEntries = manager.entries(in: sourceID).filter {
            $0.token != token && controller.isManagedWindowDisplayable($0)
        }
        let candidates = sourceEntries.compactMap { candidate -> (WindowToken, CGRect)? in
            guard let frame = candidate.axRef.flatMap({ try? AXWindowService.frame($0) }) else { return nil }
            return (candidate.token, frame)
        }
        guard candidates.count == sourceEntries.count else {
            return "Bronposities konden niet worden gelezen. Er is niets verplaatst."
        }
        let fallback = Self.nearest(to: before, candidates: candidates)
        guard Self.transfer(token, to: targetWorkspace.id, fallback: fallback, controller: controller)
        else { return "OmniWM heeft het venster niet verplaatst." }
        restoreToken = fallback
        restoreWorkspaceName = manager.descriptor(for: sourceID)?.name
        controller.mouseEventHandler.state.latestFocusFollowsMouseSample = nil

        // A committed model change is not proof that macOS accepted the frame; never resend automatically.
        for _ in 0 ..< 40 {
            try? await Task.sleep(for: .milliseconds(50))
            guard manager.entry(for: token)?.workspaceId == targetWorkspace.id,
                  manager.activeWorkspace(on: targetMonitor.id)?.id == targetWorkspace.id,
                  manager.monitors.contains(where: { $0.displayId == displayID && $0.frame == targetMonitor.frame })
            else { return "De situatie wijzigde tijdens de verplaatsing. Vernieuw voordat je verdergaat." }
            if let actual = entry.axRef.flatMap({ try? AXWindowService.frame($0) }),
               targetMonitor.frame.contains(CGPoint(x: actual.midX, y: actual.midY))
            {
                return "Verplaatst naar \(targetMonitor.name). macOS bevestigt \(Int(actual.minX)), \(Int(actual.minY)) · \(Int(actual.width)) × \(Int(actual.height))."
            }
        }
        return "Verplaatsing verstuurd, maar macOS heeft de positie niet bevestigd. Vernieuw; probeer niet blind opnieuw."
    }

    static func transfer(
        _ token: WindowToken,
        to destination: WorkspaceDescriptor.ID,
        fallback: WindowToken?,
        controller: WMController
    ) -> Bool {
        let manager = controller.workspaceManager
        guard let source = manager.workspace(for: token),
              let monitor = manager.monitor(for: source),
              case let .changed(mutation) = controller.workspaceNavigationHandler.moveWindow(
                  handle: WindowHandle(id: token), toWorkspaceId: destination
              ) else { return false }
        controller.recoverSourceFocusAfterMove(in: source, preferredToken: fallback)
        manager.setInteractionMonitor(monitor.id)
        controller.workspaceNavigationHandler.finishWorkspaceMove(mutation, focusPolicy: .retainCurrent)
        return true
    }

    static func nearest(to frame: CGRect, candidates: [(WindowToken, CGRect)]) -> WindowToken? {
        candidates.min { lhs, rhs in
            let left = pow(lhs.1.midX - frame.midX, 2) + pow(lhs.1.midY - frame.midY, 2)
            let right = pow(rhs.1.midX - frame.midX, 2) + pow(rhs.1.midY - frame.midY, 2)
            return left == right ? (lhs.0.pid, lhs.0.windowId) < (rhs.0.pid, rhs.0.windowId) : left < right
        }?.0
    }
}
