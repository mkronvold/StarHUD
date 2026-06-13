# Install StarHUD

## Files and folder layout

Put all of the project files in one folder on your Windows machine. AutoHotkey defaults to:

`%USERPROFILE%\Documents\AutoHotkey\`

so a good default location is:

`C:\Users\<YourName>\Documents\AutoHotkey\StarHUD\`

You can also use any other folder, for example `C:\Tools\StarHUD\`.

Keep these files together in that same folder:

- `StarHUD.ahk`
- `StarHUD-config.ahk`
- `images\`
- `images\StarHUD-center-logo-200x200.png`
- `images\StarHUD-center-logo-100x100.png`
- `StarHUD-center-logo.ico`

`StarHUD.ahk` reads the active `StarHUD-config*.ahk` file from its own folder. If `StarHUD-user-config.ahk` is present, it uses that user-local selector file to remember the selected profile. If the file is missing, StarHUD starts with `StarHUD-config.ahk` and creates `StarHUD-user-config.ahk` automatically. Center-logo paths are resolved from that folder, and per-button images are resolved from the `images\` subfolder.

## Install AutoHotkey

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Make sure `.ahk` files open with AutoHotkey v2.

## First launch

1. Open `StarHUD-config.ahk`.
2. Set your preferred `Size`, `OpenPositionMode`, `ToggleHotkey`, colors, and button bindings.
3. Double-click `StarHUD.ahk` to start the HUD.

You can add more config profiles later from the in-app config dialog without moving files into a separate folder. The config dialog can also open the `images\` folder for you, and StarHUD creates it automatically if it does not exist yet.

## Optional: map the toggle key to a mouse button

StarHUD uses the configured `ToggleHotkey` to show and hide the HUD. The default is `F20`. If your keyboard does not have that key, you can either change `ToggleHotkey` in the config or map one of your mouse buttons to the same keystroke in your mouse software.

For example, in **Logitech G HUB**, you can assign a mouse button to your chosen toggle keystroke so the HUD opens directly from the mouse.

## Create a desktop shortcut

If `.ahk` files are already associated with AutoHotkey v2:

1. Right-click `StarHUD.ahk`.
2. Choose **Show more options** if needed, then **Create shortcut**.
3. Move the shortcut wherever you want, such as the desktop.

If you want to point the shortcut directly at AutoHotkey:

1. Right-click the desktop and choose **New > Shortcut**.
2. Use a target like:

   `"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\Tools\StarHUD\StarHUD.ahk"`

3. Name the shortcut `StarHUD`.

## Set the shortcut icon

1. Right-click the shortcut and choose **Properties**.
2. On the **Shortcut** tab, choose **Change Icon**.
3. Browse to `StarHUD-center-logo.ico` in your StarHUD folder.
4. Apply the change.

## Updating assets

If you move StarHUD to a different folder later, move the `.ahk`, config, `images\`, `.png`, and `.ico` files together so the script and shortcut icon keep working.
