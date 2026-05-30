#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook()
#UseHook
#WinActivateForce
DetectHiddenWindows True
CoordMode "Mouse", "Screen"

; Editable settings and button/page layout live in StarHUD-config.ahk.
#Include StarHUD-config.ahk

ConfigFilePath := A_ScriptDir "\StarHUD-config.ahk"
ManagedLayoutStartMarker := "; === MANAGED BUTTON LAYOUT BEGIN ==="
ManagedLayoutEndMarker := "; === MANAGED BUTTON LAYOUT END ==="
GridRows := ButtonPages[1].Length
GridCols := ButtonPages[1][1].Length
GuiW := GridMargin * 2 + GridCols * BtnSize + (GridCols - 1) * BtnGap
GuiH := GridMargin * 2 + GridRows * BtnSize + (GridRows - 1) * BtnGap
LastActiveHwnd := 0
PanelVisible := false
CurrentPageIndex := 1
CenterClientX := GridMargin + Floor(GridCols / 2) * (BtnSize + BtnGap) + Floor(BtnSize / 2)
CenterClientY := GridMargin + Floor(GridRows / 2) * (BtnSize + BtnGap) + Floor(BtnSize / 2)
PageGuis := []
EditMode := false
EditSwapSelection := 0
EditDialogState := 0
ConfigDialogState := 0
CopiedButtonCfg := 0

; Start GDI+
DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken := 0, "Ptr", Buffer(8, 0), "Ptr", 0)
OnExit (*) => DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)

ButtonCfg(text := "", action := 0, borderColor := "00FF88", textColor := "", doubleBorder := false, imagePath := "", frameColorOverride := "", backgroundColor := "", titleLineMode := "") {
    global FillColor, FrameColor

    normalizedText := NormalizeConfigTitle(text)
    if titleLineMode = ""
        titleLineMode := InferTitleLineMode(text)
    if textColor = ""
        textColor := borderColor
    if frameColorOverride = ""
        frameColorOverride := FrameColor
    if backgroundColor = ""
        backgroundColor := FillColor

    return {
        text: normalizedText,
        action: action,
        borderColor: borderColor,
        textColor: textColor,
        doubleBorder: doubleBorder,
        imagePath: imagePath,
        frameColor: frameColorOverride,
        backgroundColor: backgroundColor,
        titleLineMode: titleLineMode
    }
}

SendKey(keys) {
    keyValue := NormalizeActionKey(keys)
    return MakeAction([SendStep(PrepareSendKeyInput(keyValue))], FormatActionKey(keyValue), false, "SendKey", keyValue)
}

DoubleTapKey(keys, delay := 60) {
    keyValue := NormalizeActionKey(keys)
    return MakeAction([SendStep(PrepareSendKeyInput(keyValue)), SleepStep(delay), SendStep(PrepareSendKeyInput(keyValue))], FormatActionKey(keyValue) " x2", false, "DoubleTapKey", keyValue, "", 0, delay)
}

HoldKey(key, duration := 1000) {
    keyValue := NormalizeActionKey(key)
    return MakeAction([SendStep("{" keyValue " down}"), SleepStep(duration), SendStep("{" keyValue " up}")], "Hold " FormatActionKey(keyValue), false, "HoldKey", keyValue, "", duration)
}

ChordKey(modifier, key, holdDelay := 30) {
    modifierValue := NormalizeActionKey(modifier)
    keyValue := NormalizeActionKey(key)
    return MakeAction([SendStep("{" modifierValue " down}"), SleepStep(holdDelay), SendStep(PrepareSendKeyInput(keyValue)), SleepStep(holdDelay), SendStep("{" modifierValue " up}")], FormatActionKey(modifierValue) "+" FormatActionKey(keyValue), false, "ChordKey", keyValue, modifierValue, 0, holdDelay)
}

SendStep(keys) {
    return {type: "send", value: keys}
}

SleepStep(duration) {
    return {type: "sleep", value: duration}
}

MakeAction(steps, shortcutLabel := "", isPageCycle := false, actionType := "None", keyValue := "", modifierValue := "", duration := 0, delay := 0) {
    return {
        steps: steps,
        shortcutLabel: shortcutLabel,
        isPageCycle: isPageCycle,
        actionType: actionType,
        keyValue: keyValue,
        modifierValue: modifierValue,
        duration: duration,
        delay: delay
    }
}

FormatActionKey(keyValue) {
    keyText := NormalizeActionKey(keyValue)

    if StrLower(keyText) = "scrolllock"
        return "SCRL"

    if StrLen(keyText) = 1
        return StrUpper(keyText)

    return keyText
}

NormalizeActionKey(keyValue) {
    keyText := Format("{}", keyValue)
    if SubStr(keyText, 1, 1) = "{" && SubStr(keyText, -1) = "}"
        keyText := SubStr(keyText, 2, StrLen(keyText) - 2)
    return keyText
}

PrepareSendKeyInput(keyValue) {
    normalizedKey := NormalizeActionKey(keyValue)
    if normalizedKey = ""
        return ""
    if StrLen(normalizedKey) = 1
        return normalizedKey
    return "{" normalizedKey "}"
}

NormalizeConfigTitle(text) {
    normalizedText := RegExReplace(Format("{}", text), "\s*`n\s*", " ")
    normalizedText := RegExReplace(normalizedText, "\s+", " ")
    return Trim(normalizedText)
}

InferTitleLineMode(text) {
    return InStr(Format("{}", text), "`n") ? "double" : "single"
}

BuildSizeProfiles() {
    profiles := Map(
        "1", ScaledSizeProfile(1080),
        "2", ScaledSizeProfile(1200),
        "3", ScaledSizeProfile(1440),
        "4", ScaledSizeProfile(1600),
        "5", ScaledSizeProfile(2160)
    )
    return profiles
}

MakeSizeProfile(targetHeight, btnSize, btnGap, gridMargin, borderThickness, innerBorderThickness, frameInset, primaryBorderInset, innerBorderInset) {
    return {
        targetHeight: targetHeight,
        btnSize: btnSize,
        btnGap: btnGap,
        gridMargin: gridMargin,
        borderThickness: borderThickness,
        innerBorderThickness: innerBorderThickness,
        frameInset: frameInset,
        primaryBorderInset: primaryBorderInset,
        innerBorderInset: innerBorderInset
    }
}

ScaledSizeProfile(targetHeight) {
    scale := targetHeight / 1440
    return MakeSizeProfile(
        targetHeight,
        Max(1, Round(108 * scale)),
        Max(1, Round(17 * scale)),
        Max(1, Round(20 * scale)),
        Max(1, Round(3 * scale)),
        Max(1, Round(2 * scale)),
        Max(1, Round(4 * scale)),
        Max(1, Round(9 * scale)),
        Max(1, Round(16 * scale))
    )
}

ApplySizeProfile(profile) {
    global BorderThickness, BtnGap, BtnSize, FrameInset, GridMargin, InnerBorderInset, InnerBorderThickness, PrimaryBorderInset

    BtnSize := profile.btnSize
    BtnGap := profile.btnGap
    GridMargin := profile.gridMargin
    BorderThickness := profile.borderThickness
    InnerBorderThickness := profile.innerBorderThickness
    FrameInset := profile.frameInset
    PrimaryBorderInset := profile.primaryBorderInset
    InnerBorderInset := profile.innerBorderInset
}

NormalizeSizeKey(sizeKey) {
    return StrLower(Format("{}", sizeKey))
}

DetectClosestSizeKey(sizeProfiles, screenHeight) {
    closestKey := ""
    closestDistance := ""

    for profileKey, profile in sizeProfiles
    {
        distance := Abs(profile.targetHeight - screenHeight)
        if closestDistance = "" || distance < closestDistance
        {
            closestKey := profileKey
            closestDistance := distance
        }
    }

    return closestKey
}

GetPrimaryScreenHeight() {
    try
    {
        MonitorGet(1, &monLeft, &monTop, &monRight, &monBottom)
        return monBottom - monTop
    }
    return A_ScreenHeight
}

PageCycleAction() {
    return MakeAction([], "", true, "PageCycle")
}

IsPageCycleAction(action) {
    return IsObject(action) && action.HasOwnProp("isPageCycle") && action.isPageCycle
}

