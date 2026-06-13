; === STARHUD CONFIG ===
; Edit this file to change settings, sizes, pages, labels, colors, and bindings.
; The main logic stays in StarHUD.ahk.

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
CornerRadius := 0
MaskColor := "010101"
FrameColor := "4A4A4A"
FillColor := "000000"
; OpenPositionMode: "auto-split", "mouse", "always-left", or "always-right"
OpenPositionMode := "always-right"
StealMouseInput := true
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
    [ButtonCfg(), ButtonCfg(), ButtonCfg(), ButtonCfg(), ButtonCfg()],
    [ButtonCfg(), ButtonCfg("UNLOCK PORTS", ChordKey("RAlt", "k", 30), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg(), ButtonCfg("UNLOCK DOORS", ChordKey("RAlt", "u", 30), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg()],
    [ButtonCfg(), ButtonCfg("LOCK PORTS", ChordKey("RAlt", "o", 30), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "double"), CenterButtonCfg, ButtonCfg("LOCK DOORS", ChordKey("RAlt", "l", 30), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg()],
    [ButtonCfg(), ButtonCfg("VJOY MODE", SendKey(Chr(92)), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg("STAGGER MODE", SendKey("."), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg("GIMBLE MODE", SendKey("g"), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg()],
    [ButtonCfg(), ButtonCfg(), ButtonCfg(), ButtonCfg(), ButtonCfg()]
]

ButtonPages := [Page1Layout]
; === MANAGED BUTTON LAYOUT END ===
