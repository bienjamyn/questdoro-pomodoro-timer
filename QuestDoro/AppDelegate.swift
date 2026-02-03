//
//  AppDelegate.swift
//  QuestDoro
//
//  Created by Kevin Tayong on 2025-12-21.
//

import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlay: MenuBarOverlayController?
    private var engine: PomodoroEngine?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        engine = PomodoroEngine()
        overlay = MenuBarOverlayController(engine: engine!)
        overlay?.showCentered()
    }
}
