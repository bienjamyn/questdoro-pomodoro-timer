//
//  MenuBarOverlayController.swift
//  PixelDoro
//
//  Created by Kevin Tayong on 2025-12-21.
//

import Cocoa
import SwiftUI

final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class AboutPanelController {
    private var panel: KeyablePanel?

    func toggle(anchorScreenPoint: NSPoint, quitAction: @escaping () -> Void) {
        if let panel, panel.isVisible {
            panel.orderOut(nil)
            return
        }
        show(anchorScreenPoint: anchorScreenPoint, quitAction: quitAction)
    }

    private func show(anchorScreenPoint: NSPoint, quitAction: @escaping () -> Void) {
        let view = NSHostingView(rootView: AboutPopoverView(quitAction: quitAction))

        let p = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 160),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        p.titleVisibility = .hidden
        p.titlebarAppearsTransparent = true
        p.isMovableByWindowBackground = true
        p.isOpaque = false
        p.backgroundColor = .windowBackgroundColor
        p.hasShadow = true
        p.level = .statusBar
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.hidesOnDeactivate = false

        p.contentView = view

        let x = max(10, anchorScreenPoint.x - 120)
        let y = anchorScreenPoint.y - 170
        p.setFrameOrigin(NSPoint(x: x, y: y))

        p.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: p,
            queue: .main
        ) { [weak self] _ in
            self?.panel?.orderOut(nil)
        }

        panel = p
    }
}

final class MenuBarOverlayController {
    private var currentWidth: CGFloat = 200  // Use expanded width to avoid resizing
    private let maxPillHeight: CGFloat = 150 // Height to fit expanded pill (140pt + padding)
    private let window: KeyablePanel

    init(engine: PomodoroEngine) {
        // 1) Create window first so self.window is initialized safely
        let w = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 150),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.level = .statusBar
        w.hidesOnDeactivate = false
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        w.acceptsMouseMovedEvents = true
        w.ignoresMouseEvents = false

        self.window = w

        // 2) Now it is safe to create the SwiftUI view
        // Window stays fixed size; SwiftUI handles all animation internally
        let root = PillView(
            engine: engine,
            quitAction: { NSApp.terminate(nil) }
        )

        let hosting = NSHostingView(rootView: root)
        self.window.contentView = hosting
    }

    func showCentered() {
        recenter()
        window.orderFrontRegardless()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recenter),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func recenter() {
        guard let screen = NSScreen.main else { return }

        // Fixed window size - SwiftUI content animates within this frame
        let height: CGFloat = maxPillHeight
        let width: CGFloat = currentWidth

        // Position so the top of the window touches the top of the screen
        let y = screen.frame.maxY - height
        let x = screen.frame.midX - (width / 2)

        window.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
        window.makeKey()
    }
}
