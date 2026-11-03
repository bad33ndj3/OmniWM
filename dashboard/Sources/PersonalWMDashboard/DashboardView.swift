// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 OmniNull — https://github.com/OmniNull/OmniWM

import AppKit
import SwiftUI

public struct DashboardView: View {
    let inventory: Inventory
    @State private var search = ""
    @State private var selectedDisplay: CGDirectDisplayID?
    @State private var selectedWindow: CGWindowID?
    @State private var dropTarget: CGDirectDisplayID?
    @State private var isMoving = false
    @State private var feedback: String?
    private let moveWindow: (@MainActor (pid_t, CGWindowID, CGDirectDisplayID) async -> String)?
    private let focusWindow: (@MainActor (pid_t, CGWindowID) -> String?)?
    let hide: () -> Void

    private let canvas = Color(nsColor: .underPageBackgroundColor)
    private let surface = Color(nsColor: .controlBackgroundColor)
    private let selectionColor = Color.accentColor

    private var visibleWindows: [WindowRecord] {
        inventory.windows.filter {
            (selectedDisplay == nil || $0.displayID == selectedDisplay) &&
                (search.isEmpty || "\($0.app) \($0.title)".localizedStandardContains(search))
        }
    }

    public init(
        inventory: Inventory,
        moveWindow: (@MainActor (pid_t, CGWindowID, CGDirectDisplayID) async -> String)? = nil,
        focusWindow: (@MainActor (pid_t, CGWindowID) -> String?)? = nil,
        hide: @escaping () -> Void
    ) {
        self.inventory = inventory
        self.moveWindow = moveWindow
        self.focusWindow = focusWindow
        self.hide = hide
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header.padding(24)
            HStack(alignment: .center, spacing: 24) {
                screenMap.frame(width: 144, height: 72)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Schermen: \(inventory.displays.count) · Zichtbare vensters: \(inventory.windows.count)")
                        .font(.callout).foregroundStyle(.secondary)
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Zoek een app of venster", text: $search)
                            .textFieldStyle(.plain)
                            .accessibilityLabel("Zoek een app of venster")
                        if !search.isEmpty {
                            Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }
                                .buttonStyle(.plain).accessibilityLabel("Wis zoekopdracht")
                        }
                    }
                    .padding(10).background(surface, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.primary.opacity(0.16)))
                }
                if selectedDisplay != nil {
                    Button("Alle schermen") { selectedDisplay = nil }
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 20)

            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let error = inventory.error {
                        ContentUnavailableView(
                            "Lezen mislukt",
                            systemImage: "exclamationmark.triangle",
                            description: Text(error)
                        )
                    } else if inventory.displays.isEmpty || (!search.isEmpty && visibleWindows.isEmpty) {
                        ContentUnavailableView(
                            "Geen zichtbare vensters",
                            systemImage: "macwindow",
                            description: Text("Pas je zoekopdracht aan of vernieuw het overzicht.")
                        )
                    } else {
                        ForEach(inventory.displays
                            .filter { selectedDisplay == nil || $0.id == selectedDisplay })
                        { display in
                            windowGroup(
                                name: display.name,
                                display: display,
                                windows: visibleWindows.filter { $0.displayID == display.id }
                            )
                        }
                        let unassigned = visibleWindows.filter { $0.displayID == nil }
                        if !unassigned.isEmpty {
                            windowGroup(name: "Buiten de schermen", display: nil, windows: unassigned)
                        }
                    }
                }
                .padding(24).frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            HStack(spacing: 12) {
                Label(
                    moveWindow == nil ? "Alleen kijken" : "Na verplaatsen blijft focus op het bronscherm",
                    systemImage: moveWindow == nil ? "eye" : "cursorarrow"
                )
                Spacer()
                Text("⌘R Vernieuwen · Esc Sluiten")
            }
            .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 24).padding(.vertical, 14)
        }
        .frame(minWidth: 780, minHeight: 580)
        .background(canvas).tint(selectionColor)
        .onAppear { inventory.refresh() }
        .onChange(of: inventory.displays.map(\.id)) { selectedDisplay = nil }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Je werkruimte").font(.system(size: 28, weight: .semibold)).tracking(-0.7)
                Text(moveWindow == nil ? "Je apps, per scherm." : "Sleep om te verplaatsen. Dubbelklik om te focussen.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { inventory.refresh() } label: { Image(systemName: "arrow.clockwise") }
                .help("Vernieuwen (⌘R)").accessibilityLabel("Vernieuwen").keyboardShortcut("r")
            Button("Verberg", action: hide).keyboardShortcut(.cancelAction).disabled(isMoving)
        }
    }

    private var screenMap: some View {
        GeometryReader { geometry in
            let frames = DisplayRecord.diagramFrames(inventory.displays, size: geometry.size)
            ZStack(alignment: .topLeading) {
                ForEach(Array(inventory.displays.enumerated()), id: \.element.id) { index, display in
                    if let rect = frames[display.id] {
                        Button {
                            selectedDisplay = selectedDisplay == display.id ? nil : display.id
                        } label: {
                            Text("\(index + 1)").font(.system(.caption, design: .monospaced).weight(.semibold))
                                .frame(width: max(0, rect.width - 4), height: max(0, rect.height - 4))
                                .background(
                                    (selectedDisplay == display.id || dropTarget == display.id) ? selectionColor
                                        .opacity(0.15) : surface,
                                    in: RoundedRectangle(cornerRadius: 4)
                                )
                                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(
                                    (selectedDisplay == display.id || dropTarget == display.id) ? selectionColor :
                                        .primary.opacity(0.25),
                                    lineWidth: (selectedDisplay == display.id || dropTarget == display.id) ? 2 : 1
                                ))
                        }
                        .buttonStyle(.plain).position(x: rect.midX, y: rect.midY)
                        .dropDestination(for: WindowDrag.self) { items, _ in
                            acceptDrop(items, to: display.id)
                        } isTargeted: { targeted in
                            updateDropTarget(display.id, targeted: targeted)
                        }
                        .accessibilityLabel("Filter op \(display.name)")
                        .accessibilityAddTraits(selectedDisplay == display.id ? .isSelected : [])
                    }
                }
            }
        }
        .accessibilityElement(children: .contain).accessibilityLabel("Fysieke schermopstelling")
    }

    private func windowGroup(name: String, display: DisplayRecord?, windows: [WindowRecord]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: display
                    .map { $0.frame.height > $0.frame.width } == true ? "display.portrait" : "display")
                    .foregroundStyle(.secondary)
                Text(name).font(.headline)
                Text("\(windows.count)").font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                Spacer()
                if let display, let index = inventory.displays.firstIndex(where: { $0.id == display.id }) {
                    Text("Scherm \(index + 1)").font(.caption).foregroundStyle(.secondary)
                }
            }
            if windows.isEmpty {
                Text(search.isEmpty ? "Geen zichtbare vensters op dit scherm." : "Geen overeenkomende vensters.")
                    .font(.callout).foregroundStyle(.secondary).padding(.vertical, 12)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 205), spacing: 10)], alignment: .leading, spacing: 10) {
                    ForEach(windows) { window in
                        draggableWindowTile(window)
                    }
                }
            }
            if let window = windows.first(where: { $0.id == selectedWindow }) {
                selectionDetails(window)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            dropTarget == display?.id && display != nil ? selectionColor.opacity(0.07) : .clear,
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(
            dropTarget == display?.id && display != nil ? selectionColor : .clear, lineWidth: 2
        ))
        .contentShape(Rectangle())
        .dropDestination(for: WindowDrag.self) { items, _ in
            guard let display else { return false }
            return acceptDrop(items, to: display.id)
        } isTargeted: { targeted in
            if let display { updateDropTarget(display.id, targeted: targeted) }
        }
    }

    @ViewBuilder
    private func draggableWindowTile(_ window: WindowRecord) -> some View {
        if moveWindow != nil && !isMoving {
            windowTile(window)
                .draggable(WindowDrag(pid: window.pid, windowID: window.id))
                .help("Sleep naar een ander scherm. Klik voor opties. Dubbelklik om dit venster te focussen.")
        } else {
            windowTile(window)
        }
    }

    private func updateDropTarget(_ display: CGDirectDisplayID, targeted: Bool) {
        if targeted, moveWindow != nil, !isMoving {
            dropTarget = display
        } else if dropTarget == display {
            dropTarget = nil
        }
    }

    private func acceptDrop(_ items: [WindowDrag], to destination: CGDirectDisplayID) -> Bool {
        dropTarget = nil
        guard moveWindow != nil, !isMoving, items.count == 1,
              let window = items.first?.window(
                  in: inventory.windows,
                  to: destination,
                  displays: inventory.displays
              ) else { return false }
        selectedWindow = window.id
        move(window, to: destination)
        return true
    }

    private func windowTile(_ window: WindowRecord) -> some View {
        Button {
            selectedWindow = window.id
            feedback = nil
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if let icon = NSRunningApplication(processIdentifier: window.pid)?.icon {
                        Image(nsImage: icon).resizable().frame(width: 40, height: 40)
                    } else {
                        Image(systemName: "macwindow").font(.title2).frame(width: 40, height: 40)
                    }
                    Spacer()
                    if selectedWindow == window.id {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(selectionColor)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(window.app).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                    Text(window.title.isEmpty ? "Venster \(window.id)" : window.title)
                        .font(.callout).foregroundStyle(.secondary).lineLimit(2)
                        .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)
                }
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(
                selectedWindow == window.id ? selectionColor.opacity(0.09) : surface,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(
                selectedWindow == window.id ? selectionColor : .primary.opacity(0.10),
                lineWidth: selectedWindow == window.id ? 2 : 1
            ))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain).disabled(isMoving)
        .simultaneousGesture(TapGesture(count: 2).onEnded { focus(window) })
        .accessibilityActions {
            if focusWindow != nil {
                Button("Focus venster") { focus(window) }
            }
        }
        .help(focusWindow == nil ? "Klik om te selecteren." :
            "Klik om te selecteren. Dubbelklik om dit venster te focussen.")
        .accessibilityLabel("\(window.app), \(window.title.isEmpty ? "venster \(window.id)" : window.title)")
        .accessibilityAddTraits(selectedWindow == window.id ? .isSelected : [])
    }

    private func focus(_ window: WindowRecord) {
        guard let focusWindow, !isMoving else { return }
        selectedWindow = window.id
        feedback = focusWindow(window.pid, window.id)
    }

    private func selectionDetails(_ window: WindowRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if moveWindow != nil {
                ViewThatFits(in: .horizontal) {
                    HStack {
                        Text(isMoving ? "Positie controleren…" : "Verplaats \(window.app)").fontWeight(.medium)
                        Spacer()
                        destinationMenu(window)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isMoving ? "Positie controleren…" : "Verplaats \(window.app)").fontWeight(.medium)
                        destinationMenu(window)
                    }
                }
                if let feedback { Text(feedback).font(.callout).textSelection(.enabled) }
            }
            DisclosureGroup("Vensterdetails") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(
                        "Positie: \(Int(window.frame.minX)), \(Int(window.frame.minY)) · Formaat: \(Int(window.frame.width)) × \(Int(window.frame.height))"
                    )
                    .monospacedDigit()
                    if !inventory.titlesAvailable {
                        Text("macOS schermt venstertitels af zonder schermopnametoestemming.")
                    }
                    if let updated = inventory
                        .updatedAt { Text("Bijgewerkt: \(updated.formatted(date: .omitted, time: .standard))") }
                }
                .font(.caption).foregroundStyle(.secondary).padding(.top, 6)
            }
        }
        .padding(14).background(surface, in: RoundedRectangle(cornerRadius: 10))
    }

    private func destinationMenu(_ window: WindowRecord) -> some View {
        Menu("Naar scherm…", systemImage: "arrow.up.forward.square") {
            ForEach(inventory.displays) { display in
                Button(display.name) { move(window, to: display.id) }
                    .disabled(display.id == window.displayID)
            }
        }
        .disabled(isMoving || !inventory.displays.contains { $0.id != window.displayID })
        .fixedSize().accessibilityLabel("Verplaats \(window.app) naar een ander scherm")
    }

    private func move(_ window: WindowRecord, to destination: CGDirectDisplayID) {
        guard let moveWindow, !isMoving,
              inventory.windows
                  .contains(where: { $0.id == window.id && $0.pid == window.pid && $0.displayID != destination }),
              inventory.displays.contains(where: { $0.id == destination }) else { return }
        isMoving = true
        feedback = nil
        Task { @MainActor in
            feedback = await moveWindow(window.pid, window.id, destination)
            await inventory.refreshAfterMove(windowID: window.id, displayID: destination)
            selectedDisplay = nil
            isMoving = false
        }
    }
}
