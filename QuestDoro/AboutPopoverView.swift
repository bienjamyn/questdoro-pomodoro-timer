//
//  AboutPopoverView.swift
//  QuestDoro
//
//  Created by Kevin Tayong on 2025-12-21.
//

import SwiftUI

struct AboutPopoverView: View {
    let quitAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QuestDoro")
                .font(.system(size: 16, weight: .bold))

            Text("v0.1")
                .font(.system(size: 12))
                .opacity(0.8)

            Text("A tiny, centered Pomodoro timer for the menu bar.")
                .font(.system(size: 12))
                .opacity(0.9)

            Text("© 2025")
                .font(.system(size: 12))
                .opacity(0.7)

            Divider()

            Button("Quit") {
                quitAction()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(12)
        .frame(width: 240)
    }
}
