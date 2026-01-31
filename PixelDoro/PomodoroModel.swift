//
//  PomodoroModel.swift
//  PixelDoro
//
//  Created by Kevin Tayong on 2025-12-19.
//

import Foundation
import Combine

enum PomodoroMode {
    case focus
    case breakTime
    case inactive
}

final class PomodoroModel: ObservableObject {
    @Published var mode: PomodoroMode = .inactive

    @Published var focusDuration: Int = 25 * 60
    @Published var breakDuration: Int = 5 * 60

    @Published var remainingSeconds: Int = 25 * 60
    @Published var isRunning: Bool = false

    private var timer: AnyCancellable?

    init() {
        remainingSeconds = focusDuration
    }

    func startFocus() {
        mode = .focus
        remainingSeconds = focusDuration
        start()
    }

    func startBreak() {
        mode = .breakTime
        remainingSeconds = breakDuration
        start()
    }

    func stop() {
        isRunning = false
        timer?.cancel()
        timer = nil
        mode = .inactive
    }

    private func start() {
        isRunning = true
        timer?.cancel()

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }

                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    switch self.mode {
                    case .focus:
                        self.startBreak()
                    case .breakTime:
                        self.stop()
                    case .inactive:
                        self.stop()
                    }
                }
            }
    }

    func displayString() -> String {
        let mm = remainingSeconds / 60
        let ss = remainingSeconds % 60
        return String(format: "%02d:%02d", mm, ss)
    }

    func setDurationFromInput(_ input: String) {
        let parts = input.split(separator: ":")
        guard parts.count == 2,
              let mm = Int(parts[0]),
              let ss = Int(parts[1]),
              (0...99).contains(mm),
              (0...59).contains(ss) else { return }

        let total = mm * 60 + ss

        switch mode {
        case .focus:
            focusDuration = total
        case .breakTime:
            breakDuration = total
        case .inactive:
            focusDuration = total
        }

        if !isRunning {
            remainingSeconds = total
        }
    }
}