CloneAction(action) {
    switch GetButtonActionType(action)
    {
        case "None":
            return 0
        case "PageCycle":
            return PageCycleAction()
        case "SendKey":
            return SendKey(action.keyValue)
        case "DoubleTapKey":
            return DoubleTapKey(action.keyValue, action.delay)
        case "HoldKey":
            return HoldKey(action.keyValue, action.duration)
        case "ChordKey":
            return ChordKey(action.modifierValue, action.keyValue, action.delay)
        default:
            throw Error("Unsupported action type for clone: " GetButtonActionType(action))
    }
}

CloneButtonCfg(cfg) {
    return ButtonCfg(
        cfg.text,
        CloneAction(cfg.action),
        cfg.borderColor,
        cfg.textColor,
        cfg.doubleBorder,
        cfg.imagePath,
        cfg.frameColor,
        cfg.backgroundColor,
        cfg.titleLineMode
    )
}

RefreshCenterButtonTemplate() {
    global CenterButtonCfg, CenterLogoPath, FillColor

    CenterButtonCfg := ButtonCfg("", PageCycleAction(), "FFFFFF", "FFFFFF", false, CenterLogoPath, "", FillColor)
}

IsCenterCell(rowIndex, colIndex) {
    global GridCols, GridRows

    return rowIndex = Floor(GridRows / 2) + 1
        && colIndex = Floor(GridCols / 2) + 1
}

CreateEmptyPageLayout() {
    global CenterButtonCfg, GridCols, GridRows

    layout := []
    Loop GridRows
    {
        rowIndex := A_Index
        row := []
        Loop GridCols
        {
            colIndex := A_Index
            if IsCenterCell(rowIndex, colIndex)
                row.Push(CloneButtonCfg(CenterButtonCfg))
            else
                row.Push(ButtonCfg())
        }
        layout.Push(row)
    }
    return layout
}

RefreshLayoutMetrics() {
    global BtnGap, BtnSize, ButtonPages, CenterClientX, CenterClientY, GridCols, GridMargin, GridRows, GuiH, GuiW

    if ButtonPages.Length = 0
        throw Error("StarHUD must have at least one page.")

    GridRows := ButtonPages[1].Length
    GridCols := ButtonPages[1][1].Length
    GuiW := GridMargin * 2 + GridCols * BtnSize + (GridCols - 1) * BtnGap
    GuiH := GridMargin * 2 + GridRows * BtnSize + (GridRows - 1) * BtnGap
    CenterClientX := GridMargin + Floor(GridCols / 2) * (BtnSize + BtnGap) + Floor(BtnSize / 2)
    CenterClientY := GridMargin + Floor(GridRows / 2) * (BtnSize + BtnGap) + Floor(BtnSize / 2)
}

ApplyCurrentSizeProfile() {
    global Size, SizeProfiles

    Size := NormalizeSizeKey(Size)
    if !SizeProfiles.Has(Size)
        throw Error("Unknown Size profile: " Size ". Add it to SizeProfiles near the top of StarHUD-config.ahk.")
    ApplySizeProfile(SizeProfiles[Size])
    RefreshLayoutMetrics()
}

UpdateButtonsForDefaultColorChange(oldFrameColor, oldFillColor) {
    global ButtonPages, FillColor, FrameColor

    if oldFrameColor = FrameColor && oldFillColor = FillColor
        return

    for _, layout in ButtonPages
    {
        for _, row in layout
        {
            for _, cfg in row
            {
                if cfg.frameColor = oldFrameColor
                    cfg.frameColor := FrameColor
                if cfg.backgroundColor = oldFillColor
                    cfg.backgroundColor := FillColor
            }
        }
    }
}

GetActionShortcutLabel(action) {
    if !IsObject(action)
        return ""
    if action.HasOwnProp("shortcutLabel")
        return action.shortcutLabel
    return ""
}

GetActionSteps(action) {
    if !IsObject(action)
        return []
    if action.HasOwnProp("steps")
        return action.steps
    return action
}

GetButtonDisplayText(cfg) {
    titleText := FormatButtonTitle(cfg.text, cfg.titleLineMode)
    shortcutLabel := GetActionShortcutLabel(cfg.action)
    if shortcutLabel = ""
        return titleText
    if titleText = ""
        return shortcutLabel
    return titleText "`n" shortcutLabel
}

HasVisualContent(cfg) {
    return GetButtonDisplayText(cfg) != "" || cfg.imagePath != "" || IsPageCycleAction(cfg.action)
}

FormatButtonTitle(titleText, titleLineMode) {
    normalizedTitle := NormalizeConfigTitle(titleText)
    if normalizedTitle = ""
        return ""
    if titleLineMode = "double"
        return SplitTitleToTwoLines(normalizedTitle)
    return normalizedTitle
}

SplitTitleToTwoLines(titleText) {
    words := StrSplit(titleText, A_Space)
    if words.Length <= 1
        return titleText

    bestSplitIndex := 1
    bestDifference := ""
    Loop words.Length - 1
    {
        splitIndex := A_Index
        leftText := JoinTokens(words, 1, splitIndex)
        rightText := JoinTokens(words, splitIndex + 1, words.Length)
        difference := Abs(StrLen(leftText) - StrLen(rightText))
        if bestDifference = "" || difference < bestDifference
        {
            bestDifference := difference
            bestSplitIndex := splitIndex
        }
    }

    return JoinTokens(words, 1, bestSplitIndex) "`n" JoinTokens(words, bestSplitIndex + 1, words.Length)
}

JoinTokens(tokens, startIndex, endIndex) {
    text := ""
    Loop endIndex - startIndex + 1
    {
        token := tokens[startIndex + A_Index - 1]
        if text != ""
            text .= " "
        text .= token
    }
    return text
}

SerializeManagedLayoutBlock() {
    global ButtonPages

    lines := []
    loop ButtonPages.Length
    {
        pageIndex := A_Index
        layoutVarName := "Page" pageIndex "Layout"
        lines.Push(layoutVarName " := [")
        lines.Push(SerializePageRows(ButtonPages[pageIndex]))
        lines.Push("]")
        lines.Push("")
    }

    pageRefs := []
    Loop ButtonPages.Length
        pageRefs.Push("Page" A_Index "Layout")
    lines.Push("ButtonPages := [" ArrayJoin(pageRefs, ", ") "]")

    return ArrayJoin(lines, "`r`n")
}

SerializePageRows(layout) {
    rowLines := []
    for _, row in layout
        rowLines.Push("    [" SerializePageRow(row) "],")
    if rowLines.Length > 0
        rowLines[rowLines.Length] := RTrim(rowLines[rowLines.Length], ",")
    return ArrayJoin(rowLines, "`r`n")
}

SerializePageRow(row) {
    parts := []
    for _, cfg in row
        parts.Push(SerializeButtonCfg(cfg))
    return ArrayJoin(parts, ", ")
}

SerializeButtonCfg(cfg) {
    global CenterLogoPath, FillColor, FrameColor

    if IsCenterButtonConfig(cfg)
        return "CenterButtonCfg"
    if !HasVisualContent(cfg) && cfg.imagePath = "" && cfg.borderColor = "00FF88" && cfg.textColor = "00FF88" && !cfg.doubleBorder && cfg.frameColor = FrameColor && cfg.backgroundColor = FillColor && cfg.titleLineMode = "single"
        return "ButtonCfg()"

    return "ButtonCfg("
        . SerializeAhkString(cfg.text) ", "
        . SerializeAction(cfg.action) ", "
        . SerializeAhkString(cfg.borderColor) ", "
        . SerializeAhkString(cfg.textColor) ", "
        . BoolToAhk(cfg.doubleBorder) ", "
        . SerializeImagePath(cfg.imagePath) ", "
        . SerializeAhkString(cfg.frameColor) ", "
        . SerializeAhkString(cfg.backgroundColor) ", "
        . SerializeAhkString(cfg.titleLineMode) ")"
}

IsCenterButtonConfig(cfg) {
    global CenterLogoPath, FillColor

    return cfg.text = ""
        && cfg.imagePath = CenterLogoPath
        && IsPageCycleAction(cfg.action)
        && cfg.borderColor = "FFFFFF"
        && cfg.textColor = "FFFFFF"
        && !cfg.doubleBorder
        && cfg.backgroundColor = FillColor
}

