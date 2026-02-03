//
//  QuestDoroApp.swift
//  QuestDoro
//
//  Created by Kevin Tayong on 2025-12-19.
//

import SwiftUI

@main
struct QuestDoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
