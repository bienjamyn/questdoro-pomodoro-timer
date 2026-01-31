//
//  PillView.swift
//  PixelDoro
//
//  Created by Kevin Tayong on 2025-12-21.
//

import SwiftUI
import AppKit

struct PillView: View {
    @ObservedObject var engine: PomodoroEngine
    let quitAction: () -> Void

    @State private var hovering = false
    @State private var isEditing = false
    @State private var input = ""

    @FocusState private var inputFocused: Bool

    // Dimensions
    private let collapsedHeight: CGFloat = 28  // Timer only
    private let expandedHeight: CGFloat = 140  // Timer + buttons + label + dots
    private let collapsedWidth: CGFloat = 130  // Timer only
    private let expandedWidth: CGFloat = 200   // Wider for 3 buttons
    private let cornerRadius: CGFloat = 10

    private var currentWidth: CGFloat {
        hovering ? expandedWidth : collapsedWidth
    }

    private var currentHeight: CGFloat {
        hovering ? expandedHeight : collapsedHeight
    }

    var body: some View {
        // Fixed frame container - aligned to top center so pill hangs from menu bar
        ZStack(alignment: .top) {
            // Single background pill shape (no conditional)
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius,
                topTrailingRadius: 0
            )
            .fill(Color(hex: "0027FF"))
            .frame(width: currentWidth, height: currentHeight)
            .shadow(color: .black.opacity(hovering ? 0 : 0.3), radius: 4, x: 0, y: 2)
            .contentShape(UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius,
                topTrailingRadius: 0
            ))
            .onHover { inside in hovering = inside }

            // Content - always present, controls fade in/out
            VStack(spacing: 8) {
                // Timer - anchored at top
                timeView
                    .padding(.top, hovering ? 10 : 0)
                    .frame(height: hovering ? nil : collapsedHeight, alignment: .center)
                    .offset(y: hovering ? 0 : 3)

                // Controls - use opacity and scale for smooth transition
                VStack(spacing: 8) {
                    // Yellow square buttons row
                    HStack(spacing: 16) {
                        controlButton(imageName: "restart") {
                            if isEditing {
                                engine.resetToDefaultFocus()
                                input = engine.displayString()
                                isEditing = false
                                inputFocused = false
                            } else {
                                engine.restartCurrent()
                            }
                        }

                        controlButton(imageName: engine.isRunning ? "pause" : "play") {
                            if isEditing { return }
                            engine.isRunning ? engine.stop() : engine.start()
                        }

                        controlButton(imageName: "close") {
                            quitAction()
                        }
                    }

                    // FOCUS/BREAK label with shadow
                    ZStack {
                        Text(engine.phase == .breakTime ? "BREAK" : "FOCUS")
                            .font(.custom("Jersey 10", size: 18))
                            .foregroundStyle(.black)
                            .offset(x: 1, y: 1)
                        Text(engine.phase == .breakTime ? "BREAK" : "FOCUS")
                            .font(.custom("Jersey 10", size: 18))
                            .foregroundStyle(.white)
                    }

                    // Session dots
                    HStack(spacing: 6) {
                        ForEach(0..<engine.totalFocusSessions, id: \.self) { index in
                            Circle()
                                .fill(index < engine.completedFocusSessions ? Color(hex: "FFD700") : Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .opacity(hovering ? 1 : 0)
                .scaleEffect(hovering ? 1 : 0.8)
                .frame(height: hovering ? nil : 0)
                .clipped()
            }
            .padding(.horizontal, 10)
            .frame(width: currentWidth, height: currentHeight)
            .onHover { inside in hovering = inside }
        }
        .frame(width: expandedWidth, height: 150, alignment: .top) // Fixed container matching window size
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hovering)
    }

    private var timeView: some View {
        Group {
            if isEditing {
                TextField("", text: $input)
                    .textFieldStyle(.plain)
                    .font(.custom("Jersey 10", size: 30))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .focused($inputFocused)
                    .onSubmit {
                        engine.setTimeFromInput(input)
                        input = engine.displayString()
                        isEditing = false
                        inputFocused = false
                    }
                    .onAppear {
                        inputFocused = true
                    }
            } else {
                // Single timer view - identical for both states (no conditional needed)
                ZStack {
                    Text(engine.displayString())
                        .font(.custom("Jersey 10", size: 30))
                        .foregroundStyle(.black)
                        .offset(x: 2, y: 2)

                    Text(engine.displayString())
                        .font(.custom("Jersey 10", size: 30))
                        .foregroundStyle(.white)
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    NSApp.activate(ignoringOtherApps: true)
                    engine.stop()
                    input = engine.displayString()
                    isEditing = true
                    inputFocused = true
                }
            }
        }
    }

    private func controlButton(imageName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
    }
}

// Hex helper
private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}