SerializeAction(action) {
    actionType := GetButtonActionType(action)
    switch actionType
    {
        case "None":
            return "0"
        case "PageCycle":
            return "PageCycleAction()"
        case "SendKey":
            return "SendKey(" SerializeKeyLiteral(action.keyValue) ")"
        case "DoubleTapKey":
            return "DoubleTapKey(" SerializeKeyLiteral(action.keyValue) ", " action.delay ")"
        case "HoldKey":
            return "HoldKey(" SerializeKeyLiteral(action.keyValue) ", " action.duration ")"
        case "ChordKey":
            return "ChordKey(" SerializeKeyLiteral(action.modifierValue) ", " SerializeKeyLiteral(action.keyValue) ", " action.delay ")"
        default:
            throw Error("Unsupported action type for serialization: " actionType)
    }
}

GetButtonActionType(action) {
    if !IsObject(action)
        return "None"
    if action.HasOwnProp("actionType")
        return action.actionType
    return "None"
}

SerializeImagePath(imagePath) {
    global CenterLogoPath

    if imagePath = ""
        return '""'
    if imagePath = CenterLogoPath
        return "CenterLogoPath"
    return SerializeAhkString(imagePath)
}

SerializeKeyLiteral(keyValue) {
    normalizedKey := NormalizeActionKey(keyValue)
    if normalizedKey = "\"
        return "Chr(92)"
    return SerializeAhkString(normalizedKey)
}

SerializeAhkString(value) {
    return '"' StrReplace(Format("{}", value), '"', '""') '"'
}

BoolToAhk(value) {
    return value ? "true" : "false"
}

ArrayJoin(values, separator := "") {
    text := ""
    for _, value in values
    {
        if text != ""
            text .= separator
        text .= value
    }
    return text
}

ReplaceManagedLayoutBlock(configText) {
    global ConfigFilePath, ManagedLayoutEndMarker, ManagedLayoutStartMarker

    startPos := InStr(configText, ManagedLayoutStartMarker)
    endPos := InStr(configText, ManagedLayoutEndMarker)
    if !startPos || !endPos || endPos <= startPos
        throw Error("Could not find managed layout markers in " ConfigFilePath)

    beforeText := SubStr(configText, 1, startPos + StrLen(ManagedLayoutStartMarker) - 1)
    afterText := SubStr(configText, endPos)
    return beforeText "`r`n" SerializeManagedLayoutBlock() "`r`n" afterText
}

ReplaceConfigAssignment(configText, keyName, valueText) {
    pattern := "m)^" keyName "\s*:=.*$"
    replacedText := RegExReplace(configText, pattern, keyName " := " valueText, &replaceCount, 1)
    if replaceCount = 0
        throw Error("Could not find config assignment for " keyName " in " ConfigFilePath)
    return replacedText
}

BackupConfigFile() {
    global ConfigFilePath

    FileCopy(ConfigFilePath, ConfigFilePath ".bak", true)
}

SerializeSizeConfigValue(sizeValue) {
    sizeText := NormalizeSizeKey(sizeValue)
    if RegExMatch(sizeText, "^\d+$")
        return sizeText
    return SerializeAhkString(sizeText)
}

WriteConfigStateToFile(createBackup := false) {
    global ConfigFilePath, CornerRadius, FillColor, FrameColor, MaskColor, OpenPositionMode, Size, StealMouseInput

    configText := FileRead(ConfigFilePath, "UTF-8")
    if createBackup
        BackupConfigFile()

    configText := ReplaceConfigAssignment(configText, "Size", SerializeSizeConfigValue(Size))
    configText := ReplaceConfigAssignment(configText, "CornerRadius", CornerRadius + 0)
    configText := ReplaceConfigAssignment(configText, "MaskColor", SerializeAhkString(StrUpper(MaskColor)))
    configText := ReplaceConfigAssignment(configText, "FrameColor", SerializeAhkString(StrUpper(FrameColor)))
    configText := ReplaceConfigAssignment(configText, "FillColor", SerializeAhkString(StrUpper(FillColor)))
    configText := ReplaceConfigAssignment(configText, "OpenPositionMode", SerializeAhkString(OpenPositionMode))
    configText := ReplaceConfigAssignment(configText, "StealMouseInput", BoolToAhk(StealMouseInput))
    configText := ReplaceManagedLayoutBlock(configText)

    file := FileOpen(ConfigFilePath, "w", "UTF-8")
    if !IsObject(file)
        throw Error("Could not open config file for writing: " ConfigFilePath)
    file.Write(configText)
    file.Close()
}

CreateButtonCell(gui, textPlacements, pageIndex, rowIndex, colIndex, cfg, x, y, size := 108) {
    global BorderThickness, CornerRadius, FrameInset, InnerBorderInset, InnerBorderThickness, PrimaryBorderInset

    if IsSelectedCell(pageIndex, rowIndex, colIndex)
        CreateSolidLayer(gui, x - 4, y - 4, size + 8, size + 8, "FFFFFF", CornerRadius)

    if !HasVisualContent(cfg)
        return

    if cfg.imagePath != ""
    {
        CreateSolidLayer(gui, x, y, size, size, cfg.backgroundColor, CornerRadius)
        gui.Add("Picture", "x" x " y" y " w" size " h" size, cfg.imagePath)
        return
    }

    CreateSolidLayer(gui, x, y, size, size, cfg.frameColor, CornerRadius)
    CreateSolidLayer(gui, x + FrameInset, y + FrameInset, size - FrameInset * 2, size - FrameInset * 2, cfg.backgroundColor, Max(0, CornerRadius - FrameInset))
    CreateSolidLayer(gui, x + PrimaryBorderInset, y + PrimaryBorderInset, size - PrimaryBorderInset * 2, size - PrimaryBorderInset * 2, cfg.borderColor, Max(0, CornerRadius - PrimaryBorderInset))
    innerInset := PrimaryBorderInset + BorderThickness
    CreateSolidLayer(gui, x + innerInset, y + innerInset, size - innerInset * 2, size - innerInset * 2, cfg.backgroundColor, Max(0, CornerRadius - innerInset))

    if cfg.doubleBorder
    {
        CreateSolidLayer(gui, x + InnerBorderInset, y + InnerBorderInset, size - InnerBorderInset * 2, size - InnerBorderInset * 2, cfg.borderColor, Max(0, CornerRadius - InnerBorderInset))
        innerFillInset := InnerBorderInset + InnerBorderThickness
        CreateSolidLayer(gui, x + innerFillInset, y + innerFillInset, size - innerFillInset * 2, size - innerFillInset * 2, cfg.backgroundColor, Max(0, CornerRadius - innerFillInset))
    }

    buttonText := GetButtonDisplayText(cfg)
    if buttonText != ""
    {
        lineGap := 2
        lines := StrSplit(buttonText, "`n")
        controls := []

        for _, lineText in lines
        {
            txt := gui.Add("Text", "x-2000 y-2000 Center +0x200 +BackgroundTrans", lineText)
            txt.SetFont("s9 Bold", "Segoe UI")
            txt.Opt("c" cfg.textColor)
            controls.Push(txt)
        }

        textPlacements.Push({x: x, y: y, size: size, lineGap: lineGap, controls: controls})
    }
}

CreateSolidLayer(gui, x, y, w, h, color, radius := 0) {
    if w <= 0 || h <= 0
        return

    ctrl := gui.Add("Text", "x" x " y" y " w" w " h" h " Background" color, "")
    if radius > 0
        ApplyRoundedRegion(ctrl.Hwnd, w, h, radius)
}

BuildGrid(gui, pageIndex, layout, textPlacements) {
    global BtnSize

    for rowIndex, row in layout
    {
        for colIndex, cfg in row
        {
            GetGridCellPos(rowIndex, colIndex, &x, &y)
            CreateButtonCell(gui, textPlacements, pageIndex, rowIndex, colIndex, cfg, x, y, BtnSize)
        }
    }
}

GetGridCellPos(row, col, &x, &y) {
    global BtnSize, BtnGap, GridMargin

    x := GridMargin + (col - 1) * (BtnSize + BtnGap)
    y := GridMargin + (row - 1) * (BtnSize + BtnGap)
}

ApplyRoundedRegion(hwnd, w, h, radius) {
    if radius <= 0
        return

    diameter := radius * 2
    hRegion := DllCall("CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", w + 1, "Int", h + 1, "Int", diameter, "Int", diameter, "Ptr")
    DllCall("SetWindowRgn", "Ptr", hwnd, "Ptr", hRegion, "Int", True)
}

