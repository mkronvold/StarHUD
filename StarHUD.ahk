#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook()
#UseHook
#WinActivateForce
DetectHiddenWindows True
CoordMode "Mouse", "Screen"

; Editable settings and button/page layout live in the active StarHUD config file.

; Start GDI+
gdiplusStartupInput := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
NumPut("UInt", 1, gdiplusStartupInput, 0)
gdiplusStatus := DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken := 0, "Ptr", gdiplusStartupInput, "Ptr", 0)
GdiplusToken := gdiplusStatus = 0 ? pToken : 0
OnExit(ShutdownGdiplus)

ButtonCfg(text := "", action := 0, borderColor := "00FF88", textColor := "", doubleBorder := false, imagePath := "", frameColorOverride := "", backgroundColor := "", titleLineMode := "", imageFitMode := "cover", showTextOnImage := false, showKeysOnImage := false) {
    global FillColor, FrameColor

    normalizedText := NormalizeConfigTitle(text)
    normalizedImagePath := NormalizeStoredImageReference(imagePath)
    borderStyle := NormalizeBorderStyle(doubleBorder)
    if titleLineMode = ""
        titleLineMode := InferTitleLineMode(text)
    if textColor = ""
        textColor := borderColor
    if frameColorOverride = ""
        frameColorOverride := FrameColor
    if backgroundColor = ""
        backgroundColor := FillColor
    if normalizedImagePath = ""
    {
        showTextOnImage := false
        showKeysOnImage := false
    }

    return {
        text: normalizedText,
        action: action,
        borderColor: borderColor,
        textColor: textColor,
        borderStyle: borderStyle,
        doubleBorder: borderStyle = "double",
        imagePath: normalizedImagePath,
        frameColor: frameColorOverride,
        backgroundColor: backgroundColor,
        titleLineMode: titleLineMode,
        imageFitMode: NormalizeImageFitMode(imageFitMode),
        showTextOnImage: !!showTextOnImage,
        showKeysOnImage: !!showKeysOnImage
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

NormalizeToggleHotkeyInput(keyValue) {
    keyText := Trim(NormalizeActionKey(keyValue))
    if keyText = ""
        throw Error("Toggle key cannot be empty.")
    return keyText
}

NormalizeImageFitMode(fitMode) {
    fitText := StrLower(Trim(Format("{}", fitMode)))
    if fitText = ""
        return "cover"
    switch fitText
    {
        case "cover", "contain", "stretch", "center":
            return fitText
        default:
            throw Error("Unsupported image fit mode: " fitText)
    }
}

NormalizeBorderStyle(borderStyleValue) {
    styleText := StrLower(Trim(Format("{}", borderStyleValue)))
    switch styleText
    {
        case "", "false", "0", "single":
            return "single"
        case "true", "1", "double":
            return "double"
        case "none":
            return "none"
        default:
            throw Error("Unsupported border style: " styleText)
    }
}

GetImagesFolderPath() {
    return A_ScriptDir "\images"
}

EnsureImagesFolderExists() {
    imagesFolder := GetImagesFolderPath()
    if !DirExist(imagesFolder)
        DirCreate(imagesFolder)
    return imagesFolder
}

IsAbsoluteFilePath(pathText) {
    normalizedPath := StrReplace(Format("{}", pathText), "/", "\")
    return RegExMatch(normalizedPath, "i)^(?:[A-Z]:\\|\\\\)")
}

NormalizeStoredImageReference(imagePath) {
    imageText := Trim(Format("{}", imagePath))
    if imageText = ""
        return ""

    imageText := StrReplace(imageText, "/", "\")
    imagesFolder := StrReplace(GetImagesFolderPath(), "/", "\")
    normalizedImagesFolder := RTrim(imagesFolder, "\")
    if InStr(StrLower(imageText), StrLower(normalizedImagesFolder "\")) = 1
        return LTrim(SubStr(imageText, StrLen(normalizedImagesFolder) + 2), "\")
    if RegExMatch(imageText, "i)^images\\")
        return SubStr(imageText, 8)
    return imageText
}

ResolveButtonImagePath(imagePath) {
    imageText := Trim(Format("{}", imagePath))
    if imageText = ""
        return ""

    imageText := StrReplace(imageText, "/", "\")
    if IsAbsoluteFilePath(imageText)
        return FileExist(imageText) ? imageText : ""

    relativeImagePath := NormalizeStoredImageReference(imageText)
    if relativeImagePath = ""
        return ""

    imagesPath := GetImagesFolderPath() "\" relativeImagePath
    if FileExist(imagesPath)
        return imagesPath

    legacyPath := A_ScriptDir "\" relativeImagePath
    if FileExist(legacyPath)
        return legacyPath

    return ""
}

IsPathInImagesFolder(filePath) {
    normalizedFilePath := StrReplace(Format("{}", filePath), "/", "\")
    normalizedImagesFolder := RTrim(StrReplace(GetImagesFolderPath(), "/", "\"), "\")
    return InStr(StrLower(normalizedFilePath), StrLower(normalizedImagesFolder "\")) = 1
}

GetImageEditorValue(imagePath) {
    return NormalizeStoredImageReference(imagePath)
}

NormalizeSelectedImagePath(selectedPath) {
    normalizedPath := StrReplace(Trim(Format("{}", selectedPath)), "/", "\")
    if normalizedPath = ""
        return ""
    if !IsPathInImagesFolder(normalizedPath)
        throw Error("Button images must be selected from the images folder or one of its subfolders.")
    return NormalizeStoredImageReference(normalizedPath)
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
    normalizedText := Format("{}", text)
    normalizedText := StrReplace(normalizedText, "`r`n", "`n")
    normalizedText := StrReplace(normalizedText, "`r", "`n")

    normalizedLines := []
    for _, lineText in StrSplit(normalizedText, "`n")
    {
        lineText := RegExReplace(lineText, "\s+", " ")
        lineText := Trim(lineText)
        if lineText != ""
            normalizedLines.Push(lineText)
    }
    if normalizedLines.Length = 0
        return ""
    return ArrayJoin(normalizedLines, "`n")
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

NormalizeButtonGapOverride(value, strict := true) {
    textValue := Trim(Format("{}", value))
    if textValue = ""
        return ""
    if !RegExMatch(textValue, "^\d+$")
    {
        if strict
            throw Error("Button gap override must be a whole number.")
        return ""
    }
    return textValue + 0
}

SerializeButtonGapOverrideValue(value) {
    normalizedValue := NormalizeButtonGapOverride(value)
    if normalizedValue = ""
        return '""'
    return normalizedValue + 0
}

GetEffectiveButtonGap(sizeKey := "") {
    global BtnGap, ButtonGapOverride, Size, SizeProfiles

    normalizedOverride := NormalizeButtonGapOverride(ButtonGapOverride, false)
    if normalizedOverride != ""
        return normalizedOverride
    if sizeKey = ""
        sizeKey := NormalizeSizeKey(Size)
    if SizeProfiles.Has(sizeKey)
        return SizeProfiles[sizeKey].btnGap
    return BtnGap
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

#Include StarHUD-active-config.ahk

if !IsSet(ToggleHotkey)
    ToggleHotkey := "F20"
if !IsSet(ButtonGapOverride)
    ButtonGapOverride := ""
if !IsSet(ShowButtonKeys)
    ShowButtonKeys := true
if !IsSet(ShowOuterBorder)
    ShowOuterBorder := true

ApplyCurrentSizeProfile()

ConfigLoaderPath := A_ScriptDir "\StarHUD-active-config.ahk"
ConfigFilePath := A_ScriptDir "\" ActiveConfigFileName
ManagedLayoutStartMarker := "; === MANAGED BUTTON LAYOUT BEGIN ==="
ManagedLayoutEndMarker := "; === MANAGED BUTTON LAYOUT END ==="
LastActiveHwnd := 0
PanelVisible := false
CurrentPageIndex := 1
PageGuis := []
RebuildingPageGuis := false
EditMode := false
EditSwapSelection := 0
EditDialogState := 0
ConfigDialogState := 0
CopiedButtonCfg := 0
RegisteredToggleHotkey := ""
RegisteredEditToggleHotkey := ""
GuiPictureBitmaps := Map()

ShutdownGdiplus(*) {
    global ConfigDialogState, EditDialogState, GdiplusToken, PageGuis

    if IsObject(ConfigDialogState)
        DestroyConfigEditor()
    if IsObject(EditDialogState)
        DestroyButtonEditor()

    for _, pageGui in PageGuis
    {
        ReleaseGuiPictureBitmaps(pageGui.Hwnd)
        try pageGui.Destroy()
    }
    PageGuis := []

    if !GdiplusToken
        return

    shutdownToken := GdiplusToken
    GdiplusToken := 0
    DllCall("gdiplus\GdiplusShutdown", "Ptr", shutdownToken)
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
        cfg.borderStyle,
        cfg.imagePath,
        cfg.frameColor,
        cfg.backgroundColor,
        cfg.titleLineMode,
        cfg.imageFitMode,
        cfg.showTextOnImage,
        cfg.showKeysOnImage
    )
}

RefreshCenterButtonTemplate() {
    global CenterButtonCfg, CenterLogoPath, FillColor

    CenterButtonCfg := ButtonCfg("", PageCycleAction(), "FFFFFF", "FFFFFF", "none", CenterLogoPath, "", FillColor)
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
    global BtnGap, ButtonGapOverride, Size, SizeProfiles

    Size := NormalizeSizeKey(Size)
    if !SizeProfiles.Has(Size)
        throw Error("Unknown Size profile: " Size ". Add it to SizeProfiles near the top of StarHUD-config.ahk.")
    ApplySizeProfile(SizeProfiles[Size])
    overrideGap := NormalizeButtonGapOverride(ButtonGapOverride, false)
    if overrideGap != ""
        BtnGap := overrideGap
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

GetButtonDisplayText(cfg, showTitle := true, showKeys := true) {
    global ShowButtonKeys

    titleText := showTitle ? FormatButtonTitle(cfg.text, cfg.titleLineMode) : ""
    shortcutLabel := GetActionShortcutLabel(cfg.action)
    if !ShowButtonKeys || !showKeys || shortcutLabel = ""
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
    if InStr(normalizedTitle, "`n")
        return normalizedTitle
    if titleLineMode = "double"
        return SplitTitleToTwoLines(normalizedTitle)
    return normalizedTitle
}

SplitTitleToTwoLines(titleText) {
    words := StrSplit(titleText, A_Space)
    if words.Length <= 1
    {
        if StrLen(titleText) <= 1
            return titleText
        splitIndex := Ceil(StrLen(titleText) / 2)
        return SubStr(titleText, 1, splitIndex) "`n" SubStr(titleText, splitIndex + 1)
    }

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
    if !HasVisualContent(cfg) && cfg.imagePath = "" && cfg.borderColor = "00FF88" && cfg.textColor = "00FF88" && cfg.borderStyle = "single" && cfg.frameColor = FrameColor && cfg.backgroundColor = FillColor && cfg.titleLineMode = "single" && cfg.imageFitMode = "cover" && !cfg.showTextOnImage && !cfg.showKeysOnImage
        return "ButtonCfg()"

    serializedButton := "ButtonCfg("
        . SerializeAhkString(cfg.text) ", "
        . SerializeAction(cfg.action) ", "
        . SerializeAhkString(cfg.borderColor) ", "
        . SerializeAhkString(cfg.textColor) ", "
        . SerializeBorderStyle(cfg.borderStyle) ", "
        . SerializeImagePath(cfg.imagePath) ", "
        . SerializeAhkString(cfg.frameColor) ", "
        . SerializeAhkString(cfg.backgroundColor) ", "
        . SerializeAhkString(cfg.titleLineMode)
    if cfg.imageFitMode != "cover" || cfg.showTextOnImage || cfg.showKeysOnImage
        serializedButton .= ", " SerializeAhkString(cfg.imageFitMode)
    if cfg.showTextOnImage || cfg.showKeysOnImage
        serializedButton .= ", " BoolToAhk(cfg.showTextOnImage) ", " BoolToAhk(cfg.showKeysOnImage)
    return serializedButton ")"
}

IsCenterButtonConfig(cfg) {
    global CenterLogoPath, FillColor

    return cfg.text = ""
        && cfg.imagePath = CenterLogoPath
        && IsPageCycleAction(cfg.action)
        && cfg.borderColor = "FFFFFF"
        && cfg.textColor = "FFFFFF"
        && cfg.borderStyle = "none"
        && cfg.backgroundColor = FillColor
        && cfg.imageFitMode = "cover"
        && !cfg.showTextOnImage
        && !cfg.showKeysOnImage
}

SerializeBorderStyle(borderStyle) {
    switch NormalizeBorderStyle(borderStyle)
    {
        case "single":
            return "false"
        case "double":
            return "true"
        case "none":
            return SerializeAhkString("none")
    }
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
    escapedValue := Format("{}", value)
    escapedValue := StrReplace(escapedValue, "`r`n", "`n")
    escapedValue := StrReplace(escapedValue, "`r", "`n")
    escapedValue := StrReplace(escapedValue, "`n", "``n")
    escapedValue := StrReplace(escapedValue, '"', '""')
    return '"' escapedValue '"'
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

GetConfigFilePath(fileName := "") {
    global ActiveConfigFileName

    if fileName = ""
    {
        activeFileName := IsSet(ActiveConfigFileName) && ActiveConfigFileName != "" ? ActiveConfigFileName : "StarHUD-config.ahk"
        return A_ScriptDir "\" activeFileName
    }
    return A_ScriptDir "\" fileName
}

GetConfigDisplayName(fileName) {
    return RegExReplace(Format("{}", fileName), "\.ahk$")
}

GetConfigDisplayNames(fileNames) {
    displayNames := []
    for _, fileName in fileNames
        displayNames.Push(GetConfigDisplayName(fileName))
    return displayNames
}

GetAvailableConfigFiles() {
    defaultFileName := ""
    otherFileNames := []

    Loop Files, A_ScriptDir "\StarHUD-config*.ahk"
    {
        if A_LoopFileName = "StarHUD-active-config.ahk"
            continue
        if A_LoopFileName = "StarHUD-config.ahk"
            defaultFileName := A_LoopFileName
        else
            otherFileNames.Push(A_LoopFileName)
    }

    configFileNames := []
    if defaultFileName != ""
        configFileNames.Push(defaultFileName)
    for _, fileName in otherFileNames
        configFileNames.Push(fileName)
    if configFileNames.Length = 0
        throw Error("No StarHUD config files were found in " A_ScriptDir ".")
    return configFileNames
}

ResolveConfigFileNameFromDisplay(displayName, fileNames) {
    targetDisplayName := Format("{}", displayName)
    for _, fileName in fileNames
    {
        if GetConfigDisplayName(fileName) = targetDisplayName
            return fileName
    }
    return ""
}

NormalizeConfigFileNameInput(rawValue) {
    nameText := Trim(Format("{}", rawValue))
    if nameText = ""
        throw Error("Config name cannot be blank.")

    normalizedText := RegExReplace(nameText, "i)\.ahk$")
    if RegExMatch(normalizedText, "i)^StarHUD-config(?:-([A-Za-z0-9_-]+))?$", &match)
    {
        suffix := match[1]
        return suffix = "" ? "StarHUD-config.ahk" : "StarHUD-config-" suffix ".ahk"
    }

    if !RegExMatch(normalizedText, "^[A-Za-z0-9_-]+$")
        throw Error("Config names may only use letters, numbers, dashes, and underscores.")
    return "StarHUD-config-" normalizedText ".ahk"
}

PromptForConfigFileName(actionLabel) {
    result := InputBox(
        actionLabel " config name:`n`nUse letters, numbers, dashes, or underscores. StarHUD will save it as StarHUD-config-<name>.ahk.",
        "StarHUD Config",
        "w420 h160"
    )
    if result.Result != "OK"
        return ""
    return NormalizeConfigFileNameInput(result.Value)
}

WriteActiveConfigLoader(fileName) {
    global ActiveConfigFileName, ConfigFilePath, ConfigLoaderPath

    loaderLines := [
        "; Auto-generated active StarHUD config selector."
        , "; Use the StarHUD config dialog to switch between config files."
        , "ActiveConfigFileName := " SerializeAhkString(fileName)
        , "#Include " fileName
    ]
    loaderFile := FileOpen(ConfigLoaderPath, "w", "UTF-8")
    if !IsObject(loaderFile)
        throw Error("Could not open config loader for writing: " ConfigLoaderPath)
    loaderFile.Write(ArrayJoin(loaderLines, "`r`n") "`r`n")
    loaderFile.Close()
    ActiveConfigFileName := fileName
    ConfigFilePath := GetConfigFilePath(fileName)
}

SaveConfigStateForSwitch() {
    ApplyConfigDialogValues()
    ApplyCurrentSizeProfile()
    WriteConfigStateToFile()
}

CreateClonedConfigFile(targetFileName) {
    sourcePath := GetConfigFilePath()
    targetPath := GetConfigFilePath(targetFileName)

    if FileExist(targetPath)
        throw Error("Config already exists: " targetFileName)
    FileCopy(sourcePath, targetPath, false)
    EnsureConfigFileCompatibility(targetPath)
}

CreateNewConfigFile(targetFileName) {
    global ButtonPages, CurrentPageIndex

    targetPath := GetConfigFilePath(targetFileName)
    if FileExist(targetPath)
        throw Error("Config already exists: " targetFileName)

    FileCopy(GetConfigFilePath(), targetPath, false)
    originalPages := ButtonPages
    originalPageIndex := CurrentPageIndex
    try
    {
        ButtonPages := [CreateEmptyPageLayout()]
        CurrentPageIndex := 1
        WriteConfigStateToFile(false, targetPath)
    }
    finally
    {
        ButtonPages := originalPages
        CurrentPageIndex := originalPageIndex
    }
}

GetAlternateConfigFileName(excludedFileName) {
    for _, fileName in GetAvailableConfigFiles()
    {
        if fileName != excludedFileName
            return fileName
    }
    throw Error("StarHUD must keep at least one config file.")
}

SwitchToConfigFile(targetFileName) {
    global ActiveConfigFileName

    if targetFileName = "" || targetFileName = ActiveConfigFileName
        return
    if !FileExist(GetConfigFilePath(targetFileName))
        throw Error("Config file not found: " targetFileName)
    WriteActiveConfigLoader(targetFileName)
    Reload()
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

UpsertConfigAssignment(configText, keyName, valueText, insertAfterKeyName := "") {
    pattern := "m)^" keyName "\s*:=.*$"
    replacedText := RegExReplace(configText, pattern, keyName " := " valueText, &replaceCount, 1)
    if replaceCount > 0
        return replacedText

    assignmentText := keyName " := " valueText
    if insertAfterKeyName != ""
    {
        anchorPattern := "m)^" insertAfterKeyName "\s*:=.*$"
        if RegExMatch(configText, anchorPattern, &anchorMatch)
        {
            insertPos := anchorMatch.Pos(0) + anchorMatch.Len(0) - 1
            return SubStr(configText, 1, insertPos) "`r`n" assignmentText SubStr(configText, insertPos + 1)
        }
    }

    return assignmentText "`r`n" configText
}

ReplaceOrInsertCommentBlock(configText, desiredLines, afterAnchorText := "", beforeAnchorText := "") {
    replacementText := ArrayJoin(desiredLines, "`r`n")
    afterPos := afterAnchorText = "" ? 0 : InStr(configText, afterAnchorText)
    beforePos := beforeAnchorText = "" ? 0 : InStr(configText, beforeAnchorText)

    if afterPos && beforePos && beforePos > afterPos
    {
        blockStart := afterPos + StrLen(afterAnchorText)
        return SubStr(configText, 1, blockStart) "`r`n" replacementText "`r`n" SubStr(configText, beforePos)
    }

    if afterPos
    {
        insertPos := afterPos + StrLen(afterAnchorText)
        return SubStr(configText, 1, insertPos) "`r`n" replacementText SubStr(configText, insertPos + 1)
    }

    if beforePos
        return SubStr(configText, 1, beforePos - 1) replacementText "`r`n" SubStr(configText, beforePos)

    if configText != "" && SubStr(configText, -1) != "`n"
        configText .= "`r`n"
    return configText replacementText
}

ApplyConfigCompatibilityMigrations(configText) {
    global ButtonGapOverride, ShowButtonKeys, ToggleHotkey

    settingCommentLines := [
        "; Set ShowButtonKeys to true to show the action keys under button titles, or false to hide them."
        , '; Set ToggleHotkey to a bare AHK key name like "F20", "F13", or "ScrollLock". RAlt+that key toggles edit mode.'
        , '; Leave ButtonGapOverride blank to use the selected size profile gap, or set it to a whole number to override the gap globally.'
        , "; Set ShowOuterBorder to true to keep the thin outer frame ring around buttons, or false to hide it."
        , "; Put per-button images in the images folder or its subfolders. The editor saves button-image references relative to images automatically."
    ]
    controlCommentLines := [
        "; Press ToggleHotkey to show or hide the HUD. Press RAlt+ToggleHotkey to toggle edit mode."
        , "; In edit mode, plain-click the center button to open the config dialog."
        , "; In edit mode, RAlt+click the center button to go to the next page."
        , "; In edit mode, plain-click a non-center button to edit its title, colors, border style, and action."
        , "; In edit mode, hold RAlt and click one non-center button, then another, to swap/move them."
        , "; Use the button editor Browse button to pick button images from the images folder, and Open Images in the config dialog to open that folder."
        , "; The button editor also supports Delete, Copy, and Paste so you can clear or duplicate buttons quickly."
        , "; Hiding the HUD always turns edit mode off."
    ]

    configText := RegExReplace(
        configText,
        'm)^CenterLogoFile\s*:=\s*"star-citizen-logo-bright\.png"\s*$',
        'CenterLogoFile := "images\StarHUD-center-logo-200x200.png"'
    )
    configText := RegExReplace(
        configText,
        'm)^CenterLogoFile\s*:=\s*"StarHUD-center-logo\.png"\s*$',
        'CenterLogoFile := "images\StarHUD-center-logo-100x100.png"'
    )
    configText := UpsertConfigAssignment(configText, "ShowButtonKeys", BoolToAhk(ShowButtonKeys), "StealMouseInput")
    configText := UpsertConfigAssignment(configText, "ToggleHotkey", SerializeAhkString(ToggleHotkey), "ShowButtonKeys")
    configText := UpsertConfigAssignment(configText, "ButtonGapOverride", SerializeButtonGapOverrideValue(ButtonGapOverride), "ToggleHotkey")
    configText := UpsertConfigAssignment(configText, "ShowOuterBorder", BoolToAhk(ShowOuterBorder), "ButtonGapOverride")
    configText := UpsertConfigAssignment(configText, "CenterLogoFile", SerializeAhkString("images\StarHUD-center-logo-200x200.png"), "ShowOuterBorder")
    configText := ReplaceOrInsertCommentBlock(
        configText,
        settingCommentLines,
        "; Set StealMouseInput to false to keep the previous non-activating overlay behavior.",
        "; Set CenterLogoFile above to change the center icon."
    )
    configText := ReplaceOrInsertCommentBlock(
        configText,
        controlCommentLines,
        "; Set the center button on each page to CenterButtonCfg to keep page cycling enabled.",
        "; The block between MANAGED BUTTON LAYOUT markers is rewritten by StarHUD edit mode."
    )

    return configText
}

EnsureConfigFileCompatibility(filePath := "") {
    if filePath = ""
        filePath := GetConfigFilePath()
    if !FileExist(filePath)
    {
        fallbackPath := GetConfigFilePath("StarHUD-config.ahk")
        if filePath != fallbackPath && FileExist(fallbackPath)
            filePath := fallbackPath
    }
    if !FileExist(filePath)
        return false

    originalText := FileRead(filePath, "UTF-8")
    migratedText := ApplyConfigCompatibilityMigrations(originalText)
    if migratedText = originalText
        return false

    file := FileOpen(filePath, "w", "UTF-8")
    if !IsObject(file)
        throw Error("Could not open config file for writing: " filePath)
    file.Write(migratedText)
    file.Close()
    return true
}

BackupConfigFile(filePath := "") {
    if filePath = ""
        filePath := GetConfigFilePath()
    FileCopy(filePath, filePath ".bak", true)
}

SerializeSizeConfigValue(sizeValue) {
    sizeText := NormalizeSizeKey(sizeValue)
    if RegExMatch(sizeText, "^\d+$")
        return sizeText
    return SerializeAhkString(sizeText)
}

WriteConfigStateToFile(createBackup := false, filePath := "") {
    global ButtonGapOverride, CornerRadius, FillColor, FrameColor, MaskColor, OpenPositionMode, ShowButtonKeys, ShowOuterBorder, Size, StealMouseInput, ToggleHotkey

    if filePath = ""
        filePath := GetConfigFilePath()
    configText := FileRead(filePath, "UTF-8")
    if createBackup
        BackupConfigFile(filePath)
    configText := ApplyConfigCompatibilityMigrations(configText)

    configText := ReplaceConfigAssignment(configText, "Size", SerializeSizeConfigValue(Size))
    configText := ReplaceConfigAssignment(configText, "CornerRadius", CornerRadius + 0)
    configText := ReplaceConfigAssignment(configText, "MaskColor", SerializeAhkString(StrUpper(MaskColor)))
    configText := ReplaceConfigAssignment(configText, "FrameColor", SerializeAhkString(StrUpper(FrameColor)))
    configText := ReplaceConfigAssignment(configText, "FillColor", SerializeAhkString(StrUpper(FillColor)))
    configText := ReplaceConfigAssignment(configText, "OpenPositionMode", SerializeAhkString(OpenPositionMode))
    configText := ReplaceConfigAssignment(configText, "StealMouseInput", BoolToAhk(StealMouseInput))
    configText := ReplaceConfigAssignment(configText, "ShowButtonKeys", BoolToAhk(ShowButtonKeys))
    configText := ReplaceConfigAssignment(configText, "ToggleHotkey", SerializeAhkString(ToggleHotkey))
    configText := ReplaceConfigAssignment(configText, "ButtonGapOverride", SerializeButtonGapOverrideValue(ButtonGapOverride))
    configText := ReplaceConfigAssignment(configText, "ShowOuterBorder", BoolToAhk(ShowOuterBorder))
    configText := ReplaceManagedLayoutBlock(configText)

    file := FileOpen(filePath, "w", "UTF-8")
    if !IsObject(file)
        throw Error("Could not open config file for writing: " filePath)
    file.Write(configText)
    file.Close()
}

CreateButtonCell(gui, textPlacements, pageIndex, rowIndex, colIndex, cfg, x, y, size := 108, createdControls := 0) {
    global BorderThickness, CornerRadius, FrameInset, InnerBorderInset, InnerBorderThickness, PrimaryBorderInset

    if IsSelectedCell(pageIndex, rowIndex, colIndex)
        CreateSolidLayer(gui, x - 4, y - 4, size + 8, size + 8, "FFFFFF", CornerRadius, createdControls)

    if !HasVisualContent(cfg)
        return

    resolvedImagePath := ResolveButtonImagePath(cfg.imagePath)
    if ShowOuterBorder
    {
        CreateSolidLayer(gui, x, y, size, size, cfg.frameColor, CornerRadius, createdControls)
        CreateSolidLayer(gui, x + FrameInset, y + FrameInset, size - FrameInset * 2, size - FrameInset * 2, cfg.backgroundColor, Max(0, CornerRadius - FrameInset), createdControls)
        contentInset := FrameInset
        contentRadius := Max(0, CornerRadius - FrameInset)
    }
    else
    {
        CreateSolidLayer(gui, x, y, size, size, cfg.backgroundColor, CornerRadius, createdControls)
        contentInset := 0
        contentRadius := CornerRadius
    }

    switch cfg.borderStyle
    {
        case "double":
            CreateSolidLayer(gui, x + PrimaryBorderInset, y + PrimaryBorderInset, size - PrimaryBorderInset * 2, size - PrimaryBorderInset * 2, cfg.borderColor, Max(0, CornerRadius - PrimaryBorderInset), createdControls)
            innerInset := PrimaryBorderInset + BorderThickness
            CreateSolidLayer(gui, x + innerInset, y + innerInset, size - innerInset * 2, size - innerInset * 2, cfg.backgroundColor, Max(0, CornerRadius - innerInset), createdControls)
            CreateSolidLayer(gui, x + InnerBorderInset, y + InnerBorderInset, size - InnerBorderInset * 2, size - InnerBorderInset * 2, cfg.borderColor, Max(0, CornerRadius - InnerBorderInset), createdControls)
            innerFillInset := InnerBorderInset + InnerBorderThickness
            CreateSolidLayer(gui, x + innerFillInset, y + innerFillInset, size - innerFillInset * 2, size - innerFillInset * 2, cfg.backgroundColor, Max(0, CornerRadius - innerFillInset), createdControls)
            contentInset := innerFillInset
            contentRadius := Max(0, CornerRadius - innerFillInset)

        case "single":
            CreateSolidLayer(gui, x + PrimaryBorderInset, y + PrimaryBorderInset, size - PrimaryBorderInset * 2, size - PrimaryBorderInset * 2, cfg.borderColor, Max(0, CornerRadius - PrimaryBorderInset), createdControls)
            innerInset := PrimaryBorderInset + BorderThickness
            CreateSolidLayer(gui, x + innerInset, y + innerInset, size - innerInset * 2, size - innerInset * 2, cfg.backgroundColor, Max(0, CornerRadius - innerInset), createdControls)
            contentInset := innerInset
            contentRadius := Max(0, CornerRadius - innerInset)

        case "none":
            ; No inner border lines; the frame shell still renders around the content area.
    }

    contentX := x + contentInset
    contentY := y + contentInset
    contentSize := size - contentInset * 2

    if resolvedImagePath != ""
    {
        imageCtrl := gui.Add("Picture", "x" contentX " y" contentY " w" contentSize " h" contentSize " +0xE", "")
        if IsObject(createdControls)
            createdControls.Push(imageCtrl)
        ApplyRoundedRegion(imageCtrl.Hwnd, contentSize, contentSize, contentRadius)
        hBitmap := CreateFittedImageBitmap(resolvedImagePath, cfg.imageFitMode, contentSize, contentSize, cfg.backgroundColor)
        if hBitmap
            SetManagedPictureBitmap(gui.Hwnd, imageCtrl, hBitmap)
        else
            SetManagedPictureFromFile(gui.Hwnd, imageCtrl, resolvedImagePath, contentSize, contentSize)
    }

    buttonText := resolvedImagePath != ""
        ? GetButtonDisplayText(cfg, cfg.showTextOnImage, cfg.showKeysOnImage)
        : GetButtonDisplayText(cfg)
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
            if IsObject(createdControls)
                createdControls.Push(txt)
            controls.Push(txt)
        }

        textPlacements.Push({x: x, y: y, size: size, lineGap: lineGap, controls: controls})
    }
}

CreateSolidLayer(gui, x, y, w, h, color, radius := 0, createdControls := 0) {
    if w <= 0 || h <= 0
        return

    ctrl := gui.Add("Picture", "x" x " y" y " w" w " h" h " +0xE", "")
    if IsObject(createdControls)
        createdControls.Push(ctrl)
    hBitmap := CreateSolidBitmap(w, h, color, radius)
    if hBitmap
        SetManagedPictureBitmap(gui.Hwnd, ctrl, hBitmap)
    if radius > 0
        ApplyRoundedRegion(ctrl.Hwnd, w, h, radius)
    return ctrl
}

CreateSolidBitmap(targetW, targetH, color, radius := 0) {
    if targetW <= 0 || targetH <= 0
        return 0

    pCanvasBitmap := 0
    pGraphics := 0
    brush := 0
    hBitmap := 0

    try
    {
        if DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", targetW, "Int", targetH, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", &pCanvasBitmap := 0)
            return 0
        if DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pCanvasBitmap, "Ptr*", &pGraphics := 0)
            return 0
        DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)
        DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "UInt", 0x00000000)
        if DllCall("gdiplus\GdipCreateSolidFill", "UInt", ("0xFF" NormalizeColorInput(color, "000000")) + 0, "Ptr*", &brush := 0)
            return 0

        radius := Max(0, Min(radius, Floor(Min(targetW, targetH) / 2)))
        if radius <= 0
        {
            DllCall("gdiplus\GdipFillRectangleI", "Ptr", pGraphics, "Ptr", brush, "Int", 0, "Int", 0, "Int", targetW, "Int", targetH)
        }
        else
        {
            diameter := radius * 2
            innerW := Max(0, targetW - diameter)
            innerH := Max(0, targetH - diameter)

            if innerW > 0
                DllCall("gdiplus\GdipFillRectangleI", "Ptr", pGraphics, "Ptr", brush, "Int", radius, "Int", 0, "Int", innerW, "Int", targetH)
            if innerH > 0
                DllCall("gdiplus\GdipFillRectangleI", "Ptr", pGraphics, "Ptr", brush, "Int", 0, "Int", radius, "Int", targetW, "Int", innerH)

            DllCall("gdiplus\GdipFillEllipseI", "Ptr", pGraphics, "Ptr", brush, "Int", 0, "Int", 0, "Int", diameter, "Int", diameter)
            DllCall("gdiplus\GdipFillEllipseI", "Ptr", pGraphics, "Ptr", brush, "Int", targetW - diameter, "Int", 0, "Int", diameter, "Int", diameter)
            DllCall("gdiplus\GdipFillEllipseI", "Ptr", pGraphics, "Ptr", brush, "Int", 0, "Int", targetH - diameter, "Int", diameter, "Int", diameter)
            DllCall("gdiplus\GdipFillEllipseI", "Ptr", pGraphics, "Ptr", brush, "Int", targetW - diameter, "Int", targetH - diameter, "Int", diameter, "Int", diameter)
        }

        if DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pCanvasBitmap, "Ptr*", &hBitmap := 0, "UInt", 0x00000000)
            hBitmap := 0
    }
    finally
    {
        if brush
            DllCall("gdiplus\GdipDeleteBrush", "Ptr", brush)
        if pGraphics
            DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
        if pCanvasBitmap
            DllCall("gdiplus\GdipDisposeImage", "Ptr", pCanvasBitmap)
    }

    return hBitmap
}

CreateFittedImageBitmap(imagePath, fitMode, targetW, targetH, backgroundColor := "000000") {
    fitMode := NormalizeImageFitMode(fitMode)
    if imagePath = "" || !FileExist(imagePath) || targetW <= 0 || targetH <= 0
        return 0

    sourceBitmapHandle := 0
    pSourceImage := 0
    pCanvasBitmap := 0
    pGraphics := 0
    hBitmap := 0

    try
    {
        sourceBitmapHandle := LoadPicture(imagePath, "", &imageType)
        if !sourceBitmapHandle
            return 0
        if DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", sourceBitmapHandle, "Ptr", 0, "Ptr*", &pSourceImage := 0)
            return 0
        DllCall("gdiplus\GdipGetImageWidth", "Ptr", pSourceImage, "UInt*", &sourceW := 0)
        DllCall("gdiplus\GdipGetImageHeight", "Ptr", pSourceImage, "UInt*", &sourceH := 0)
        if sourceW <= 0 || sourceH <= 0
            return 0

        if DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", targetW, "Int", targetH, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", &pCanvasBitmap := 0)
            return 0
        if DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pCanvasBitmap, "Ptr*", &pGraphics := 0)
            return 0

        DllCall("gdiplus\GdipSetInterpolationMode", "Ptr", pGraphics, "Int", 7)
        DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pGraphics, "Int", 2)
        DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "UInt", ("0xFF" NormalizeColorInput(backgroundColor, "000000")) + 0)

        switch fitMode
        {
            case "stretch":
                destX := 0, destY := 0, destW := targetW, destH := targetH
                srcX := 0, srcY := 0, srcW := sourceW, srcH := sourceH

            case "contain":
                scale := Min(targetW / sourceW, targetH / sourceH)
                destW := Max(1, Round(sourceW * scale))
                destH := Max(1, Round(sourceH * scale))
                destX := Floor((targetW - destW) / 2)
                destY := Floor((targetH - destH) / 2)
                srcX := 0, srcY := 0, srcW := sourceW, srcH := sourceH

            case "center":
                destW := sourceW
                destH := sourceH
                destX := Floor((targetW - destW) / 2)
                destY := Floor((targetH - destH) / 2)
                srcX := 0, srcY := 0, srcW := sourceW, srcH := sourceH

            default:
                scale := Max(targetW / sourceW, targetH / sourceH)
                srcW := Max(1, Round(targetW / scale))
                srcH := Max(1, Round(targetH / scale))
                srcX := Max(0, Floor((sourceW - srcW) / 2))
                srcY := Max(0, Floor((sourceH - srcH) / 2))
                destX := 0, destY := 0, destW := targetW, destH := targetH
        }

        DllCall(
            "gdiplus\GdipDrawImageRectRectI",
            "Ptr", pGraphics,
            "Ptr", pSourceImage,
            "Int", destX,
            "Int", destY,
            "Int", destW,
            "Int", destH,
            "Int", srcX,
            "Int", srcY,
            "Int", srcW,
            "Int", srcH,
            "Int", 2,
            "Ptr", 0,
            "Ptr", 0,
            "Ptr", 0
        )
        if DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pCanvasBitmap, "Ptr*", &hBitmap := 0, "UInt", 0x00000000)
            hBitmap := 0
    }
    finally
    {
        if pGraphics
            DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
        if pCanvasBitmap
            DllCall("gdiplus\GdipDisposeImage", "Ptr", pCanvasBitmap)
        if pSourceImage
            DllCall("gdiplus\GdipDisposeImage", "Ptr", pSourceImage)
        if sourceBitmapHandle
            DllCall("DeleteObject", "Ptr", sourceBitmapHandle)
    }

    return hBitmap
}

SetManagedPictureBitmap(guiHwnd, pictureCtrl, hBitmap) {
    global GuiPictureBitmaps

    guiKey := Format("{}", guiHwnd)
    ctrlKey := Format("{}", pictureCtrl.Hwnd)
    if !GuiPictureBitmaps.Has(guiKey)
        GuiPictureBitmaps[guiKey] := Map()

    guiBitmaps := GuiPictureBitmaps[guiKey]
    if guiBitmaps.Has(ctrlKey)
    {
        oldBitmap := guiBitmaps[ctrlKey]
        if oldBitmap && oldBitmap != hBitmap
            DllCall("DeleteObject", "Ptr", oldBitmap)
    }

    guiBitmaps[ctrlKey] := hBitmap
    DllCall("SendMessage", "Ptr", pictureCtrl.Hwnd, "UInt", 0x0172, "Ptr", 0, "Ptr", hBitmap, "Ptr")
}

SetManagedPictureFromFile(guiHwnd, pictureCtrl, imagePath, targetW := 0, targetH := 0) {
    loadOptions := ""
    if targetW > 0
        loadOptions .= "w" targetW
    if targetH > 0
        loadOptions .= (loadOptions = "" ? "" : " ") "h" targetH
    hBitmap := LoadPicture(imagePath, loadOptions, &imageType)
    if !hBitmap
        return false
    SetManagedPictureBitmap(guiHwnd, pictureCtrl, hBitmap)
    return true
}

ReleaseManagedControlBitmap(guiHwnd, ctrlHwnd) {
    global GuiPictureBitmaps

    guiKey := Format("{}", guiHwnd)
    ctrlKey := Format("{}", ctrlHwnd)
    if !GuiPictureBitmaps.Has(guiKey)
        return

    guiBitmaps := GuiPictureBitmaps[guiKey]
    if !guiBitmaps.Has(ctrlKey)
        return

    hBitmap := guiBitmaps[ctrlKey]
    if hBitmap
        DllCall("DeleteObject", "Ptr", hBitmap)
    guiBitmaps.Delete(ctrlKey)
}

ReleaseGuiPictureBitmaps(guiHwnd) {
    global GuiPictureBitmaps

    guiKey := Format("{}", guiHwnd)
    if !GuiPictureBitmaps.Has(guiKey)
        return

    for _, hBitmap in GuiPictureBitmaps[guiKey]
    {
        if hBitmap
            DllCall("DeleteObject", "Ptr", hBitmap)
    }
    GuiPictureBitmaps.Delete(guiKey)
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
    global ButtonPages, CurrentPageIndex, EditMode, PageGuis, PanelVisible, RebuildingPageGuis

    if !PanelVisible || RebuildingPageGuis || CurrentPageIndex > PageGuis.Length
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
            CyclePage()
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

RebuildPageGuis(preserveVisible := true, activateWindow := true) {
    global ButtonPages, CurrentPageIndex, PageGuis, PanelVisible, RebuildingPageGuis

    RebuildingPageGuis := true
    shouldRestoreVisible := preserveVisible && PanelVisible && PageGuis.Length >= CurrentPageIndex
    if shouldRestoreVisible
        PageGuis[CurrentPageIndex].GetPos(&panelX, &panelY)

    try
    {
        for _, pageGui in PageGuis
        {
            ReleaseGuiPictureBitmaps(pageGui.Hwnd)
            try pageGui.Destroy()
        }

        PageGuis := []
        for _, layout in ButtonPages
            PageGuis.Push(CreatePageGui(layout))

        if shouldRestoreVisible
            ShowCurrentPage(panelX, panelY, activateWindow)
        else
            PanelVisible := false
    }
    finally
    {
        RebuildingPageGuis := false
    }
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
        HandleEditModeMoveClick(pageIndex, rowIndex, colIndex)
        return
    }

    if IsObject(EditSwapSelection)
    {
        if EditSwapSelection.pageIndex = pageIndex && EditSwapSelection.row = rowIndex && EditSwapSelection.col = colIndex
        {
            EditSwapSelection := 0
            RebuildPageGuis(PanelVisible, false)
            if IsObject(ConfigDialogState)
                WinActivate("ahk_id " ConfigDialogState.gui.Hwnd)
        }
        else
        {
            EditSwapSelection := 0
            RebuildPageGuis(PanelVisible)
        }
    }

    ToggleButtonEditor(pageIndex, rowIndex, colIndex)
}

HandleEditModeMoveClick(pageIndex, rowIndex, colIndex) {
    global EditSwapSelection, PanelVisible

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
    global ButtonPages, CenterLogoPath, CopiedButtonCfg, EditDialogState, PageGuis, CurrentPageIndex

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

    borderStyleOptions := ["single", "double", "none"]
    imageFitOptions := ["cover", "contain", "stretch", "center"]
    editorGui.Add("Text", "xm y+8", "Border style")
    borderStyleList := editorGui.Add("DropDownList", "xm w160", borderStyleOptions)
    ChooseDropDownValue(borderStyleList, cfg.borderStyle, borderStyleOptions)

    editorGui.Add("Text", "xm y+8", "Image")
    imagePathEdit := editorGui.Add("Edit", "xm w260 ReadOnly", GetImageEditorValue(cfg.imagePath))
    browseImageButton := editorGui.Add("Button", "xm y+6 w80", "Browse")
    clearImageButton := editorGui.Add("Button", "x+8 w80", "Clear")
    editorGui.Add("Text", "xm y+8", "Image fit")
    imageFitList := editorGui.Add("DropDownList", "xm w160", imageFitOptions)
    ChooseDropDownValue(imageFitList, cfg.imageFitMode, imageFitOptions)
    showTextOnImageCheck := editorGui.Add("CheckBox", "xm y+8", "Show text over image")
    showTextOnImageCheck.Value := cfg.showTextOnImage ? 1 : 0
    showKeysOnImageCheck := editorGui.Add("CheckBox", "xm y+4", "Show keys over image")
    showKeysOnImageCheck.Value := cfg.showKeysOnImage ? 1 : 0
    editorGui.Add("Text", "xm y+8 c808080", "The HUD itself is the live preview. Save keeps changes; Cancel reverts them.")

    actionTypeOptions := ["None", "SendKey", "ChordKey", "HoldKey", "DoubleTapKey", "PageCycle"]
    editorGui.Add("Text", "xm y+8", "Action type")
    actionTypeList := editorGui.Add("DropDownList", "xm w180", actionTypeOptions)
    ChooseDropDownValue(actionTypeList, actionType, actionTypeOptions)

    key1Label := editorGui.Add("Text", "xm y+8", "Key")
    key1Edit := editorGui.Add("Edit", "xm w120", GetActionEditorPrimaryValue(cfg.action))
    key2Label := editorGui.Add("Text", "x+12 yp", "Modifier")
    key2Edit := editorGui.Add("Edit", "x+0 w120", GetActionEditorSecondaryValue(cfg.action))
    chordHintText := editorGui.Add("Text", "xm y+2 c808080", "Chord modifiers use AHK names like LAlt or RAlt.")

    durationLabel := editorGui.Add("Text", "xm y+8", "Duration ms")
    durationEdit := editorGui.Add("Edit", "xm w120", GetActionEditorDurationValue(cfg.action))
    delayLabel := editorGui.Add("Text", "x+12 yp", "Delay ms")
    delayEdit := editorGui.Add("Edit", "x+0 w120", GetActionEditorDelayValue(cfg.action))

    deleteButton := editorGui.Add("Button", "xm y+12 w76", "Delete")
    copyButton := editorGui.Add("Button", "x+8 w76", "Copy")
    pasteButton := editorGui.Add("Button", "x+8 w76", "Paste")
    saveButton := editorGui.Add("Button", "xm y+10 w120 Default", "Save")
    cancelButton := editorGui.Add("Button", "x+12 w120", "Cancel")

    EditDialogState := {
        gui: editorGui,
        sourceCfg: CloneButtonCfg(cfg),
        pageIndex: pageIndex,
        row: rowIndex,
        col: colIndex,
        nameEdit: nameEdit,
        textColorEdit: textColorEdit,
        borderColorEdit: borderColorEdit,
        borderStyleList: borderStyleList,
        imagePathEdit: imagePathEdit,
        browseImageButton: browseImageButton,
        clearImageButton: clearImageButton,
        imageFitList: imageFitList,
        showTextOnImageCheck: showTextOnImageCheck,
        showKeysOnImageCheck: showKeysOnImageCheck,
        actionTypeList: actionTypeList,
        key1Label: key1Label,
        key1Edit: key1Edit,
        key2Label: key2Label,
        key2Edit: key2Edit,
        chordHintText: chordHintText,
        durationLabel: durationLabel,
        durationEdit: durationEdit,
        delayLabel: delayLabel,
        delayEdit: delayEdit,
        deleteButton: deleteButton,
        copyButton: copyButton,
        pasteButton: pasteButton
    }

    nameEdit.OnEvent("Change", UpdateButtonEditorPreview)
    textColorEdit.OnEvent("Change", UpdateButtonEditorPreview)
    borderColorEdit.OnEvent("Change", UpdateButtonEditorPreview)
    borderStyleList.OnEvent("Change", UpdateButtonEditorPreview)
    actionTypeList.OnEvent("Change", UpdateButtonEditorFields)
    key1Edit.OnEvent("Change", UpdateButtonEditorPreview)
    key2Edit.OnEvent("Change", UpdateButtonEditorPreview)
    durationEdit.OnEvent("Change", UpdateButtonEditorPreview)
    delayEdit.OnEvent("Change", UpdateButtonEditorPreview)
    textColorPickButton.OnEvent("Click", PickButtonEditorColor.Bind("text"))
    borderColorPickButton.OnEvent("Click", PickButtonEditorColor.Bind("border"))
    browseImageButton.OnEvent("Click", BrowseButtonImage)
    clearImageButton.OnEvent("Click", ClearButtonImage)
    imageFitList.OnEvent("Change", UpdateButtonEditorPreview)
    showTextOnImageCheck.OnEvent("Click", UpdateButtonEditorPreview)
    showKeysOnImageCheck.OnEvent("Click", UpdateButtonEditorPreview)
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
    UpdateButtonEditorPreview()
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

ParseButtonTitleFromEditor(titleText) {
    convertedTitle := Format("{}", titleText)
    convertedTitle := StrReplace(convertedTitle, "`r`n", "`n")
    convertedTitle := StrReplace(convertedTitle, "``n", "`n")
    return {
        text: convertedTitle,
        lineMode: InferTitleLineMode(convertedTitle)
    }
}

UpdateButtonEditorFields(*) {
    global EditDialogState

    if !IsObject(EditDialogState)
        return

    actionType := EditDialogState.actionTypeList.Text
    SetEditorFieldVisible(EditDialogState.key1Label, EditDialogState.key1Edit, false)
    SetEditorFieldVisible(EditDialogState.key2Label, EditDialogState.key2Edit, false)
    EditDialogState.chordHintText.Opt("+Hidden")
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
            EditDialogState.chordHintText.Opt("-Hidden")
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
    UpdateButtonEditorPreview()
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

TryCreatePreviewAction(actionType, key1Value, key2Value, durationValue, delayValue) {
    try
    {
        return CreateActionFromEditor(actionType, key1Value, key2Value, durationValue, delayValue)
    }
    return 0
}

BuildButtonCfgFromEditor() {
    global EditDialogState

    sourceCfg := EditDialogState.sourceCfg
    titleInfo := ParseButtonTitleFromEditor(EditDialogState.nameEdit.Value)
    return ButtonCfg(
        titleInfo.text,
        TryCreatePreviewAction(
            EditDialogState.actionTypeList.Text,
            EditDialogState.key1Edit.Value,
            EditDialogState.key2Edit.Value,
            EditDialogState.durationEdit.Value,
            EditDialogState.delayEdit.Value
        ),
        NormalizeColorInput(EditDialogState.borderColorEdit.Value, sourceCfg.borderColor),
        NormalizeColorInput(EditDialogState.textColorEdit.Value, sourceCfg.textColor),
        EditDialogState.borderStyleList.Text,
        EditDialogState.imagePathEdit.Value,
        sourceCfg.frameColor,
        sourceCfg.backgroundColor,
        titleInfo.lineMode,
        EditDialogState.imageFitList.Text,
        EditDialogState.showTextOnImageCheck.Value = 1,
        EditDialogState.showKeysOnImageCheck.Value = 1
    )
}

UpdateImageOverlayEditorControls(hasImage) {
    global EditDialogState

    if !IsObject(EditDialogState)
        return

    EditDialogState.showTextOnImageCheck.Opt(hasImage ? "-Hidden" : "+Hidden")
    EditDialogState.showKeysOnImageCheck.Opt(hasImage ? "-Hidden" : "+Hidden")
    SetEditorControlEnabled(EditDialogState.imageFitList, hasImage)
    SetEditorControlEnabled(EditDialogState.showTextOnImageCheck, hasImage)
    SetEditorControlEnabled(EditDialogState.showKeysOnImageCheck, hasImage)
}

ApplyButtonEditorPreview() {
    global ButtonPages, EditDialogState, PanelVisible

    if !IsObject(EditDialogState)
        return

    ButtonPages[EditDialogState.pageIndex][EditDialogState.row][EditDialogState.col] := BuildButtonCfgFromEditor()
    RebuildPageGuis(PanelVisible)
}

RestoreButtonEditorSourceCfg() {
    global ButtonPages, EditDialogState, PanelVisible

    if !IsObject(EditDialogState)
        return

    ButtonPages[EditDialogState.pageIndex][EditDialogState.row][EditDialogState.col] := CloneButtonCfg(EditDialogState.sourceCfg)
    RebuildPageGuis(PanelVisible)
}

BrowseButtonImage(*) {
    global EditDialogState

    if !IsObject(EditDialogState)
        return

    imagesFolder := EnsureImagesFolderExists()
    selectedFile := FileSelect(3, imagesFolder "\", "Select button image", "Image Files (*.png; *.jpg; *.jpeg; *.bmp; *.gif; *.ico)")
    if selectedFile = ""
        return

    try
    {
        EditDialogState.imagePathEdit.Value := NormalizeSelectedImagePath(selectedFile)
        UpdateButtonEditorPreview()
    }
    catch as err
    {
        MsgBox(err.Message, "StarHUD Edit Error")
    }
}

ClearButtonImage(*) {
    global EditDialogState

    if !IsObject(EditDialogState)
        return

    EditDialogState.imagePathEdit.Value := ""
    UpdateButtonEditorPreview()
}

UpdateButtonEditorPreview(*) {
    global EditDialogState

    if !IsObject(EditDialogState)
        return

    hasImage := Trim(EditDialogState.imagePathEdit.Value) != ""
    SetEditorControlEnabled(EditDialogState.clearImageButton, hasImage)
    UpdateImageOverlayEditorControls(hasImage)
    ApplyButtonEditorPreview()
}

SaveButtonEditor(*) {
    global ButtonPages, EditDialogState

    if !IsObject(EditDialogState)
        return

    try
    {
        ButtonPages[EditDialogState.pageIndex][EditDialogState.row][EditDialogState.col] := BuildButtonCfgFromEditor()
        DestroyButtonEditor()
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
    DestroyButtonEditor()
    PersistButtonPages()
}

CopyButtonFromEditor(*) {
    global ButtonPages, CopiedButtonCfg, EditDialogState

    if !IsObject(EditDialogState)
        return

    CopiedButtonCfg := CloneButtonCfg(ButtonPages[EditDialogState.pageIndex][EditDialogState.row][EditDialogState.col])
    DestroyButtonEditor()
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
    DestroyButtonEditor()
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
    numValue := textValue + 0
    return numValue
}

NormalizeColorInput(colorValue, fallbackValue := "") {
    normalizedColor := Trim(StrReplace(Format("{}", colorValue), "#"))
    if normalizedColor = ""
        return fallbackValue
    if !RegExMatch(normalizedColor, "i)^[0-9a-f]{6}$")
        throw Error("Colors must be 6 hexadecimal characters, for example 00FF88.")
    return StrUpper(normalizedColor)
}

DestroyButtonEditor() {
    global EditDialogState

    if IsObject(EditDialogState)
    {
        ReleaseGuiPictureBitmaps(EditDialogState.gui.Hwnd)
        try EditDialogState.gui.Destroy()
        EditDialogState := 0
    }
}

CloseButtonEditor(*) {
    RestoreButtonEditorSourceCfg()
    DestroyButtonEditor()
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
    {
        ctrl.Value := chosenColor
        UpdateButtonEditorPreview()
    }
}

GetSizeProfileOptions() {
    global SizeProfiles

    options := []
    for sizeKey, _ in SizeProfiles
        options.Push(sizeKey)
    return options
}

GetBuiltInSizeSliderValue(sizeKey := "") {
    global SizeProfiles, Size

    if sizeKey = ""
        sizeKey := NormalizeSizeKey(Size)
    if RegExMatch(sizeKey, "^\d+$")
    {
        numericValue := sizeKey + 0
        if numericValue >= 1 && numericValue <= 5
            return numericValue
    }

    if !SizeProfiles.Has(sizeKey)
        return 3

    targetHeight := SizeProfiles[sizeKey].targetHeight
    bestValue := 3
    bestDistance := ""
    Loop 5
    {
        candidateValue := A_Index
        candidateKey := Format("{}", candidateValue)
        if !SizeProfiles.Has(candidateKey)
            continue
        distance := Abs(SizeProfiles[candidateKey].targetHeight - targetHeight)
        if bestDistance = "" || distance < bestDistance
        {
            bestDistance := distance
            bestValue := candidateValue
        }
    }
    return bestValue
}

NormalizeSliderRangeValue(value, minValue, maxValue, fallbackValue) {
    textValue := Trim(Format("{}", value))
    if !RegExMatch(textValue, "^\d+$")
        return fallbackValue
    numericValue := textValue + 0
    return Max(minValue, Min(maxValue, numericValue))
}

SyncConfigDialogSliderDisplays() {
    global ConfigDialogState, SizeProfiles

    if !IsObject(ConfigDialogState)
        return

    sizeValue := NormalizeSliderRangeValue(ConfigDialogState.sizeSlider.Value, 1, 5, 3)
    sizeKey := Format("{}", sizeValue)
    ConfigDialogState.sizeValueEdit.Value := sizeKey
    if SizeProfiles.Has(sizeKey)
        ConfigDialogState.sizeHelperText.Text := "[default " SizeProfiles[sizeKey].targetHeight "]"
    else
        ConfigDialogState.sizeHelperText.Text := "[default]"

    defaultGap := SizeProfiles.Has(sizeKey) ? SizeProfiles[sizeKey].btnGap : 0
    if ConfigDialogState.buttonGapDefaultCheck.Value = 1
        ConfigDialogState.buttonGapSlider.Value := defaultGap
    gapValue := NormalizeSliderRangeValue(ConfigDialogState.buttonGapSlider.Value, 0, 200, defaultGap)
    ConfigDialogState.buttonGapValueEdit.Value := gapValue
    ConfigDialogState.buttonGapHelperText.Text := "[default " defaultGap "]"
    SetEditorControlEnabled(ConfigDialogState.buttonGapSlider, ConfigDialogState.buttonGapDefaultCheck.Value != 1)

    cornerDefault := 0
    if ConfigDialogState.cornerRadiusDefaultCheck.Value = 1
        ConfigDialogState.cornerRadiusSlider.Value := cornerDefault
    cornerValue := NormalizeSliderRangeValue(ConfigDialogState.cornerRadiusSlider.Value, 0, 200, cornerDefault)
    ConfigDialogState.cornerRadiusValueEdit.Value := cornerValue
    ConfigDialogState.cornerRadiusHelperText.Text := "[default " cornerDefault "]"
    SetEditorControlEnabled(ConfigDialogState.cornerRadiusSlider, ConfigDialogState.cornerRadiusDefaultCheck.Value != 1)
}

OpenImagesFolder(*) {
    Run('explorer.exe "' EnsureImagesFolderExists() '"')
}

CaptureConfigDialogPreviewState() {
    global ButtonGapOverride, CornerRadius, FillColor, FrameColor, MaskColor, OpenPositionMode, ShowButtonKeys, ShowOuterBorder, Size, StealMouseInput, ToggleHotkey

    return {
        size: Size,
        cornerRadius: CornerRadius,
        maskColor: MaskColor,
        frameColor: FrameColor,
        fillColor: FillColor,
        openPositionMode: OpenPositionMode,
        toggleHotkey: ToggleHotkey,
        buttonGapOverride: ButtonGapOverride,
        buttonGapUsesDefault: ButtonGapOverride = "",
        cornerRadiusUsesDefault: CornerRadius = 0,
        stealMouseInput: StealMouseInput,
        showButtonKeys: ShowButtonKeys,
        showOuterBorder: ShowOuterBorder
    }
}

ApplyConfigDialogPreviewState(state, activateWindow := true) {
    global ButtonGapOverride, CornerRadius, FillColor, FrameColor, MaskColor, OpenPositionMode, PanelVisible, ShowButtonKeys, ShowOuterBorder, Size, StealMouseInput, ToggleHotkey

    oldFrameColor := FrameColor
    oldFillColor := FillColor
    oldToggleHotkey := ToggleHotkey
    newCornerRadius := state.cornerRadius

    Size := NormalizeSizeKey(state.size)
    MaskColor := state.maskColor
    FrameColor := state.frameColor
    FillColor := state.fillColor
    OpenPositionMode := state.openPositionMode
    ToggleHotkey := state.toggleHotkey
    ButtonGapOverride := state.buttonGapOverride
    StealMouseInput := state.stealMouseInput
    ShowButtonKeys := state.showButtonKeys
    ShowOuterBorder := state.showOuterBorder

    ApplyCurrentSizeProfile()
    CornerRadius := newCornerRadius
    if oldToggleHotkey != ToggleHotkey
        RegisterToggleHotkeys(ToggleHotkey)
    RefreshCenterButtonTemplate()
    UpdateButtonsForDefaultColorChange(oldFrameColor, oldFillColor)
    RebuildPageGuis(PanelVisible, activateWindow)
}

BuildConfigDialogPreviewState(strict := true) {
    global ButtonGapOverride, ConfigDialogState, CornerRadius, FillColor, FrameColor, MaskColor, OpenPositionMode, ShowButtonKeys, ShowOuterBorder, Size, SizeProfiles, StealMouseInput, ToggleHotkey

    if !IsObject(ConfigDialogState)
        return 0

    newSize := NormalizeSizeKey(ConfigDialogState.sizeValueEdit.Value)
    if !SizeProfiles.Has(newSize)
    {
        if strict
            throw Error("Unknown Size profile: " newSize)
        return 0
    }

    try newToggleHotkey := NormalizeToggleHotkeyInput(ConfigDialogState.toggleHotkeyEdit.Value)
    catch as err
    {
        if strict
            throw err
        return 0
    }

    defaultGap := SizeProfiles.Has(newSize) ? SizeProfiles[newSize].btnGap : 0
    gapValue := NormalizeSliderRangeValue(ConfigDialogState.buttonGapSlider.Value, 0, 200, defaultGap)
    newButtonGapOverride := ConfigDialogState.buttonGapDefaultCheck.Value = 1 ? "" : gapValue

    newCornerRadius := ConfigDialogState.cornerRadiusDefaultCheck.Value = 1
        ? 0
        : NormalizeSliderRangeValue(ConfigDialogState.cornerRadiusSlider.Value, 0, 200, 0)

    try newMaskColor := NormalizeColorInput(ConfigDialogState.maskColorEdit.Value, MaskColor)
    catch as err
    {
        if strict
            throw err
        return 0
    }

    try newFrameColor := NormalizeColorInput(ConfigDialogState.frameColorEdit.Value, FrameColor)
    catch as err
    {
        if strict
            throw err
        return 0
    }

    try newFillColor := NormalizeColorInput(ConfigDialogState.fillColorEdit.Value, FillColor)
    catch as err
    {
        if strict
            throw err
        return 0
    }

    return {
        size: newSize,
        cornerRadius: newCornerRadius,
        maskColor: newMaskColor,
        frameColor: newFrameColor,
        fillColor: newFillColor,
        openPositionMode: ConfigDialogState.openPositionList.Text,
        toggleHotkey: newToggleHotkey,
        buttonGapOverride: newButtonGapOverride,
        buttonGapUsesDefault: ConfigDialogState.buttonGapDefaultCheck.Value = 1,
        cornerRadiusUsesDefault: ConfigDialogState.cornerRadiusDefaultCheck.Value = 1,
        stealMouseInput: ConfigDialogState.stealMouseInputCheck.Value = 1,
        showButtonKeys: ConfigDialogState.showButtonKeysCheck.Value = 1,
        showOuterBorder: ConfigDialogState.showOuterBorderCheck.Value = 1
    }
}

UpdateConfigDialogGapHelper() {
    global ConfigDialogState

    if !IsObject(ConfigDialogState)
        return

    SyncConfigDialogSliderDisplays()
}

HandleConfigSizeSliderChange(*) {
    global ConfigDialogState

    if !IsObject(ConfigDialogState)
        return
    ConfigDialogState.sizeSlider.Value := NormalizeSliderRangeValue(ConfigDialogState.sizeSlider.Value, 1, 5, 3)
    UpdateConfigDialogPreview()
}

HandleConfigButtonGapSliderChange(*) {
    global ConfigDialogState, SizeProfiles

    if !IsObject(ConfigDialogState)
        return
    sizeKey := Format("{}", NormalizeSliderRangeValue(ConfigDialogState.sizeSlider.Value, 1, 5, 3))
    defaultGap := SizeProfiles.Has(sizeKey) ? SizeProfiles[sizeKey].btnGap : 0
    ConfigDialogState.buttonGapSlider.Value := NormalizeSliderRangeValue(ConfigDialogState.buttonGapSlider.Value, 0, 200, defaultGap)
    if ConfigDialogState.buttonGapDefaultCheck.Value = 1 && ConfigDialogState.buttonGapSlider.Value != defaultGap
        ConfigDialogState.buttonGapDefaultCheck.Value := 0
    UpdateConfigDialogPreview()
}

HandleConfigCornerRadiusSliderChange(*) {
    global ConfigDialogState

    if !IsObject(ConfigDialogState)
        return
    ConfigDialogState.cornerRadiusSlider.Value := NormalizeSliderRangeValue(ConfigDialogState.cornerRadiusSlider.Value, 0, 200, 0)
    if ConfigDialogState.cornerRadiusDefaultCheck.Value = 1 && ConfigDialogState.cornerRadiusSlider.Value != 0
        ConfigDialogState.cornerRadiusDefaultCheck.Value := 0
    UpdateConfigDialogPreview()
}

UpdateConfigDialogPreview(*) {
    global ConfigDialogState
    
    if !IsObject(ConfigDialogState)
        return

    previewState := BuildConfigDialogPreviewState(false)
    if !IsObject(previewState)
        return

    UpdateConfigDialogGapHelper()
    ApplyConfigDialogPreviewState(previewState, false)
}

OpenConfigEditor() {
    global ActiveConfigFileName, ButtonGapOverride, ConfigDialogState, CornerRadius, CurrentPageIndex, FillColor, FrameColor, MaskColor, OpenPositionMode, ShowButtonKeys, ShowOuterBorder, Size, StealMouseInput, ToggleHotkey

    configFileNames := GetAvailableConfigFiles()
    configDisplayNames := GetConfigDisplayNames(configFileNames)
    sizeOptions := GetSizeProfileOptions()
    openPositionOptions := ["auto-split", "mouse", "always-left", "always-right"]
    configGui := Gui("+AlwaysOnTop +ToolWindow +OwnDialogs", "StarHUD Config")
    configGui.MarginX := 12
    configGui.MarginY := 10

    configGui.Add("Text", "xm", "Config file")
    configList := configGui.Add("DropDownList", "xm w220", configDisplayNames)
    ChooseDropDownValue(configList, GetConfigDisplayName(ActiveConfigFileName), configDisplayNames)
    configGui.Add("Text", "xm y+2 c808080", "Switches the active config profile and reloads StarHUD.")
    newConfigButton := configGui.Add("Button", "xm y+10 w90", "New Config")
    cloneConfigButton := configGui.Add("Button", "x+8 w90", "Clone Config")
    deleteConfigButton := configGui.Add("Button", "x+8 w90", "Delete Config")

    configGui.Add("Text", "xm y+12", "Current page")
    pageInfoText := configGui.Add("Text", "x+8 yp w160", "")

    sliderLabelW := 90
    sliderValueW := 52
    sliderW := 220

    sizeSliderValue := GetBuiltInSizeSliderValue()
    gapDefaultValue := GetEffectiveButtonGap(Format("{}", sizeSliderValue))
    gapSliderValue := ButtonGapOverride = "" ? gapDefaultValue : NormalizeSliderRangeValue(ButtonGapOverride, 0, 200, gapDefaultValue)
    cornerSliderValue := NormalizeSliderRangeValue(CornerRadius, 0, 200, 0)

    configGui.Add("Text", "xm y+10", "Size")
    sizeHelperText := configGui.Add("Text", "xm y+4 w" sliderLabelW " c808080", "")
    sizeSlider := configGui.Add("Slider", "x+8 yp-2 w" sliderW " Range1-5 NoTicks ToolTip", sizeSliderValue)
    sizeValueEdit := configGui.Add("Edit", "x+8 yp w" sliderValueW " ReadOnly Center", sizeSliderValue)

    configGui.Add("Text", "xm y+8", "Button gap")
    buttonGapHelperText := configGui.Add("Text", "xm y+4 w" sliderLabelW " c808080", "")
    buttonGapSlider := configGui.Add("Slider", "x+8 yp-2 w" sliderW " Range0-200 NoTicks ToolTip", gapSliderValue)
    buttonGapDefaultCheck := configGui.Add("CheckBox", "x+8 yp+2", "Default")
    buttonGapDefaultCheck.Value := ButtonGapOverride = "" ? 1 : 0
    buttonGapValueEdit := configGui.Add("Edit", "x+8 yp-2 w" sliderValueW " ReadOnly Center", gapSliderValue)

    configGui.Add("Text", "xm y+8", "Corner radius")
    cornerRadiusHelperText := configGui.Add("Text", "xm y+4 w" sliderLabelW " c808080", "")
    cornerRadiusSlider := configGui.Add("Slider", "x+8 yp-2 w" sliderW " Range0-200 NoTicks ToolTip", cornerSliderValue)
    cornerRadiusDefaultCheck := configGui.Add("CheckBox", "x+8 yp+2", "Default")
    cornerRadiusDefaultCheck.Value := CornerRadius = 0 ? 1 : 0
    cornerRadiusValueEdit := configGui.Add("Edit", "x+8 yp-2 w" sliderValueW " ReadOnly Center", cornerSliderValue)

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

    showOuterBorderCheck := configGui.Add("CheckBox", "xm y+8", "Show outer border")
    showOuterBorderCheck.Value := ShowOuterBorder ? 1 : 0
    configGui.Add("Text", "xm y+2 c808080", "Toggle the thin outer frame ring around each button.")

    configGui.Add("Text", "xm y+8", "Open position")
    openPositionList := configGui.Add("DropDownList", "xm w180", openPositionOptions)
    ChooseDropDownValue(openPositionList, OpenPositionMode, openPositionOptions)
    configGui.Add("Text", "xm y+2 c808080", "Choose where the HUD appears when you open it.")

    configGui.Add("Text", "xm y+8", "Toggle key")
    toggleHotkeyEdit := configGui.Add("Edit", "xm w140", ToggleHotkey)
    configGui.Add("Text", "xm y+2 c808080", "Bare AHK key name used to open the HUD. RAlt + this key toggles edit mode.")

    stealMouseInputCheck := configGui.Add("CheckBox", "xm y+10", "Steal mouse input")
    stealMouseInputCheck.Value := StealMouseInput ? 1 : 0
    configGui.Add("Text", "xm y+2 c808080", "Block mouse clicks and movement from reaching the app underneath.")

    showButtonKeysCheck := configGui.Add("CheckBox", "xm y+8", "Show key labels on buttons")
    showButtonKeysCheck.Value := ShowButtonKeys ? 1 : 0
    configGui.Add("Text", "xm y+2 c808080", "Show or hide the action keys that appear under each button title.")

    addPageButton := configGui.Add("Button", "xm y+14 w100", "Add Page")
    deletePageButton := configGui.Add("Button", "x+8 w100", "Delete Page")
    resetPageButton := configGui.Add("Button", "x+8 w100", "Reset Page")
    openFolderButton := configGui.Add("Button", "xm y+8 w150", "Open File Location")
    openImagesButton := configGui.Add("Button", "x+8 w120", "Open Images")
    saveButton := configGui.Add("Button", "xm y+14 w120 Default", "Save")
    closeButton := configGui.Add("Button", "x+12 w120", "Close")

    ConfigDialogState := {
        gui: configGui,
        configList: configList,
        configFileNames: configFileNames,
        configDisplayNames: configDisplayNames,
        suppressConfigSwitch: false,
        pageInfoText: pageInfoText,
        sizeSlider: sizeSlider,
        sizeHelperText: sizeHelperText,
        sizeValueEdit: sizeValueEdit,
        buttonGapSlider: buttonGapSlider,
        buttonGapDefaultCheck: buttonGapDefaultCheck,
        buttonGapHelperText: buttonGapHelperText,
        buttonGapValueEdit: buttonGapValueEdit,
        cornerRadiusSlider: cornerRadiusSlider,
        cornerRadiusDefaultCheck: cornerRadiusDefaultCheck,
        cornerRadiusHelperText: cornerRadiusHelperText,
        cornerRadiusValueEdit: cornerRadiusValueEdit,
        maskColorEdit: maskColorEdit,
        frameColorEdit: frameColorEdit,
        fillColorEdit: fillColorEdit,
        showOuterBorderCheck: showOuterBorderCheck,
        openPositionList: openPositionList,
        toggleHotkeyEdit: toggleHotkeyEdit,
        stealMouseInputCheck: stealMouseInputCheck,
        showButtonKeysCheck: showButtonKeysCheck,
        originalState: CaptureConfigDialogPreviewState()
    }

    sizeSlider.OnEvent("Change", HandleConfigSizeSliderChange)
    buttonGapSlider.OnEvent("Change", HandleConfigButtonGapSliderChange)
    buttonGapDefaultCheck.OnEvent("Click", UpdateConfigDialogPreview)
    cornerRadiusSlider.OnEvent("Change", HandleConfigCornerRadiusSliderChange)
    cornerRadiusDefaultCheck.OnEvent("Click", UpdateConfigDialogPreview)
    maskColorEdit.OnEvent("Change", UpdateConfigDialogPreview)
    frameColorEdit.OnEvent("Change", UpdateConfigDialogPreview)
    fillColorEdit.OnEvent("Change", UpdateConfigDialogPreview)
    showOuterBorderCheck.OnEvent("Click", UpdateConfigDialogPreview)
    maskColorPickButton.OnEvent("Click", PickConfigDialogColor.Bind("maskColorEdit"))
    frameColorPickButton.OnEvent("Click", PickConfigDialogColor.Bind("frameColorEdit"))
    fillColorPickButton.OnEvent("Click", PickConfigDialogColor.Bind("fillColorEdit"))
    configList.OnEvent("Change", SwitchConfigFromDialog)
    newConfigButton.OnEvent("Click", NewConfigFromDialog)
    cloneConfigButton.OnEvent("Click", CloneConfigFromDialog)
    deleteConfigButton.OnEvent("Click", DeleteConfigFromDialog)
    addPageButton.OnEvent("Click", AddConfigPage)
    deletePageButton.OnEvent("Click", DeleteConfigPage)
    resetPageButton.OnEvent("Click", ResetConfigPage)
    openFolderButton.OnEvent("Click", OpenConfigFileLocation)
    openImagesButton.OnEvent("Click", OpenImagesFolder)
    saveButton.OnEvent("Click", SaveConfigEditor)
    closeButton.OnEvent("Click", CloseConfigEditor)
    configGui.OnEvent("Close", CloseConfigEditor)
    configGui.OnEvent("Escape", CloseConfigEditor)
    UpdateConfigDialogPageInfo()
    ConfigDialogState.buttonGapUsesDefault := ButtonGapOverride = ""
    UpdateConfigDialogGapHelper()
    configGui.Show("AutoSize")
}

UpdateConfigDialogPageInfo() {
    global ButtonPages, ConfigDialogState, CurrentPageIndex

    if !IsObject(ConfigDialogState)
        return

    ConfigDialogState.pageInfoText.Text := "Page " CurrentPageIndex " of " ButtonPages.Length
}

GetSelectedConfigDialogFileName() {
    global ConfigDialogState

    if !IsObject(ConfigDialogState)
        return ""
    return ResolveConfigFileNameFromDisplay(ConfigDialogState.configList.Text, ConfigDialogState.configFileNames)
}

RestoreConfigDialogSelection() {
    global ActiveConfigFileName, ConfigDialogState

    if !IsObject(ConfigDialogState)
        return
    ConfigDialogState.suppressConfigSwitch := true
    ChooseDropDownValue(ConfigDialogState.configList, GetConfigDisplayName(ActiveConfigFileName), ConfigDialogState.configDisplayNames)
    ConfigDialogState.suppressConfigSwitch := false
}

SwitchConfigFromDialog(*) {
    global ActiveConfigFileName, ConfigDialogState

    if IsObject(ConfigDialogState) && ConfigDialogState.suppressConfigSwitch
        return

    targetFileName := GetSelectedConfigDialogFileName()
    if targetFileName = "" || targetFileName = ActiveConfigFileName
        return

    try
    {
        SaveConfigStateForSwitch()
        SwitchToConfigFile(targetFileName)
    }
    catch as err
    {
        RestoreConfigDialogSelection()
        MsgBox(err.Message, "StarHUD Config Error")
    }
}

NewConfigFromDialog(*) {
    try
    {
        SaveConfigStateForSwitch()
        DestroyConfigEditor()
        targetFileName := PromptForConfigFileName("New")
        if targetFileName = ""
            return
        CreateNewConfigFile(targetFileName)
        SwitchToConfigFile(targetFileName)
    }
    catch as err
    {
        MsgBox(err.Message, "StarHUD Config Error")
    }
}

CloneConfigFromDialog(*) {
    try
    {
        SaveConfigStateForSwitch()
        DestroyConfigEditor()
        targetFileName := PromptForConfigFileName("Clone")
        if targetFileName = ""
            return
        CreateClonedConfigFile(targetFileName)
        SwitchToConfigFile(targetFileName)
    }
    catch as err
    {
        MsgBox(err.Message, "StarHUD Config Error")
    }
}

DeleteConfigFromDialog(*) {
    global ActiveConfigFileName

    if GetAvailableConfigFiles().Length <= 1
    {
        MsgBox("StarHUD must keep at least one config file.", "StarHUD Config")
        return
    }
    if MsgBox("Delete the current config file and save a .bak copy first?", "StarHUD Config", "YesNo Icon!") != "Yes"
    {
        RestoreConfigDialogSelection()
        return
    }

    try
    {
        nextFileName := GetAlternateConfigFileName(ActiveConfigFileName)
        BackupConfigFile()
        FileDelete(GetConfigFilePath())
        SwitchToConfigFile(nextFileName)
    }
    catch as err
    {
        MsgBox(err.Message, "StarHUD Config Error")
    }
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
    {
        ctrl.Value := chosenColor
        UpdateConfigDialogPreview()
    }
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
    global ConfigDialogState

    if !IsObject(ConfigDialogState)
        return

    appliedState := BuildConfigDialogPreviewState(true)
    ApplyConfigDialogPreviewState(appliedState, false)
}

SaveConfigEditor(*) {
    try
    {
        ApplyConfigDialogValues()
        PersistButtonPages()
        DestroyConfigEditor()
    }
    catch as err
    {
        MsgBox(err.Message, "StarHUD Config Error")
    }
}

ReopenConfigEditor() {
    DestroyConfigEditor()
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
        ApplyConfigDialogPreviewState(ConfigDialogState.originalState, false)
        DestroyConfigEditor()
    }
}

DestroyConfigEditor() {
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

ShowCurrentPage(panelX, panelY, activateWindow := true) {
    global CurrentPageIndex, EditMode, GuiH, GuiW, PageGuis, PanelVisible, StealMouseInput

    if CurrentPageIndex < 1 || CurrentPageIndex > PageGuis.Length
    {
        PanelVisible := false
        return
    }

    HideAllPages()
    pageGui := PageGuis[CurrentPageIndex]
    try hwnd := pageGui.Hwnd
    catch
    {
        PanelVisible := false
        return
    }
    showOptions := "x" panelX " y" panelY " w" GuiW " h" GuiH
    if !activateWindow || (!StealMouseInput && !EditMode)
        showOptions := "NA " showOptions

    pageGui.Show(showOptions)
    WinSetAlwaysOnTop 1, "ahk_id " hwnd
    WinMoveTop "ahk_id " hwnd
    if activateWindow && (StealMouseInput || EditMode)
        WinActivate("ahk_id " hwnd)
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

HandleToggleHotkey(*) {
    global PanelVisible

    if PanelVisible
        HidePanel()
    else
        ShowPanel()
}

HandleEditToggleHotkey(*) {
    ToggleEditMode()
}

RegisterToggleHotkeys(toggleKey := "") {
    global RegisteredEditToggleHotkey, RegisteredToggleHotkey, ToggleHotkey

    newToggleHotkey := toggleKey = "" ? NormalizeToggleHotkeyInput(ToggleHotkey) : NormalizeToggleHotkeyInput(toggleKey)
    newEditToggleHotkey := ">!" newToggleHotkey

    Hotkey(newToggleHotkey, HandleToggleHotkey, "On")
    Hotkey(newEditToggleHotkey, HandleEditToggleHotkey, "On")

    if RegisteredToggleHotkey != "" && RegisteredToggleHotkey != newToggleHotkey
        Hotkey(RegisteredToggleHotkey, "Off")
    if RegisteredEditToggleHotkey != "" && RegisteredEditToggleHotkey != newEditToggleHotkey
        Hotkey(RegisteredEditToggleHotkey, "Off")

    ToggleHotkey := newToggleHotkey
    RegisteredToggleHotkey := newToggleHotkey
    RegisteredEditToggleHotkey := newEditToggleHotkey
}

; ================== TOGGLE ==================
if EnsureConfigFileCompatibility()
    Reload()
RegisterToggleHotkeys()
