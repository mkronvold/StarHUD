; === STARHUD CONFIG ===
; Edit this file to change settings, sizes, pages, labels, colors, and bindings.
; The main logic stays in StarHUD.ahk.

; === TOGGLE KEY ===
; This is the key that shows/hides the HUD. Press RAlt+ToggleHotkey to toggle edit mode.
; Use any bare AHK key name: F13–F24, ScrollLock, CapsLock, PrintScreen, Pause, etc.
; See https://www.autohotkey.com/docs/v2/KeyList.htm for a full list of valid key names.
; Examples: "F20", "F13", "ScrollLock", "Pause"
ToggleHotkey := "F20"

; === SETTINGS ===
; Set Size to one of the built-in profiles below:
;   1 = 1080 height
;   2 = 1200 height
;   3 = 1440 height (current defaults)
;   4 = 1600 height
;   5 = 2160 height / 2k-style profile
; Comment out Size to auto-detect the closest profile from the primary screen height.
; Custom profile keys can use letters, for example:
;   Size := "a"
;   Size := "b"
Size := 3

SizeProfiles := BuildSizeProfiles()
; Custom profile examples. Copy one of these lines, remove the leading ';', then edit the values:
; MakeSizeProfile(targetHeight, btnSize, btnGap, gridMargin, borderThickness, innerBorderThickness, frameInset, primaryBorderInset, innerBorderInset)
; targetHeight = reference screen height for auto-detect, btnSize = button width/height, btnGap = space between buttons,
; gridMargin = outer padding around the grid, borderThickness / innerBorderThickness = border widths,
; frameInset / primaryBorderInset / innerBorderInset = how far each border layer sits in from the button edge.
; SizeProfiles["a"] := MakeSizeProfile(1366, 102, 16, 19, 3, 2, 4, 8, 15)
; SizeProfiles["b"] := ScaledSizeProfile(1800)

if !IsSet(Size) || Size = ""
    Size := DetectClosestSizeKey(SizeProfiles, GetPrimaryScreenHeight())

Size := NormalizeSizeKey(Size)
if !SizeProfiles.Has(Size)
    throw Error("Unknown Size profile: " Size ". Add it to SizeProfiles near the top of StarHUD-config.ahk.")

ApplySizeProfile(SizeProfiles[Size])
CornerRadius := 14
MaskColor := "010101"
FrameColor := "4A4A4A"
FillColor := "000000"
; OpenPositionMode: "auto-split", "mouse", "always-left", or "always-right"
OpenPositionMode := "always-right"
StealMouseInput := true
ShowButtonKeys := true
ButtonGapOverride := ""
ShowOuterBorder := true
CenterLogoFile := "images\StarHUD-center-logo-200x200.png"
CenterLogoPath := CenterLogoFile = "" ? "" : A_ScriptDir "\" CenterLogoFile
CenterButtonCfg := ButtonCfg("", PageCycleAction(), "FFFFFF", "FFFFFF", "none", CenterLogoPath, "", FillColor)

; === BUTTON CONFIG ===
; Edit labels and actions here.
; Labels should only contain the button name. Shortcut and macro text is added automatically from the action config.
; Use SendKey("r"), DoubleTapKey("u"), HoldKey("b", 1000), or ChordKey("RAlt", "l").
; Set border style to "single", "double", or "none" to match the screenshot styling.
; Set OpenPositionMode to "auto-split", "mouse", "always-left", or "always-right".
; Set StealMouseInput to true to activate the HUD while it is shown so clicks/mouse movement do not reach the app underneath.
; Set StealMouseInput to false to keep the previous non-activating overlay behavior.

; Set ShowButtonKeys to true to show the action keys under button titles, or false to hide them.
; Set ToggleHotkey to a bare AHK key name like "F20", "F13", or "ScrollLock". RAlt+that key toggles edit mode.
; Leave ButtonGapOverride blank to use the selected size profile gap, or set it to a whole number to override the gap globally.
; Set ShowOuterBorder to true to keep the thin outer frame ring around buttons, or false to hide it.
; Put per-button images in the images folder or its subfolders. The editor saves button-image references relative to images automatically.
; Set CenterLogoFile above to change the center icon.
; Set the center button on each page to CenterButtonCfg to keep page cycling enabled.

; Press ToggleHotkey to show or hide the HUD. Press RAlt+ToggleHotkey to toggle edit mode.
; In edit mode, plain-click the center button to open the config dialog.
; In edit mode, RAlt+click the center button to go to the next page.
; In edit mode, plain-click a non-center button to edit its title, colors, border style, and action.
; In edit mode, hold RAlt and click one non-center button, then another, to swap/move them.
; Use the button editor Browse button to pick button images from the images folder, and Open Images in the config dialog to open that folder.
; The button editor also supports Delete, Copy, and Paste so you can clear or duplicate buttons quickly.
; Hiding the HUD always turns edit mode off.
; The block between MANAGED BUTTON LAYOUT markers is rewritten by StarHUD edit mode.
; You can still edit it manually, but button swaps and dialog edits will overwrite that managed block.
; titleLineMode is stored as "single" or "double" in each ButtonCfg(...) entry.
; === MANAGED BUTTON LAYOUT BEGIN ===
Page1Layout := [
    [ButtonCfg(), ButtonCfg("POWER`n-ON-", SendKey("u"), "FF0000", "00FF00", true, "", "4A4A4A", "000000", "double"), ButtonCfg("POWER`n-OFF-", DoubleTapKey("u", 15), "FF0000", "FFFF00", true, "", "4A4A4A", "000000", "double"), ButtonCfg(), ButtonCfg()],
    [ButtonCfg(), ButtonCfg("ENGINE`n-ON-", SendKey("i"), "FF8000", "00FF00", true, "", "4A4A4A", "000000", "double"), ButtonCfg("ENGINE`n-OFF-", DoubleTapKey("i", 15), "FF8000", "FF8000", true, "", "4A4A4A", "000000", "double"), ButtonCfg(), ButtonCfg()],
    [ButtonCfg(), ButtonCfg("FLIGHT`nREADY", SendKey("r"), "00FF88", "00FF88", true, "", "4A4A4A", "000000", "double"), ButtonCfg("", PageCycleAction(), "FFFFFF", "FFFFFF", "none", "StarHUD-center-logo-200x200.png", "4A4A4A", "000000", "single"), ButtonCfg(), ButtonCfg()],
    [ButtonCfg(), ButtonCfg("SHIELD`n-ON-", SendKey("o"), "8080FF", "00FF00", false, "", "4A4A4A", "000000", "double"), ButtonCfg("SHIELD`n-OFF-", DoubleTapKey("o", 60), "8080FF", "8080FF", true, "", "4A4A4A", "000000", "double"), ButtonCfg(), ButtonCfg()],
    [ButtonCfg(), ButtonCfg("WEAPON`n-ON-", SendKey("p"), "FF00FF", "00FF00", false, "", "4A4A4A", "000000", "double"), ButtonCfg("WEAPON`n-OFF-", DoubleTapKey("p", 60), "FF00FF", "FF00FF", true, "", "4A4A4A", "000000", "double"), ButtonCfg(), ButtonCfg()]
]

ButtonPages := [Page1Layout]
; === MANAGED BUTTON LAYOUT END ===