FinalizeTextLayout(textPlacements) {
    for _, placement in textPlacements
    {
        metrics := []
        blockH := 0

        for _, ctrl in placement.controls
        {
            ctrl.GetPos(,, &textW, &textH)
            metrics.Push({ctrl: ctrl, w: textW, h: textH})
            blockH += textH
        }
        blockH += Max(0, metrics.Length - 1) * placement.lineGap

        lineY := placement.y + Floor((placement.size - blockH) / 2)
        textInset := 6
        availableW := placement.size - textInset * 2
        for _, line in metrics
        {
            targetW := Min(placement.size, Max(line.w + 8, availableW))
            lineX := placement.x + Floor((placement.size - targetW) / 2)
            line.ctrl.Move(lineX, lineY, targetW, line.h + 2)
            lineY += line.h + placement.lineGap
        }
    }
}

HandleLeftButtonUp(wParam, lParam, msg, hwnd) {
    global ButtonPages, CurrentPageIndex, EditMode, PageGuis, PanelVisible

    if !PanelVisible
        return

    currentGui := PageGuis[CurrentPageIndex]
    rootHwnd := DllCall("GetAncestor", "Ptr", hwnd, "UInt", 2, "Ptr")
    if rootHwnd != currentGui.Hwnd
        return

    MouseGetPos &mouseX, &mouseY
    point := Buffer(8, 0)
    NumPut("Int", mouseX, point, 0)
    NumPut("Int", mouseY, point, 4)
    DllCall("ScreenToClient", "Ptr", currentGui.Hwnd, "Ptr", point)
    clientX := NumGet(point, 0, "Int")
    clientY := NumGet(point, 4, "Int")

    cell := GetButtonCellAtClientPos(ButtonPages[CurrentPageIndex], clientX, clientY)
    if !IsObject(cell)
        return

    if IsCenterCell(cell.row, cell.col) && IsRightAltModifierDown()
    {
        if EditMode
            ExitLayoutEditMode(true)
        else
            EnterLayoutEditMode(false)
        return
    }

    if EditMode
    {
        HandleEditModeClick(CurrentPageIndex, cell.row, cell.col)
        return
    }

    if IsObject(cell.cfg) && IsObject(cell.cfg.action)
        ActivateButton(cell.cfg)
}

GetButtonCellAtClientPos(layout, clientX, clientY) {
    global BtnGap, BtnSize, GridCols, GridMargin, GridRows

    stride := BtnSize + BtnGap
    relX := clientX - GridMargin
    relY := clientY - GridMargin

    if relX < 0 || relY < 0
        return 0

    col := Floor(relX / stride) + 1
    row := Floor(relY / stride) + 1
    if col < 1 || col > GridCols || row < 1 || row > GridRows
        return 0

    if Mod(relX, stride) >= BtnSize || Mod(relY, stride) >= BtnSize
        return 0

    return {cfg: layout[row][col], row: row, col: col}
}

ActivateButton(cfg) {
    global LastActiveHwnd, PageGuis, CurrentPageIndex, PanelVisible

    if !IsObject(cfg.action)
        return

    if IsPageCycleAction(cfg.action)
    {
        CyclePage()
        return
    }

    targetHwnd := LastActiveHwnd
    PanelVisible := false
    PageGuis[CurrentPageIndex].Hide()
    if targetHwnd && WinExist("ahk_id " targetHwnd)
        WinActivate("ahk_id " targetHwnd)
    Sleep 40
    RunButtonAction(cfg.action)
}

RunButtonAction(action) {
    for _, step in GetActionSteps(action)
    {
        if step.type = "send"
            Send(step.value)
        else if step.type = "sleep"
            Sleep(step.value)
        else
            throw Error("Unknown button action type: " step.type)
    }
}

IsRightAltModifierDown() {
    return GetKeyState("RAlt", "P")
}

; === LAYOUT ===
RebuildPageGuis(false)

OnMessage(0x0202, HandleLeftButtonUp)

HidePanel(*) {
    global EditMode, EditSwapSelection, LastActiveHwnd, PageGuis, PanelVisible

    wasEditing := EditMode || IsObject(EditSwapSelection)

    PanelVisible := false
    EditMode := false
    EditSwapSelection := 0
    CloseButtonEditor()
    CloseConfigEditor()
    HideAllPages()
    if wasEditing
        RebuildPageGuis(false)
    if LastActiveHwnd && WinExist("ahk_id " LastActiveHwnd)
        WinActivate("ahk_id " LastActiveHwnd)
}

GetPanelPosition(&panelX, &panelY) {
    global CenterClientX, CenterClientY, GuiH, GuiW, OpenPositionMode

    MouseGetPos &mouseX, &mouseY
    GetMouseMonitorWorkArea(mouseX, mouseY, &monLeft, &monTop, &monRight, &monBottom)

    switch OpenPositionMode
    {
        case "mouse":
            panelX := mouseX - CenterClientX
            panelY := mouseY - CenterClientY

        case "auto-split":
            GetHalfPanelPosition("auto", mouseX, monLeft, monTop, monRight, monBottom, &panelX, &panelY)

        case "always-left":
            GetHalfPanelPosition("left", mouseX, monLeft, monTop, monRight, monBottom, &panelX, &panelY)

        case "always-right":
            GetHalfPanelPosition("right", mouseX, monLeft, monTop, monRight, monBottom, &panelX, &panelY)

        default:
            GetHalfPanelPosition("auto", mouseX, monLeft, monTop, monRight, monBottom, &panelX, &panelY)
    }

    panelX := Clamp(panelX, monLeft, monRight - GuiW)
    panelY := Clamp(panelY, monTop, monBottom - GuiH)
}

GetMouseMonitorWorkArea(mouseX, mouseY, &monLeft, &monTop, &monRight, &monBottom) {
    Loop MonitorGetCount()
    {
        MonitorGetWorkArea(A_Index, &monLeft, &monTop, &monRight, &monBottom)
        if mouseX >= monLeft && mouseX < monRight && mouseY >= monTop && mouseY < monBottom
            return
    }

    MonitorGetWorkArea(, &monLeft, &monTop, &monRight, &monBottom)
}

GetHalfPanelPosition(mode, mouseX, monLeft, monTop, monRight, monBottom, &panelX, &panelY) {
    global GuiH, GuiW

    halfWidth := (monRight - monLeft) / 2
    if mode = "left"
        targetCenterX := monLeft + (halfWidth / 2)
    else if mode = "right"
        targetCenterX := monLeft + halfWidth + (halfWidth / 2)
    else if mouseX < monLeft + halfWidth
        targetCenterX := monLeft + (halfWidth / 2)
    else
        targetCenterX := monLeft + halfWidth + (halfWidth / 2)

    targetCenterY := monTop + ((monBottom - monTop) / 2)
    panelX := Round(targetCenterX - (GuiW / 2))
    panelY := Round(targetCenterY - (GuiH / 2))
}

Clamp(value, minValue, maxValue) {
    if maxValue < minValue
        return minValue
    return Max(minValue, Min(value, maxValue))
}

RebuildPageGuis(preserveVisible := true) {
    global ButtonPages, CurrentPageIndex, PageGuis, PanelVisible

    shouldRestoreVisible := preserveVisible && PanelVisible && PageGuis.Length >= CurrentPageIndex
    if shouldRestoreVisible
        PageGuis[CurrentPageIndex].GetPos(&panelX, &panelY)

    for _, pageGui in PageGuis
    {
        try pageGui.Destroy()
    }

    PageGuis := []
    for _, layout in ButtonPages
        PageGuis.Push(CreatePageGui(layout))

    if shouldRestoreVisible
        ShowCurrentPage(panelX, panelY)
    else
        PanelVisible := false
}

CreateEditModeChrome(gui) {
    global GuiH, GuiW

    gui.Add("Text", "x0 y0 w" GuiW " h" GuiH " Background111111", "")
    gui.Add("Text", "x0 y0 w" GuiW " h4 BackgroundFFFFFF", "")
    gui.Add("Text", "x0 y" (GuiH - 4) " w" GuiW " h4 BackgroundFFFFFF", "")
    gui.Add("Text", "x0 y0 w4 h" GuiH " BackgroundFFFFFF", "")
    gui.Add("Text", "x" (GuiW - 4) " y0 w4 h" GuiH " BackgroundFFFFFF", "")
}

