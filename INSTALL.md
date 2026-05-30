# Install StarHUD

## Files and folder layout

Put all of the project files in one folder on your Windows machine, for example:

`C:\Tools\StarHUD\`

Keep these files together in that same folder:

- `StarHUD.ahk`
- `StarHUD-config.ahk`
- `star-citizen-logo-bright.png`
- `StarHUD-center-logo.png`
- `StarHUD-center-logo.ico`

`StarHUD.ahk` reads `StarHUD-config.ahk` from its own folder, and the center-logo image paths are also resolved relative to that same folder.

## Install AutoHotkey

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Make sure `.ahk` files open with AutoHotkey v2.

## First launch

1. Open `StarHUD-config.ahk`.
2. Set your preferred `Size`, `OpenPositionMode`, colors, and button bindings.
3. Double-click `StarHUD.ahk` to start the HUD.

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

If you move StarHUD to a different folder later, move the `.ahk`, config, `.png`, and `.ico` files together so the script and shortcut icon keep working.
