# StarHUD

StarHUD is an AutoHotkey v2 overlay for Star Citizen that opens a configurable 5x5 HUD of mouse-friendly buttons for common ship actions, shortcuts, and macros.

## Documentation

- [Install guide](docs/INSTALL.md)
- [Configuration guide](docs/CONFIG.md)
- [Examples gallery](docs/EXAMPLES.md)

## Screenshots

### HUD overlay

![StarHUD HUD overlay](docs/StarHUD-config-default.png)

More layout examples are in the [examples gallery](docs/EXAMPLES.md).

### Config dialog

The layout editor includes an in-app config dialog for display, color, placement, key-label, and page-management settings.

![StarHUD config dialog](docs/starhud-config-dialog-v2.png)

### Button editor

Buttons can be edited in place for title, colors, line mode, and action behavior.

![StarHUD button editor](docs/starhud-button-editor-v2.png)

## Features

- Config-driven multi-page button layout
- Multiple config profiles with in-app switching
- Automatic shortcut labels generated from the configured action
- Optional hide/show control for shortcut labels on buttons
- Automatic migration of older config files when new settings are introduced
- Per-button image browsing from the `images/` folder with preview and fit modes
- Screen-size profiles with optional auto-detection
- Popup positioning modes: `mouse`, `auto-split`, `always-left`, and `always-right`
- Optional mouse input capture while the HUD is open
- In-app layout edit mode with swap, button edit, copy, paste, and delete
- In-app config dialog for size, colors, popup mode, and page management

## Requirements

- Windows
- [AutoHotkey v2](https://www.autohotkey.com/)

## Files

- `StarHUD.ahk` - main runtime script
- `StarHUD-active-config.ahk` - selects which config profile StarHUD loads
- `StarHUD-config.ahk` and `StarHUD-config-*.ahk` - user-editable settings, pages, and button definitions
- `images\` - folder for per-button images used by the button editor
- `images\StarHUD-center-logo-200x200.png` - default center button image
- `images\StarHUD-center-logo-100x100.png` - alternate logo image included with the project
- `StarHUD-center-logo.ico` - icon file for Windows shortcuts

## Getting started

1. Install AutoHotkey v2.
2. Download or clone this repository.
3. Edit the active `StarHUD-config*.ahk` file to match your preferred size profile, colors, popup mode, and button bindings, or use the in-app dialogs described in [docs/CONFIG.md](docs/CONFIG.md).
4. Run `StarHUD.ahk`.

## Default controls

- Configured toggle key (`F20` by default) - show or hide the HUD
- `RAlt` + configured toggle key - enter or exit layout edit mode
- `RAlt` + click center button when not editing - enter layout edit mode
- Click the center button in edit mode - open or close the config dialog
- `RAlt` + click center button in edit mode - go to the next page
- Click a non-center button in edit mode - edit that button
- `RAlt` + click a non-center button in edit mode - select and swap/move buttons
- Hiding the HUD always exits layout edit mode

## Customizing

Most customization happens in the active `StarHUD-config*.ahk` file.

- Change `Size` to use a built-in profile or add your own custom lettered profile.
- Change `OpenPositionMode` to control where the HUD appears.
- Change `StealMouseInput` if you want the HUD to intercept mouse input while visible.
- Change `ShowButtonKeys` if you want to show or hide the action keys on buttons.
- Change `ToggleHotkey` if you want a different key than `F20` to open the HUD.
- Edit the managed page layout block to define buttons, colors, and actions.

The script also supports editing the layout live from the HUD. Swaps, button edits, page changes, and config-profile changes are written back to the active `StarHUD-config*.ahk` file.