IsSelectedCell(pageIndex, rowIndex, colIndex) {
    global EditMode, EditSwapSelection

    return EditMode
        && IsObject(EditSwapSelection)
        && EditSwapSelection.pageIndex = pageIndex
        && EditSwapSelection.row = rowIndex
        && EditSwapSelection.col = colIndex
}

HandleEditModeClick(pageIndex, rowIndex, colIndex) {
    global EditSwapSelection, PanelVisible

    if IsCenterCell(rowIndex, colIndex)
    {
        ToggleConfigEditor()
        return
    }

    if IsRightAltModifierDown()
    {
        ToggleButtonEditor(pageIndex, rowIndex, colIndex)
        return
    }

    if IsObject(EditSwapSelection)
        if EditSwapSelection.pageIndex = pageIndex && EditSwapSelection.row = rowIndex && EditSwapSelection.col = colIndex
        {
            EditSwapSelection := 0
            RebuildPageGuis(PanelVisible)
            return
        }

    if !IsObject(EditSwapSelection)
    {
        EditSwapSelection := {pageIndex: pageIndex, row: rowIndex, col: colIndex}
        RebuildPageGuis(PanelVisible)
        return
    }

    SwapButtonCells(EditSwapSelection, {pageIndex: pageIndex, row: rowIndex, col: colIndex})
    EditSwapSelection := 0
    PersistButtonPages()
}

SwapButtonCells(firstCell, secondCell) {
    global ButtonPages

    tempCfg := ButtonPages[firstCell.pageIndex][firstCell.row][firstCell.col]
    ButtonPages[firstCell.pageIndex][firstCell.row][firstCell.col] := ButtonPages[secondCell.pageIndex][secondCell.row][secondCell.col]
    ButtonPages[secondCell.pageIndex][secondCell.row][secondCell.col] := tempCfg
}

PersistButtonPages(createBackup := false) {
    global PanelVisible

    ApplyCurrentSizeProfile()
    WriteConfigStateToFile(createBackup)
    RebuildPageGuis(PanelVisible)
}

EnterLayoutEditMode(openConfig := false) {
    global EditMode, EditSwapSelection, PanelVisible

    if EditMode
    {
        if openConfig
            OpenConfigEditor()
        return
    }

    EditMode := true
    EditSwapSelection := 0
    CloseButtonEditor()
    CloseConfigEditor()
    RebuildPageGuis(PanelVisible)
    if !PanelVisible
        ShowPanel()
    if openConfig
        OpenConfigEditor()
}

ExitLayoutEditMode(hidePanelOnExit := true) {
    global EditMode, EditSwapSelection

    if !EditMode
        return

    EditMode := false
    EditSwapSelection := 0
    CloseButtonEditor()
    CloseConfigEditor()
    if hidePanelOnExit
        HidePanel()
    RebuildPageGuis(false)
}

ToggleEditMode() {
    global EditMode

    if EditMode
        ExitLayoutEditMode(true)
    else
        EnterLayoutEditMode(false)
}

ToggleButtonEditor(pageIndex, rowIndex, colIndex) {
    global EditDialogState

    CloseConfigEditor()
    if IsObject(EditDialogState)
    {
        if EditDialogState.pageIndex = pageIndex && EditDialogState.row = rowIndex && EditDialogState.col = colIndex
        {
            CloseButtonEditor()
            return
        }
        CloseButtonEditor()
    }

    OpenButtonEditor(pageIndex, rowIndex, colIndex)
}

ToggleConfigEditor() {
    global ConfigDialogState

    CloseButtonEditor()
    if IsObject(ConfigDialogState)
    {
        CloseConfigEditor()
        return
    }

    OpenConfigEditor()
}

OpenButtonEditor(pageIndex, rowIndex, colIndex) {
    global ButtonPages, CopiedButtonCfg, EditDialogState, PageGuis, CurrentPageIndex

    cfg := ButtonPages[pageIndex][rowIndex][colIndex]
    actionType := GetButtonActionType(cfg.action)
    editorGui := Gui("+AlwaysOnTop +ToolWindow", "Edit StarHUD Button")
    editorGui.MarginX := 12
    editorGui.MarginY := 10

    editorGui.Add("Text", "xm", "Button name")
    nameEdit := editorGui.Add("Edit", "xm w260 r3", FormatButtonTitleForEditor(cfg))
    editorGui.Add("Text", "xm y+2 c808080", "Press Enter for a new line. ``n also works.")

    editorGui.Add("Text", "xm y+8", "Text color")
    textColorEdit := editorGui.Add("Edit", "xm w120", cfg.textColor)
    textColorPickButton := editorGui.Add("Button", "x+8 yp-2 w54", "Pick")
    editorGui.Add("Text", "xm y+8", "Line color")
    borderColorEdit := editorGui.Add("Edit", "xm w120", cfg.borderColor)
    borderColorPickButton := editorGui.Add("Button", "x+8 yp-2 w54", "Pick")

    lineModeOptions := ["single", "double"]
    editorGui.Add("Text", "xm y+8", "Title line mode")
    lineModeList := editorGui.Add("DropDownList", "xm w160", lineModeOptions)
    ChooseDropDownValue(lineModeList, cfg.titleLineMode, lineModeOptions)

    actionTypeOptions := ["None", "SendKey", "ChordKey", "HoldKey", "DoubleTapKey", "PageCycle"]
    editorGui.Add("Text", "xm y+8", "Action type")
    actionTypeList := editorGui.Add("DropDownList", "xm w180", actionTypeOptions)
    ChooseDropDownValue(actionTypeList, actionType, actionTypeOptions)

    key1Label := editorGui.Add("Text", "xm y+8", "Key")
    key1Edit := editorGui.Add("Edit", "xm w120", GetActionEditorPrimaryValue(cfg.action))
    key2Label := editorGui.Add("Text", "x+12 yp", "Modifier")
    key2Edit := editorGui.Add("Edit", "x+0 w120", GetActionEditorSecondaryValue(cfg.action))

    durationLabel := editorGui.Add("Text", "xm y+8", "Duration ms")
    durationEdit := editorGui.Add("Edit", "xm w120", GetActionEditorDurationValue(cfg.action))
    delayLabel := editorGui.Add("Text", "x+12 yp", "Delay ms")
    delayEdit := editorGui.Add("Edit", "x+0 w120", GetActionEditorDelayValue(cfg.action))

    if cfg.imagePath != ""
        editorGui.Add("Text", "xm y+8 cAAAAAA", "Image buttons keep their current image path.")

    deleteButton := editorGui.Add("Button", "xm y+12 w76", "Delete")
    copyButton := editorGui.Add("Button", "x+8 w76", "Copy")
    pasteButton := editorGui.Add("Button", "x+8 w76", "Paste")
    saveButton := editorGui.Add("Button", "xm y+10 w120 Default", "Save")
    cancelButton := editorGui.Add("Button", "x+12 w120", "Cancel")

    EditDialogState := {
        gui: editorGui,
        pageIndex: pageIndex,
        row: rowIndex,
        col: colIndex,
        nameEdit: nameEdit,
        textColorEdit: textColorEdit,
        borderColorEdit: borderColorEdit,
        lineModeList: lineModeList,
        actionTypeList: actionTypeList,
        key1Label: key1Label,
        key1Edit: key1Edit,
        key2Label: key2Label,
        key2Edit: key2Edit,
        durationLabel: durationLabel,
        durationEdit: durationEdit,
        delayLabel: delayLabel,
        delayEdit: delayEdit,
        deleteButton: deleteButton,
        copyButton: copyButton,
        pasteButton: pasteButton
    }

    actionTypeList.OnEvent("Change", UpdateButtonEditorFields)
    textColorPickButton.OnEvent("Click", PickButtonEditorColor.Bind("text"))
    borderColorPickButton.OnEvent("Click", PickButtonEditorColor.Bind("border"))
    deleteButton.OnEvent("Click", DeleteButtonFromEditor)
    copyButton.OnEvent("Click", CopyButtonFromEditor)
    pasteButton.OnEvent("Click", PasteButtonIntoEditor)
    saveButton.OnEvent("Click", SaveButtonEditor)
    cancelButton.OnEvent("Click", CloseButtonEditor)
    editorGui.OnEvent("Close", CloseButtonEditor)
    editorGui.OnEvent("Escape", CloseButtonEditor)
    SetEditorControlEnabled(pasteButton, IsObject(CopiedButtonCfg))
    UpdateButtonEditorFields()
    editorGui.Show("AutoSize")
}

