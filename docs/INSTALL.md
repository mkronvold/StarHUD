# Install StarHUD

## Install AutoHotkey

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Make sure `.ahk` files open with AutoHotkey v2.

## Download StarHUD

### Option A: Use the installer (recommended)

1. Download `StarHUD-Setup.exe` from the [latest release](https://github.com/mkronvold/StarHUD/releases).
2. Run the installer — it will place StarHUD in your Documents\AutoHotkey\StarHUD folder and create a desktop shortcut with the correct icon.
3. No admin privileges are required.

The installer auto-detects your Documents folder (including OneDrive-redirected Documents).

### Option B: Download the ZIP from GitHub

1. Go to <https://github.com/mkronvold/StarHUD>.
2. Click the green **Code** button and choose **Download ZIP**.
3. Open the downloaded ZIP and extract the inner `StarHUD-main` folder.
4. Move or rename it to your chosen location, e.g.:
   ```
   %USERPROFILE%\Documents\AutoHotkey\StarHUD\
   ```

### Option C: Clone with Git / GitHub CLI

If you don't have Git and the GitHub CLI installed, you can install them with winget:

```powershell
winget install Git.Git
winget install GitHub.cli
```

Then restart your terminal and authenticate:

```powershell
gh auth login
```

Clone the repository to your chosen folder:

```powershell
gh repo clone mkronvold/StarHUD "%USERPROFILE%\Documents\AutoHotkey\StarHUD"
```

To update later, pull the latest changes:

```powershell
cd "%USERPROFILE%\Documents\AutoHotkey\StarHUD"
git pull
```

## Files and folder layout

Keep these files together in the same folder:

- `StarHUD.ahk`
- `StarHUD-config.ahk`
- `images\`
- `images\StarHUD-center-logo-200x200.png`
- `images\StarHUD-center-logo-100x100.png`
- `StarHUD-center-logo.ico`

`StarHUD.ahk` reads the active `StarHUD-config*.ahk` file from its own folder. If `StarHUD-user-config.ahk` is present, it uses that user-local selector file to remember the selected profile. If the file is missing, StarHUD starts with `StarHUD-config.ahk` and creates `StarHUD-user-config.ahk` automatically. Center-logo paths are resolved from that folder, and per-button images are resolved from the `images\` subfolder.

## First launch

The only setting you need to configure before running StarHUD is the toggle key. Everything else can be changed from the in-app config dialog.

1. Open any `StarHUD-config*.ahk` file in a text editor.
2. Find the `ToggleHotkey` line near the top and set it to your preferred key:

   ```ahk
   ToggleHotkey := "F20"
   ```

3. Double-click `StarHUD.ahk` to start the HUD.
4. Press the toggle key to show/hide the HUD. Press **RAlt + toggle key** to enter edit mode.

### Choosing a toggle key

Use any bare [AutoHotkey key name](https://www.autohotkey.com/docs/v2/KeyList.htm). Good choices are keys you don't normally use:

| Key | Description |
| --- | --- |
| `F13`–`F24` | Extended function keys (many mice/keyboards can send these) |
| `ScrollLock` | Rarely used on modern systems |
| `Pause` | Pause/Break key |
| `PrintScreen` | If you don't use it for screenshots |
| `CapsLock` | If you've remapped it elsewhere |

The value must be a single key name — not a combination. If you want a mouse button to open the HUD, map that button to the chosen key in your mouse software (e.g. Logitech G HUB, Razer Synapse).

You can also change the toggle key later from the in-app config dialog without editing the file.

## Create a desktop shortcut

If `.ahk` files are already associated with AutoHotkey v2:

1. Right-click `StarHUD.ahk`.
2. Choose **Show more options** if needed, then **Create shortcut**.
3. Move the shortcut wherever you want, such as the desktop.

If you want to point the shortcut directly at AutoHotkey:

1. Right-click the desktop and choose **New > Shortcut**.
2. Use a target like:

   ```
   "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "%USERPROFILE%\Documents\AutoHotkey\StarHUD\StarHUD.ahk"
   ```

3. Name the shortcut `StarHUD`.

## Set the shortcut icon

1. Right-click the shortcut and choose **Properties**.
2. On the **Shortcut** tab, choose **Change Icon**.
3. Browse to `StarHUD-center-logo.ico` in your StarHUD folder.
4. Apply the change.

## Updating

If you installed with **git clone**, just run `git pull` in the StarHUD folder.

If you installed from a ZIP, download the latest ZIP and extract it over your existing folder. Your `StarHUD-user-config.ahk` and custom config files will not be overwritten since they are not in the repository.

If you move StarHUD to a different folder, move the `.ahk`, config, `images\`, `.png`, and `.ico` files together so the script and shortcut icon keep working.
