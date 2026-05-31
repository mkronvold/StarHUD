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
OpenPositionMode := "mouse"
StealMouseInput := true
ShowButtonKeys := true
ToggleHotkey := "F20"
CenterLogoFile := "star-citizen-logo-bright.png"
CenterLogoPath := CenterLogoFile = "" ? "" : A_ScriptDir "\" CenterLogoFile
CenterButtonCfg := ButtonCfg("", PageCycleAction(), "FFFFFF", "FFFFFF", false, CenterLogoPath, "", FillColor)

; === BUTTON CONFIG ===
; Edit labels and actions here.
; Labels should only contain the button name. Shortcut and macro text is added automatically from the action config.
; Use SendKey("r"), DoubleTapKey("u"), HoldKey("b", 1000), or ChordKey("RAlt", "l").
; Set doubleBorder to true/false to match the screenshot styling.
; Set OpenPositionMode to "auto-split", "mouse", "always-left", or "always-right".
; Set StealMouseInput to true to activate the HUD while it is shown so clicks/mouse movement do not reach the app underneath.
; Set StealMouseInput to false to keep the previous non-activating overlay behavior.
; Set ShowButtonKeys to true to show the action keys under button titles, or false to hide them.
; Set ToggleHotkey to a bare AHK key name like "F20", "F13", or "ScrollLock". RAlt+that key toggles edit mode.
; Set CenterLogoFile above to change the center icon.
; Set the center button on each page to CenterButtonCfg to keep page cycling enabled.
; Press ToggleHotkey to show or hide the HUD. Press RAlt+ToggleHotkey to toggle edit mode.
; In edit mode, plain-click the center button to open the config dialog.
; In edit mode, RAlt+click the center button to go to the next page.
; In edit mode, plain-click a non-center button to edit its title, colors, border style, and action.
; In edit mode, hold RAlt and click one non-center button, then another, to swap/move them.
; The button editor also supports Delete, Copy, and Paste so you can clear or duplicate buttons quickly.
; Hiding the HUD always turns edit mode off.
; The block between MANAGED BUTTON LAYOUT markers is rewritten by StarHUD edit mode.
; You can still edit it manually, but button swaps and dialog edits will overwrite that managed block.
; titleLineMode is stored as "single" or "double" in each ButtonCfg(...) entry.
; === MANAGED BUTTON LAYOUT BEGIN ===
Page1Layout := [
    [ButtonCfg(), ButtonCfg("FLIGHT READY", SendKey("r"), "00FF66", "00FF66", true, "", "4A4A4A", "000000", "double"), ButtonCfg("PWR -OFF-", DoubleTapKey("u", 60), "FF2A2A", "FFF200", true, "", "4A4A4A", "000000", "double"), ButtonCfg("ENG -OFF-", DoubleTapKey("i", 60), "FF9900", "FFF200", true, "", "4A4A4A", "000000", "double"), ButtonCfg()],
    [ButtonCfg("DOORS -OPEN-", SendKey("ScrollLock"), "00D97E", "00BFFF", true, "", "4A4A4A", "000000", "double"), ButtonCfg("VTOL", SendKey("k"), "19D75D", "00FF88", true, "", "4A4A4A", "000000", "single"), ButtonCfg("GEAR", SendKey("n"), "19D75D", "00FF88", true, "", "4A4A4A", "000000", "single"), ButtonCfg("CPLD", SendKey("c"), "19D75D", "00FF88", true, "", "4A4A4A", "000000", "single"), ButtonCfg("ATC", ChordKey("LAlt", "n", 30), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "single")],
    [ButtonCfg("DOORS -CLOSE-", DoubleTapKey("ScrollLock", 60), "00D97E", "00BFFF", true, "", "4A4A4A", "000000", "double"), ButtonCfg("SCAN", SendKey("v"), "1C2BFF", "00FF88", false, "", "4A4A4A", "000000", "single"), CenterButtonCfg, ButtonCfg("NAV", SendKey("b"), "1C2BFF", "00FF88", false, "", "4A4A4A", "000000", "single"), ButtonCfg("DEPLOY", ChordKey("LAlt", "k", 30), "FFF000", "FF88FF", true, "", "4A4A4A", "000000", "single")],
    [ButtonCfg(), ButtonCfg("LIGHTS", SendKey("l"), "1C2BFF", "00FF88", true, "", "4A4A4A", "000000", "single"), ButtonCfg("TOOL MODE", SendKey("m"), "19D75D", "7E8200", true, "", "4A4A4A", "000000", "double"), ButtonCfg("QT", HoldKey("b", 1000), "1C2BFF", "00FF88", false, "", "4A4A4A", "000000", "single"), ButtonCfg("DOCK", ChordKey("RAlt", "n", 30), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "single")],
    [ButtonCfg(), ButtonCfg("NIGHT VISION", ChordKey("RAlt", "l", 30), "1C2BFF", "00FF88", true, "", "4A4A4A", "000000", "double"), ButtonCfg("ACCEPT", SendKey("["), "FFF000", "00FF88", true, "", "4A4A4A", "000000", "single"), ButtonCfg("REJECT", SendKey("]"), "FF2A2A", "00FF88", true, "", "4A4A4A", "000000", "single"), ButtonCfg()]
]

