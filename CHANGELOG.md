# Changelog

All notable changes to QuestDoro will be documented in this file.

## [1.1.2] - 2026-03-01

### Added
- Unit tests for PomodoroEngine and time parsing (32 tests)
- CLAUDE.md for AI-assisted development guidance

### Removed
- Dead code: PomodoroModel.swift (unused alternative implementation)
- Dead code: AboutPopoverView.swift and AboutPanelController (unused about panel)

### Changed
- Made parseFlexibleTime function testable (internal visibility)

## [1.1.1] - 2026-02-03

### Added
- Session dot states: gray (not started), dim gold (in progress), bright gold (completed)
- Flash text animations on focus/break transitions
- Notch-safe menu bar positioning
- Tada celebration sound on session complete
- Sparkle celebration effect on phase transitions
- Controls GIF in README

### Fixed
- 4th focus session now properly resets after completing all cycles
- Double-click reset: two consecutive clicks reset the entire session back to 25:00 focus mode
- Double sound on final break: only tada plays, not both

### Changed
- Renamed from PixelDoro to QuestDoro
- Play button greys out when editing custom timer input
- ESC key and double-click on pill background cancel custom timer input
- Full session reset returns to default 25min focus / 5min break

## [1.1.0] - 2026-01-30

### Added
- `.gitignore` for build artifacts and system files
- App icons in asset catalog
- MIT license
- README with download and install instructions

### Fixed
- Janky hover animation replaced with spring animation and fixed window size
- Timer text centering adjusted for better alignment

### Changed
- Prepared for open source release
- Cleaned up tracked files (removed built app, xcuserdata, duplicate font folder)

## [1.0.0] - 2025-12-19

### Added
- Initial release
- Pixel-art Pomodoro timer for macOS menu bar
- Focus and break timer modes
- Hover to expand, click to control
- Custom timer input via double-click
