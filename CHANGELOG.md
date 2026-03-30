# Changelog

All notable changes to this project are documented in this file.

## [1.1.0] - 2026-03-31

### Added

- **Menu bar app**: Keyboard Blocker runs from the menu bar (no dock icon). Click the icon to open the control popover.
- **Animated menu bar icon**: Minimal pulse / ring animation while the keyboard is locked.
- **Launch at login** (macOS 13+): Optional “Start at login” toggle using `SMAppService`; on older macOS versions, use System Settings → General → Login Items.
- **Context menu**: Right-click the menu bar icon for Open and Quit.
- **Login Items entitlement** for sandboxed launch-at-login registration.

### Changed

- **Popover behavior**: Uses `applicationDefined` so the popover stays open after locking (overlay no longer dismisses it).
- **Safety while locked**: Quit, Start at login, and menu Quit are disabled while the keyboard is locked; ⌘Q is blocked until unlock.
- **Mouse handling**: Clicks are allowed in app windows (e.g. popover) while blocking; overlay windows still absorb background clicks.

### Notes

- Unlock: **hold the ESC key for 3 seconds** (not a single tap).
- Release builds with launch-at-login require proper code signing and the Login Items capability for App Store / notarized distribution.

## [1.0.0] - Earlier

- Initial public release: floating window UI, multi-display overlay, keyboard blocking with accessibility/input monitoring permissions.
