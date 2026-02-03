//
//  PillView.swift
//  QuestDoro
//
//  Created by Kevin Tayong on 2025-12-21.
//

import SwiftUI
import AppKit

// Particle model for sparkle celebration
struct PixelParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var angle: Double
    var velocity: CGFloat
    var opacity: Double
    var rotation: Double
}

struct PillView: View {
    @ObservedObject var engine: PomodoroEngine
    @ObservedObject var hoverState: HoverState
    let quitAction: () -> Void

    private var hovering: Bool { hoverState.isHovering }

    @State private var isEditing = false
    @State private var input = ""
    @State private var sparkleParticles: [PixelParticle] = []
    @State private var restartClickPending = false
    @State private var flashText: String? = nil


    @FocusState private var inputFocused: Bool

    // Colors
    private let focusBlue = Color(hex: "0027FF")
    private let goldAccent = Color(hex: "FFD700")

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
            // Background pill shape with break state color
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius,
                topTrailingRadius: 0
            )
            .fill(focusBlue)
            .frame(width: currentWidth, height: currentHeight)
            .shadow(color: .black.opacity(hovering ? 0 : 0.3), radius: 4, x: 0, y: 2)
            .contentShape(UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius,
                topTrailingRadius: 0
            ))
            .onHover { inside in hoverState.isHovering = inside }
            .onTapGesture(count: 2) {
                if isEditing {
                    isEditing = false
                    inputFocused = false
                }
            }

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
                                if restartClickPending {
                                    engine.resetAll()
                                    restartClickPending = false
                                } else {
                                    engine.restartCurrent()
                                    restartClickPending = true
                                }
                            }
                        }

                        controlButton(imageName: engine.isRunning ? "pause" : "play", disabled: isEditing) {
                            restartClickPending = false
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
                                .fill(dotColor(for: index))
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
            .onHover { inside in hoverState.isHovering = inside }

            // Sparkle overlay for focus complete celebration
            sparkleOverlay
        }
        .frame(width: expandedWidth, height: 150, alignment: .top) // Fixed container matching window size
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hovering)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: engine.phase)
        .onChange(of: engine.phase) { oldPhase, newPhase in
            if oldPhase == .focus && newPhase == .breakTime {
                triggerSparkle()
                showFlashText("BREAK")
            } else if oldPhase == .breakTime && newPhase == .focus {
                showFlashText("FOCUS")
            }
        }
    }

    // MARK: - Sparkle Celebration

    private var sparkleOverlay: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(sparkleParticles) { particle in
                    Rectangle()
                        .fill(goldAccent)
                        .frame(width: particle.size, height: particle.size)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                        .offset(x: particle.x, y: particle.y)
                }
            }
            .position(x: geo.size.width / 2, y: collapsedHeight / 2)
        }
        .allowsHitTesting(false)
    }

    private func triggerSparkle() {
        let particleCount = 14

        // Create particles at center
        sparkleParticles = (0..<particleCount).map { _ in
            PixelParticle(
                x: 0,
                y: 0,
                size: CGFloat.random(in: 4...8),
                angle: Double.random(in: 0...(2 * .pi)),
                velocity: CGFloat.random(in: 50...100),
                opacity: 1.0,
                rotation: 0
            )
        }

        // Animate burst outward
        withAnimation(.easeOut(duration: 0.5)) {
            sparkleParticles = sparkleParticles.map { p in
                var updated = p
                updated.x = cos(p.angle) * p.velocity
                updated.y = sin(p.angle) * p.velocity
                updated.opacity = 0
                updated.rotation = Double.random(in: -180...180)
                return updated
            }
        }

        // Cleanup after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            sparkleParticles = []
        }
    }

    private func showFlashText(_ text: String) {
        flashText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                flashText = nil
            }
        }
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
                    .onExitCommand {
                        isEditing = false
                        inputFocused = false
                    }
                    .onAppear {
                        inputFocused = true
                    }
            } else if let text = flashText {
                // Flash text when timer completes
                ZStack {
                    Text(text)
                        .font(.custom("Jersey 10", size: 30))
                        .foregroundStyle(.black)
                        .offset(x: 2, y: 2)
                    Text(text)
                        .font(.custom("Jersey 10", size: 30))
                        .foregroundStyle(.white)
                }
                .transition(.opacity)
            } else {
                // Normal timer display
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
        .animation(.easeInOut(duration: 0.3), value: flashText)
    }

    private func dotColor(for index: Int) -> Color {
        if index < engine.completedFocusSessions {
            return goldAccent
        } else if index == engine.completedFocusSessions && engine.phase == .focus {
            return goldAccent.opacity(0.75)
        } else {
            return Color.gray.opacity(0.5)
        }
    }

    private func controlButton(imageName: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.75 : 1.0)
        .disabled(disabled)
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

