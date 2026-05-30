# Configure StarHUD

StarHUD supports both direct file editing in `StarHUD-config*.ahk` files and in-app editing through the HUD.

## Access the config dialogs

### Open the layout editor

1. Press `F20` to show the HUD.
2. Press `RAlt+F20` to toggle layout edit mode.
3. You can also `RAlt` + click the center button to toggle layout edit mode with the mouse.

### Open the config dialog

While layout edit mode is active, click the center button to open or close the **StarHUD Config** dialog.

![StarHUD config dialog](starhud-config-dialog-v2.png)

### Open the button editor

While layout edit mode is active, hold `RAlt` and click any non-center button. This opens the **Edit StarHUD Button** dialog for that specific button.

![StarHUD button editor](starhud-button-editor-v2.png)

### Leaving edit mode

Edit mode is turned off automatically whenever the HUD is hidden or closed.

## What the config dialog controls

### Config profiles

- **Config file**: chooses which `StarHUD-config*.ahk` profile StarHUD should use. Switching profiles reloads StarHUD into the selected config.
- **New Config**: creates a fresh config profile with the current global settings and a new empty page, then switches to it.
- **Clone Config**: copies the current config profile to a new `StarHUD-config-<name>.ahk` file, then switches to it.
- **Delete Config**: deletes the active config profile after writing a `.bak` backup, then switches to another remaining profile.

### HUD-wide settings

- **Size**: selects one of the built-in size profiles, which control button size, gap, margins, border widths, and insets.
- **Corner radius**: changes how rounded the button corners and panel visuals appear.
- **Mask color**: sets the transparent mask color used for the HUD window.
- **Frame color**: sets the default outer frame color for buttons.
- **Fill color**: sets the default inner fill color used behind button labels and images.
- **Open position**: chooses where the HUD opens: at the mouse, auto-split to the nearest side, always-left, or always-right.
- **Steal mouse input**: when enabled, the HUD captures mouse interaction so the underlying app does not receive clicks or movement while the panel is open.

### Page management

- **Add Page**: creates another empty page with the center page-cycle button already in place.
- **Delete Page**: removes the current page after confirmation and writes a `.bak` backup first.
- **Reset Page**: clears the current page back to empty buttons after confirmation and writes a `.bak` backup first.
- **Open File Location**: opens the folder that contains the StarHUD files and config.

## What the button editor controls

- **Button name**: multiline title field for the label shown on the button. The line breaks you type here control how many title lines the button uses.
- **Border color / text color / line color**: per-button colors, with direct hex entry and picker buttons.
- **Border style**: choose whether the button uses a single or double border.
- **Action type**: choose between `SendKey`, `ChordKey`, `HoldKey`, `DoubleTapKey`, or no action.
- **Action key fields**: define the keys or modifier+key combination used by the selected action.
- **Duration / delay**: shown only for action types that need them.
- **Delete / Copy / Paste**: clear a button, copy a button config, or paste a copied config onto another button.

## Persistence

Changes made through the config dialog and button editor are written back to the active `StarHUD-config*.ahk` file, so the next launch uses the updated layout and settings.

## Visual overview

For a quick view of the HUD itself, see the main overlay screenshot in the [README](../README.md).

![StarHUD HUD overlay](starhud-hud-v2.png)