ChooseDropDownValue(ctrl, value, options) {
    valueText := Format("{}", value)
    for optionIndex, optionText in options
    {
        if optionText = valueText
        {
            ctrl.Choose(optionIndex)
            return
        }
    }
    ctrl.Choose(1)
}

FormatButtonTitleForEditor(cfg) {
    return FormatButtonTitle(cfg.text, cfg.titleLineMode)
}

ParseButtonTitleFromEditor(titleText, selectedLineMode) {
    convertedTitle := Format("{}", titleText)
    convertedTitle := StrReplace(convertedTitle, "`r`n", "`n")
    convertedTitle := StrReplace(convertedTitle, "``n", "`n")
    resolvedLineMode := InStr(convertedTitle, "`n") ? "double" : selectedLineMode
    return {
        text: convertedTitle,
        lineMode: resolvedLineMode
    }
}

UpdateButtonEditorFields(*) {
    global EditDialogState

    if !IsObject(EditDialogState)
        return

    actionType := EditDialogState.actionTypeList.Text
    SetEditorFieldVisible(EditDialogState.key1Label, EditDialogState.key1Edit, false)
    SetEditorFieldVisible(EditDialogState.key2Label, EditDialogState.key2Edit, false)
    SetEditorFieldVisible(EditDialogState.durationLabel, EditDialogState.durationEdit, false)
    SetEditorFieldVisible(EditDialogState.delayLabel, EditDialogState.delayEdit, false)
    switch actionType
    {
        case "None":
            SetEditorControlEnabled(EditDialogState.key1Edit, false)
            SetEditorControlEnabled(EditDialogState.key2Edit, false)
            SetEditorControlEnabled(EditDialogState.durationEdit, false)
            SetEditorControlEnabled(EditDialogState.delayEdit, false)

        case "SendKey":
            EditDialogState.key1Label.Text := "Key"
            SetEditorFieldVisible(EditDialogState.key1Label, EditDialogState.key1Edit, true)
            SetEditorControlEnabled(EditDialogState.key1Edit, true)
            SetEditorControlEnabled(EditDialogState.key2Edit, false)
            SetEditorControlEnabled(EditDialogState.durationEdit, false)
            SetEditorControlEnabled(EditDialogState.delayEdit, false)

        case "ChordKey":
            EditDialogState.key1Label.Text := "Modifier"
            EditDialogState.key2Label.Text := "Key"
            EditDialogState.delayLabel.Text := "Delay ms"
            SetEditorFieldVisible(EditDialogState.key1Label, EditDialogState.key1Edit, true)
            SetEditorFieldVisible(EditDialogState.key2Label, EditDialogState.key2Edit, true)
            SetEditorFieldVisible(EditDialogState.delayLabel, EditDialogState.delayEdit, true)
            SetEditorControlEnabled(EditDialogState.key1Edit, true)
            SetEditorControlEnabled(EditDialogState.key2Edit, true)
            SetEditorControlEnabled(EditDialogState.durationEdit, false)
            SetEditorControlEnabled(EditDialogState.delayEdit, true)

        case "HoldKey":
            EditDialogState.key1Label.Text := "Key"
            EditDialogState.durationLabel.Text := "Duration ms"
            SetEditorFieldVisible(EditDialogState.key1Label, EditDialogState.key1Edit, true)
            SetEditorFieldVisible(EditDialogState.durationLabel, EditDialogState.durationEdit, true)
            SetEditorControlEnabled(EditDialogState.key1Edit, true)
            SetEditorControlEnabled(EditDialogState.key2Edit, false)
            SetEditorControlEnabled(EditDialogState.durationEdit, true)
            SetEditorControlEnabled(EditDialogState.delayEdit, false)

        case "DoubleTapKey":
            EditDialogState.key1Label.Text := "Key"
            EditDialogState.delayLabel.Text := "Delay ms"
            SetEditorFieldVisible(EditDialogState.key1Label, EditDialogState.key1Edit, true)
            SetEditorFieldVisible(EditDialogState.delayLabel, EditDialogState.delayEdit, true)
            SetEditorControlEnabled(EditDialogState.key1Edit, true)
            SetEditorControlEnabled(EditDialogState.key2Edit, false)
            SetEditorControlEnabled(EditDialogState.durationEdit, false)
            SetEditorControlEnabled(EditDialogState.delayEdit, true)

        case "PageCycle":
            SetEditorControlEnabled(EditDialogState.key1Edit, false)
            SetEditorControlEnabled(EditDialogState.key2Edit, false)
            SetEditorControlEnabled(EditDialogState.durationEdit, false)
            SetEditorControlEnabled(EditDialogState.delayEdit, false)
    }

    try EditDialogState.gui.Show("AutoSize")
}

SetEditorControlEnabled(ctrl, isEnabled) {
    ctrl.Opt(isEnabled ? "-Disabled" : "+Disabled")
}

SetEditorFieldVisible(labelCtrl, inputCtrl, isVisible) {
    labelCtrl.Opt(isVisible ? "-Hidden" : "+Hidden")
    inputCtrl.Opt(isVisible ? "-Hidden" : "+Hidden")
}

GetActionEditorPrimaryValue(action) {
    actionType := GetButtonActionType(action)
    if actionType = "ChordKey"
        return IsObject(action) ? action.modifierValue : ""
    if IsObject(action)
        return action.keyValue
    return ""
}

GetActionEditorSecondaryValue(action) {
    if IsObject(action) && GetButtonActionType(action) = "ChordKey"
        return action.keyValue
    return ""
}

GetActionEditorDurationValue(action) {
    if IsObject(action) && action.duration
        return action.duration
    return ""
}

GetActionEditorDelayValue(action) {
    if IsObject(action) && action.delay
        return action.delay
    return ""
}

SaveButtonEditor(*) {
    global ButtonPages, EditDialogState

    if !IsObject(EditDialogState)
        return

    try
    {
        cfg := ButtonPages[EditDialogState.pageIndex][EditDialogState.row][EditDialogState.col]
        titleInfo := ParseButtonTitleFromEditor(EditDialogState.nameEdit.Value, EditDialogState.lineModeList.Text)
        updatedCfg := ButtonCfg(
            titleInfo.text,
            CreateActionFromEditor(
                EditDialogState.actionTypeList.Text,
                EditDialogState.key1Edit.Value,
                EditDialogState.key2Edit.Value,
                EditDialogState.durationEdit.Value,
                EditDialogState.delayEdit.Value
            ),
            NormalizeColorInput(EditDialogState.borderColorEdit.Value, cfg.borderColor),
            NormalizeColorInput(EditDialogState.textColorEdit.Value, cfg.textColor),
            cfg.doubleBorder,
            cfg.imagePath,
            cfg.frameColor,
            cfg.backgroundColor,
            titleInfo.lineMode
        )

        ButtonPages[EditDialogState.pageIndex][EditDialogState.row][EditDialogState.col] := updatedCfg
        CloseButtonEditor()
        PersistButtonPages()
    }
    catch as err
    {
        MsgBox(err.Message, "StarHUD Edit Error")
    }
}

DeleteButtonFromEditor(*) {
    global ButtonPages, EditDialogState

    if !IsObject(EditDialogState)
        return

    ButtonPages[EditDialogState.pageIndex][EditDialogState.row][EditDialogState.col] := ButtonCfg()
    CloseButtonEditor()
    PersistButtonPages()
}

CopyButtonFromEditor(*) {
    global ButtonPages, CopiedButtonCfg, EditDialogState

    if !IsObject(EditDialogState)
        return

    CopiedButtonCfg := CloneButtonCfg(ButtonPages[EditDialogState.pageIndex][EditDialogState.row][EditDialogState.col])
    CloseButtonEditor()
}

PasteButtonIntoEditor(*) {
    global ButtonPages, CopiedButtonCfg, EditDialogState

    if !IsObject(EditDialogState)
        return
    if !IsObject(CopiedButtonCfg)
    {
        MsgBox("Copy a button first, then open the destination button and click Paste.", "StarHUD Edit Error")
        return
    }

    ButtonPages[EditDialogState.pageIndex][EditDialogState.row][EditDialogState.col] := CloneButtonCfg(CopiedButtonCfg)
    CloseButtonEditor()
    PersistButtonPages()
}

