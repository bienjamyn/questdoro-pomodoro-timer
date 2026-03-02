# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

QuestDoro is a macOS menu bar Pomodoro timer app with a pixel-art aesthetic. It's a native Swift/SwiftUI application targeting macOS 14+.

## Build & Run

Open `QuestDoro.xcodeproj` in Xcode and build/run (Cmd+R). There are no external dependencies or package managers.

## Testing

Run tests with Cmd+U in Xcode or via command line:
```bash
xcodebuild test -project QuestDoro.xcodeproj -scheme QuestDoro -destination 'platform=macOS'
```

Tests are in `QuestDoroTests/` and cover `PomodoroEngine` logic and time parsing.

## Architecture

The app runs as a menu bar accessory (no dock icon) using `NSApp.setActivationPolicy(.accessory)`.

### Key Components

- **QuestDoroApp.swift** - Entry point, uses `@NSApplicationDelegateAdaptor` to delegate to AppDelegate
- **AppDelegate.swift** - Creates the `PomodoroEngine` and `MenuBarOverlayController` on launch
- **PomodoroEngine.swift** - Core timer logic: manages phases (focus/break/idle/finished), countdown, session tracking (4 focus sessions per cycle), and audio feedback using system sounds
- **MenuBarOverlayController.swift** - Creates a borderless `KeyablePanel` window positioned below the menu bar. Uses global mouse monitors to toggle `ignoresMouseEvents` for click-through behavior outside the pill
- **PillView.swift** - SwiftUI view for the expandable timer pill. Collapsed state shows timer only; expanded (on hover) shows play/pause/restart/close buttons, phase label, and session progress dots

### Data Flow

`PomodoroEngine` is an `@ObservableObject` shared between `MenuBarOverlayController` and `PillView`. Timer state changes propagate via `@Published` properties.

### Window System

- `KeyablePanel` (NSPanel subclass) allows becoming key window while remaining borderless
- `HoverState` tracks mouse hover to animate pill expansion
- `ClickThroughHostingView` enables first-click acceptance for SwiftUI content

### Custom Font

Uses "Jersey 10" pixel font (Jersey10-Regular.ttf) registered in Info.plist.