Page2Layout := [
    [ButtonCfg(), ButtonCfg("EJECT", ChordKey("RAlt", "y", 30), "FF2A2A", "FFFFFF", true, "", "4A4A4A", "000000", "single"), ButtonCfg("CPLD", SendKey("c"), "19D75D", "00FF88", true, "", "4A4A4A", "000000", "single"), ButtonCfg(), ButtonCfg()],
    [ButtonCfg(), ButtonCfg("MISSILES +", ChordKey("LAlt", "g", 30), "FF9900", "1C2BFF", true, "", "4A4A4A", "000000", "double"), ButtonCfg("RESET MISSILES", ChordKey("RAlt", "g", 30), "FF9900", "FFF200", true, "", "4A4A4A", "000000", "double"), ButtonCfg("MISSILE CAM", SendKey("Home"), "19D75D", "FFF200", true, "", "4A4A4A", "000000", "double"), ButtonCfg("BURST +", ChordKey("LAlt", "h", 30), "19D75D", "00FF88", false, "", "4A4A4A", "000000", "double")],
    [ButtonCfg("CLEAR TARGET", ChordKey("LAlt", "t", 30), "FF9900", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg("TARGET", SendKey("t"), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "single"), CenterButtonCfg, ButtonCfg("NOISE", SendKey("j"), "FFF000", "FF6600", false, "", "4A4A4A", "000000", "single"), ButtonCfg("DECOY", SendKey("h"), "FFF000", "FF6600", false, "", "4A4A4A", "000000", "single")],
    [ButtonCfg("UNPIN ALL", SendKey("0"), "FFF000", "00FF88", true, "", "4A4A4A", "000000", "double"), ButtonCfg("1 LOCK", SendKey("1"), "FFF000", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg("2 LOCK", SendKey("2"), "FFF000", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg("3 LOCK", SendKey("3"), "FFF000", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg("BURST -", ChordKey("RAlt", "h", 30), "19D75D", "00FF88", false, "", "4A4A4A", "000000", "double")],
    [ButtonCfg(), ButtonCfg("1 PIN", ChordKey("LAlt", "1", 30), "FFF000", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg("2 PIN", ChordKey("LAlt", "2", 30), "FFF000", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg("3 PIN", ChordKey("LAlt", "3", 30), "FFF000", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg()]
]

Page3Layout := [
    [ButtonCfg(), ButtonCfg(), ButtonCfg(), ButtonCfg(), ButtonCfg()],
    [ButtonCfg(), ButtonCfg("UNLOCK PORTS", ChordKey("RAlt", "k", 30), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg(), ButtonCfg("UNLOCK DOORS", ChordKey("RAlt", "u", 30), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg()],
    [ButtonCfg(), ButtonCfg("LOCK PORTS", ChordKey("RAlt", "o", 30), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "double"), CenterButtonCfg, ButtonCfg("LOCK DOORS", ChordKey("RAlt", "l", 30), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg()],
    [ButtonCfg(), ButtonCfg("VJOY MODE", SendKey(Chr(92)), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg("STAGGER MODE", SendKey("."), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg("GIMBLE MODE", SendKey("g"), "00FF88", "00FF88", false, "", "4A4A4A", "000000", "double"), ButtonCfg()],
    [ButtonCfg(), ButtonCfg(), ButtonCfg(), ButtonCfg(), ButtonCfg()]
]

ButtonPages := [Page1Layout, Page2Layout, Page3Layout]
; === MANAGED BUTTON LAYOUT END ===