CreateActionFromEditor(actionType, key1Value, key2Value, durationValue, delayValue) {
    primaryKey := Trim(Format("{}", key1Value))
    secondaryKey := Trim(Format("{}", key2Value))

    switch actionType
    {
        case "None":
            return 0
        case "SendKey":
            if primaryKey = ""
                throw Error("SendKey requires a key.")
            return SendKey(primaryKey)
        case "ChordKey":
            if primaryKey = "" || secondaryKey = ""
                throw Error("ChordKey requires both a modifier and a key.")
            return ChordKey(primaryKey, secondaryKey, ParseEditorNumber(delayValue, 30))
        case "HoldKey":
            if primaryKey = ""
                throw Error("HoldKey requires a key.")
            return HoldKey(primaryKey, ParseEditorNumber(durationValue, 1000))
        case "DoubleTapKey":
            if primaryKey = ""
                throw Error("DoubleTapKey requires a key.")
            return DoubleTapKey(primaryKey, ParseEditorNumber(delayValue, 60))
        case "PageCycle":
            return PageCycleAction()
        default:
            throw Error("Unsupported action type: " actionType)
    }
}

ParseEditorNumber(value, defaultValue) {
    textValue := Trim(Format("{}", value))
    if textValue = ""
        return defaultValue
    if !RegExMatch(textValue, "^\d+$")
        throw Error("Expected a whole number, got: " textValue)
    return textValue + 0
}

NormalizeColorInput(colorValue, fallbackValue := "") {
    normalizedColor := Trim(StrReplace(Format("{}", colorValue), "#"))
    if normalizedColor = ""
        return fallbackValue
    if !RegExMatch(normalizedColor, "i)^[0-9a-f]{6}$")
        throw Error("Colors must be 6 hexadecimal characters, for example 00FF88.")
    return StrUpper(normalizedColor)
}

CloseButtonEditor(*) {
    global EditDialogState

    if IsObject(EditDialogState)
    {
        try EditDialogState.gui.Destroy()
        EditDialogState := 0
    }
}

PickButtonEditorColor(colorTarget, *) {
    global EditDialogState

    if !IsObject(EditDialogState)
        return

    if colorTarget = "text"
        ctrl := EditDialogState.textColorEdit
    else if colorTarget = "border"
        ctrl := EditDialogState.borderColorEdit
    else
        throw Error("Unknown button color control: " colorTarget)

    chosenColor := ChooseColorHex(ctrl.Value, EditDialogState.gui.Hwnd)
    if chosenColor != ""
        ctrl.Value := chosenColor
}

GetSizeProfileOptions() {
    global SizeProfiles

    options := []
    for sizeKey, _ in SizeProfiles
        options.Push(sizeKey)
    return options
}

OpenConfigEditor() {
    global ConfigDialogState, CornerRadius, CurrentPageIndex, FillColor, FrameColor, MaskColor, OpenPositionMode, Size, StealMouseInput

    sizeOptions := GetSizeProfileOptions()
    openPositionOptions := ["auto-split", "mouse", "always-left", "always-right"]
    configGui := Gui("+AlwaysOnTop +ToolWindow", "StarHUD Config")
    configGui.MarginX := 12
    configGui.MarginY := 10

    configGui.Add("Text", "xm", "Current page")
    pageInfoText := configGui.Add("Text", "x+8 yp w160", "")

    configGui.Add("Text", "xm y+10", "Size")
    sizeList := configGui.Add("DropDownList", "xm w140", sizeOptions)
    ChooseDropDownValue(sizeList, Size, sizeOptions)
    configGui.Add("Text", "xm y+2 c808080", "Pick the built-in scale profile that best matches your screen.")

    configGui.Add("Text", "xm y+8", "Corner radius")
    cornerRadiusEdit := configGui.Add("Edit", "xm w140", CornerRadius)
    configGui.Add("Text", "xm y+2 c808080", "Rounds button corners. Use 0 for square edges.")

    configGui.Add("Text", "xm y+8", "Mask color")
    maskColorEdit := configGui.Add("Edit", "xm w140", MaskColor)
    maskColorPickButton := configGui.Add("Button", "x+8 yp-2 w54", "Pick")
    configGui.Add("Text", "xm y+2 c808080", "Transparent key color for the HUD window.")

    configGui.Add("Text", "xm y+8", "Frame color")
    frameColorEdit := configGui.Add("Edit", "xm w140", FrameColor)
    frameColorPickButton := configGui.Add("Button", "x+8 yp-2 w54", "Pick")
    configGui.Add("Text", "xm y+2 c808080", "Default outer frame color for button shells.")

    configGui.Add("Text", "xm y+8", "Fill color")
    fillColorEdit := configGui.Add("Edit", "xm w140", FillColor)
    fillColorPickButton := configGui.Add("Button", "x+8 yp-2 w54", "Pick")
    configGui.Add("Text", "xm y+2 c808080", "Default inner fill color behind button labels.")

    configGui.Add("Text", "xm y+8", "Open position")
    openPositionList := configGui.Add("DropDownList", "xm w180", openPositionOptions)
    ChooseDropDownValue(openPositionList, OpenPositionMode, openPositionOptions)
    configGui.Add("Text", "xm y+2 c808080", "Choose where the HUD appears when you open it.")

    stealMouseInputCheck := configGui.Add("CheckBox", "xm y+10", "Steal mouse input")
    stealMouseInputCheck.Value := StealMouseInput ? 1 : 0
    configGui.Add("Text", "xm y+2 c808080", "Block mouse clicks and movement from reaching the app underneath.")

    addPageButton := configGui.Add("Button", "xm y+14 w100", "Add Page")
    deletePageButton := configGui.Add("Button", "x+8 w100", "Delete Page")
    resetPageButton := configGui.Add("Button", "x+8 w100", "Reset Page")
    openFolderButton := configGui.Add("Button", "xm y+8 w160", "Open File Location")
    saveButton := configGui.Add("Button", "xm y+14 w120 Default", "Save")
    closeButton := configGui.Add("Button", "x+12 w120", "Close")

    ConfigDialogState := {
        gui: configGui,
        pageInfoText: pageInfoText,
        sizeList: sizeList,
        cornerRadiusEdit: cornerRadiusEdit,
        maskColorEdit: maskColorEdit,
        frameColorEdit: frameColorEdit,
        fillColorEdit: fillColorEdit,
        openPositionList: openPositionList,
        stealMouseInputCheck: stealMouseInputCheck
    }

    maskColorPickButton.OnEvent("Click", PickConfigDialogColor.Bind("maskColorEdit"))
    frameColorPickButton.OnEvent("Click", PickConfigDialogColor.Bind("frameColorEdit"))
    fillColorPickButton.OnEvent("Click", PickConfigDialogColor.Bind("fillColorEdit"))
    addPageButton.OnEvent("Click", AddConfigPage)
    deletePageButton.OnEvent("Click", DeleteConfigPage)
    resetPageButton.OnEvent("Click", ResetConfigPage)
    openFolderButton.OnEvent("Click", OpenConfigFileLocation)
    saveButton.OnEvent("Click", SaveConfigEditor)
    closeButton.OnEvent("Click", CloseConfigEditor)
    configGui.OnEvent("Close", CloseConfigEditor)
    configGui.OnEvent("Escape", CloseConfigEditor)
    UpdateConfigDialogPageInfo()
    configGui.Show("AutoSize")
}

UpdateConfigDialogPageInfo() {
    global ButtonPages, ConfigDialogState, CurrentPageIndex

    if !IsObject(ConfigDialogState)
        return

    ConfigDialogState.pageInfoText.Text := "Page " CurrentPageIndex " of " ButtonPages.Length
}

PickConfigDialogColor(controlKey, *) {
    global ConfigDialogState

    if !IsObject(ConfigDialogState)
        return

    switch controlKey
    {
        case "maskColorEdit":
            ctrl := ConfigDialogState.maskColorEdit
        case "frameColorEdit":
            ctrl := ConfigDialogState.frameColorEdit
        case "fillColorEdit":
            ctrl := ConfigDialogState.fillColorEdit
        default:
            throw Error("Unknown config color control: " controlKey)
    }
    chosenColor := ChooseColorHex(ctrl.Value, ConfigDialogState.gui.Hwnd)
    if chosenColor != ""
        ctrl.Value := chosenColor
}

