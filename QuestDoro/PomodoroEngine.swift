//
//  PomodoroEngine.swift
//  QuestDoro
//
//  Created by Kevin Tayong on 2025-12-21.
//

import Foundation
import Combine
import AppKit

enum Phase {
    case focus
    case breakTime
    case idle
    case finished
}

final class PomodoroEngine: ObservableObject {
    // Config
    @Published var focusSeconds: Int = 25 * 60
    @Published var breakSeconds: Int = 5 * 60
    let totalFocusSessions = 4

    // State
    @Published var phase: Phase = .idle
    @Published var remaining: Int = 25 * 60
    @Published var isRunning: Bool = false
    @Published var completedFocusSessions: Int = 0

    private var timer: AnyCancellable?

    func displayString() -> String {
        let mm = remaining / 60
        let ss = remaining % 60
        return String(format: "%02d:%02d", mm, ss)
    }

    func start() {
        let wasIdle = (phase == .idle)
        if phase == .idle {
            phase = .focus
            remaining = focusSeconds
        }
        // Play light ding when starting a focus session
        if phase == .focus && wasIdle {
            playStartDing()
        }
        isRunning = true
        startTicking()
    }

    func stop() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }

    func restartCurrent() {
        stop() // ensure not running
        switch phase {
        case .focus, .idle:
            remaining = focusSeconds
            phase = (phase == .idle) ? .idle : .focus
        case .breakTime:
            remaining = breakSeconds
        case .finished:
            resetAll()
        }
    }

    func resetAll() {
        stop()
        phase = .idle
        completedFocusSessions = 0
        remaining = focusSeconds
    }

    func setTimeFromInput(_ input: String) {
        guard let seconds = parseFlexibleTime(input) else { return }

        stop() // ensure editing never starts countdown

        switch phase {
        case .breakTime:
            breakSeconds = seconds
            remaining = seconds
        default:
            focusSeconds = seconds
            remaining = seconds
            if phase == .finished { phase = .idle }
        }
    }
    
    func resetToDefaultFocus() {
        stop()
        focusSeconds = 25 * 60
        if phase != .breakTime {
            phase = .idle
            remaining = focusSeconds
        }
    }

    private func startTicking() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard self.isRunning else { return }

                if self.remaining > 0 {
                    self.remaining -= 1
                } else {
                    self.handlePhaseComplete()
                }
            }
    }

    private func handlePhaseComplete() {
        switch phase {
        case .focus:
            playFocusComplete()
            completedFocusSessions += 1
            if completedFocusSessions >= totalFocusSessions {
                phase = .finished
                remaining = focusSeconds  // Reset timer to 25:00
                isRunning = false
                timer?.cancel()
                timer = nil
                return
            }
            // Switch to break but do NOT auto-start
            phase = .breakTime
            remaining = breakSeconds
            isRunning = false
            timer?.cancel()
            timer = nil

        case .breakTime:
            playBreakComplete()
            // Switch to next focus but do NOT auto-start
            phase = .focus
            remaining = focusSeconds
            isRunning = false
            timer?.cancel()
            timer = nil

        case .idle, .finished:
            isRunning = false
        }
    }

    private func playStartDing() {
        // Light ding when starting focus
        NSSound(named: "Tink")?.play()
    }

    private func playFocusComplete() {
        // Gentle sound when focus session ends
        NSSound(named: "Glass")?.play()
    }

    private func playBreakComplete() {
        // More noticeable ring when break is over
        NSSound(named: "Hero")?.play()
    }
}

private func parseFlexibleTime(_ raw: String) -> Int? {
    let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if s.isEmpty { return nil }

    // Allow MM:SS
    if s.contains(":") {
        let parts = s.split(separator: ":")
        guard parts.count == 2,
              let mm = Int(parts[0]),
              let ss = Int(parts[1]),
              (0...99).contains(mm),
              (0...59).contains(ss) else { return nil }
        return mm * 60 + ss
    }

    // Digits-only
    let digits = s.filter { $0.isNumber }
    guard !digits.isEmpty else { return nil }

    // 1–2 digits => minutes
    if digits.count <= 2 {
        let mm = Int(digits) ?? 0
        guard (0...99).contains(mm) else { return nil }
        return mm * 60
    }

    // 3–4 digits => MMSS (right-aligned) with overflow normalization
    let trimmed = String(digits.suffix(4))
    let padded = trimmed.count == 3 ? "0" + trimmed : trimmed  // "599" -> "0599"
    let mmStr = String(padded.prefix(2))
    let ssStr = String(padded.suffix(2))

    let mm = Int(mmStr) ?? 0
    let ss = Int(ssStr) ?? 0

    let total = (mm * 60) + ss
    guard total >= 0 else { return nil }

    // normalize overflow: ss can be 60–99, we still accept
    let normalizedMinutes = total / 60
    let normalizedSeconds = total % 60
    guard (0...99).contains(normalizedMinutes) else { return nil }

    return normalizedMinutes * 60 + normalizedSeconds

}