ChooseColorHex(initialHex := "", ownerHwnd := 0) {
    static customColors := Buffer(64, 0)
    if A_PtrSize = 8
    {
        structSize := 72
        hwndOffset := 8
        rgbOffset := 24
        customColorsOffset := 32
        flagsOffset := 40
    }
    else
    {
        structSize := 36
        hwndOffset := 4
        rgbOffset := 12
        customColorsOffset := 16
        flagsOffset := 20
    }

    chooseColor := Buffer(structSize, 0)
    initialColor := ColorHexToColorRef(NormalizeColorInput(initialHex, "FFFFFF"))
    NumPut("UInt", structSize, chooseColor, 0)
    NumPut("Ptr", ownerHwnd, chooseColor, hwndOffset)
    NumPut("UInt", initialColor, chooseColor, rgbOffset)
    NumPut("Ptr", customColors.Ptr, chooseColor, customColorsOffset)
    NumPut("UInt", 0x00000003, chooseColor, flagsOffset)
    if !DllCall("Comdlg32\ChooseColorW", "Ptr", chooseColor, "Int")
        return ""
    return ColorRefToHex(NumGet(chooseColor, rgbOffset, "UInt"))
}

ColorHexToColorRef(colorHex) {
    rgbValue := ("0x" NormalizeColorInput(colorHex, "FFFFFF")) + 0
    redValue := (rgbValue >> 16) & 0xFF
    greenValue := (rgbValue >> 8) & 0xFF
    blueValue := rgbValue & 0xFF
    return redValue | (greenValue << 8) | (blueValue << 16)
}

ColorRefToHex(colorRef) {
    redValue := colorRef & 0xFF
    greenValue := (colorRef >> 8) & 0xFF
    blueValue := (colorRef >> 16) & 0xFF
    return Format("{:02X}{:02X}{:02X}", redValue, greenValue, blueValue)
}

ApplyConfigDialogValues() {
    global ConfigDialogState, CornerRadius, FillColor, FrameColor, MaskColor, OpenPositionMode, Size, SizeProfiles, StealMouseInput

    if !IsObject(ConfigDialogState)
        return

    oldFrameColor := FrameColor
    oldFillColor := FillColor
    newSize := NormalizeSizeKey(ConfigDialogState.sizeList.Text)
    if !SizeProfiles.Has(newSize)
        throw Error("Unknown Size profile: " newSize)

    Size := newSize
    CornerRadius := ParseEditorNumber(ConfigDialogState.cornerRadiusEdit.Value, 0)
    MaskColor := NormalizeColorInput(ConfigDialogState.maskColorEdit.Value, MaskColor)
    FrameColor := NormalizeColorInput(ConfigDialogState.frameColorEdit.Value, FrameColor)
    FillColor := NormalizeColorInput(ConfigDialogState.fillColorEdit.Value, FillColor)
    OpenPositionMode := ConfigDialogState.openPositionList.Text
    StealMouseInput := ConfigDialogState.stealMouseInputCheck.Value = 1
    RefreshCenterButtonTemplate()
    UpdateButtonsForDefaultColorChange(oldFrameColor, oldFillColor)
}

SaveConfigEditor(*) {
    try
    {
        ApplyConfigDialogValues()
        PersistButtonPages()
        CloseConfigEditor()
    }
    catch as err
    {
        MsgBox(err.Message, "StarHUD Config Error")
    }
}

ReopenConfigEditor() {
    CloseConfigEditor()
    OpenConfigEditor()
}

AddConfigPage(*) {
    global ButtonPages, CurrentPageIndex

    try
    {
        ApplyConfigDialogValues()
        ButtonPages.Push(CreateEmptyPageLayout())
        CurrentPageIndex := ButtonPages.Length
        PersistButtonPages()
        ReopenConfigEditor()
    }
    catch as err
    {
        MsgBox(err.Message, "StarHUD Config Error")
    }
}

DeleteConfigPage(*) {
    global ButtonPages, CurrentPageIndex

    if ButtonPages.Length <= 1
    {
        MsgBox("StarHUD must keep at least one page.", "StarHUD Config")
        return
    }
    if MsgBox("Delete the current page and save a .bak copy of the config first?", "StarHUD Config", "YesNo Icon!") != "Yes"
        return

    try
    {
        ApplyConfigDialogValues()
        ButtonPages.RemoveAt(CurrentPageIndex)
        if CurrentPageIndex > ButtonPages.Length
            CurrentPageIndex := ButtonPages.Length
        PersistButtonPages(true)
        ReopenConfigEditor()
    }
    catch as err
    {
        MsgBox(err.Message, "StarHUD Config Error")
    }
}

ResetConfigPage(*) {
    global ButtonPages, CurrentPageIndex

    if MsgBox("Reset the current page to empty buttons and save a .bak copy first?", "StarHUD Config", "YesNo Icon!") != "Yes"
        return

    try
    {
        ApplyConfigDialogValues()
        ButtonPages[CurrentPageIndex] := CreateEmptyPageLayout()
        PersistButtonPages(true)
        ReopenConfigEditor()
    }
    catch as err
    {
        MsgBox(err.Message, "StarHUD Config Error")
    }
}

OpenConfigFileLocation(*) {
    Run('explorer.exe "' A_ScriptDir '"')
}

CloseConfigEditor(*) {
    global ConfigDialogState

    if IsObject(ConfigDialogState)
    {
        try ConfigDialogState.gui.Destroy()
        ConfigDialogState := 0
    }
}

ShowPanel() {
    global CurrentPageIndex, GuiH, GuiW, PageGuis, LastActiveHwnd

    activeHwnd := WinExist("A")
    if activeHwnd && !IsPageGui(activeHwnd)
        LastActiveHwnd := activeHwnd

    GetPanelPosition(&panelX, &panelY)
    ShowCurrentPage(panelX, panelY)
}

CreatePageGui(layout) {
    global EditMode, GuiH, GuiW, MaskColor, PageGuis, StealMouseInput

    guiOptions := "+AlwaysOnTop -Caption -DPIScale"
    if !StealMouseInput && !EditMode
        guiOptions .= " +E0x08000000"

    pageGui := Gui(guiOptions, "SC Panel")
    pageGui.BackColor := MaskColor
    WinSetTransColor(MaskColor, pageGui.Hwnd)

    if EditMode
        CreateEditModeChrome(pageGui)

    textPlacements := []
    BuildGrid(pageGui, PageGuis.Length + 1, layout, textPlacements)
    pageGui.Show("w" GuiW " h" GuiH " Hide")
    FinalizeTextLayout(textPlacements)
    pageGui.OnEvent("Close", HidePanel)
    pageGui.OnEvent("Escape", HidePanel)

    return pageGui
}

HideAllPages() {
    global PageGuis

    for _, pageGui in PageGuis
        pageGui.Hide()
}

ShowCurrentPage(panelX, panelY) {
    global CurrentPageIndex, EditMode, GuiH, GuiW, PageGuis, PanelVisible, StealMouseInput

    HideAllPages()
    pageGui := PageGuis[CurrentPageIndex]
    showOptions := "x" panelX " y" panelY " w" GuiW " h" GuiH
    if !StealMouseInput && !EditMode
        showOptions := "NA " showOptions

    pageGui.Show(showOptions)
    WinSetAlwaysOnTop 1, "ahk_id " pageGui.Hwnd
    WinMoveTop "ahk_id " pageGui.Hwnd
    if StealMouseInput || EditMode
        WinActivate("ahk_id " pageGui.Hwnd)
    PanelVisible := true
}

CyclePage() {
    global CurrentPageIndex, PageGuis, PanelVisible

    previousPageIndex := CurrentPageIndex
    CurrentPageIndex := Mod(CurrentPageIndex, PageGuis.Length) + 1
    if !PanelVisible
        return

    PageGuis[previousPageIndex].GetPos(&panelX, &panelY)
    ShowCurrentPage(panelX, panelY)
}

IsPageGui(hwnd) {
    global PageGuis

    for _, pageGui in PageGuis
    {
        if pageGui.Hwnd = hwnd
            return true
    }
    return false
}

; ================== TOGGLE ==================
F20::
{
    if PanelVisible
    {
        HidePanel()
    }
    else
    {
        ShowPanel()
    }
}

>!F20::
{
    ToggleEditMode()
}
