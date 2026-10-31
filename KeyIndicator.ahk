#Requires AutoHotkey v2.0
#Include ImagePut.ahk ; 挂载ImagePut图像库
#SingleInstance Force
CoordMode("ToolTip", "Screen")

; ==================== 默认参数 ====================
DEF_EDGE_SPACING    := 10
DEF_EDGE_MARGIN     := 10
DEF_EDGE_VERTICAL   := 0
DEF_EDGE_POS_X      := -1
DEF_EDGE_POS_Y      := -1
DEF_CENTER_DURATION := 500
DEF_CENTER_POS_X    := -1
DEF_CENTER_POS_Y    := -1
DEF_CENTER_GAP      := 20
DEF_CENTER_VERTICAL := 0
DEF_ALWAYS_ON_TOP   := true
DEF_SHOW_TRAY       := true
DEF_TRAY_ICON       := ""
DEF_KEY1            := ""
DEF_KEY2            := ""
DEF_KEY3            := ""

INI_FILE  := A_ScriptDir "\setting.ini"
IMG_DIR   := A_ScriptDir "\images\"
SND_DIR   := A_ScriptDir "\sounds\"
ICO_DIR   := A_ScriptDir "\icon\"
MISSING   := "\x01MISSING\x01"

; ==================== 初始化 ====================
if !DirExist(IMG_DIR)
    DirCreate(IMG_DIR)
if !DirExist(SND_DIR)
    DirCreate(SND_DIR)
if !DirExist(ICO_DIR)
    DirCreate(ICO_DIR)
if !FileExist(INI_FILE)
    GenerateDefaultIni(INI_FILE)

global ImgSizeCache := Map()
global EdgeSizes    := Map()
global CurrentCenterW := 0
global CurrentCenterH := 0

global AlwaysOnTop    := ReadIniBool("General", "AlwaysOnTop", DEF_ALWAYS_ON_TOP)
global ShowTrayIcon   := ReadIniBool("General", "ShowTrayIcon", DEF_SHOW_TRAY)
global TrayIconFile   := ReadIniStr("General", "TrayIcon", DEF_TRAY_ICON)

global Key1 := ReadIniStr("Keys", "Key1", DEF_KEY1)
global Key2 := ReadIniStr("Keys", "Key2", DEF_KEY2)
global Key3 := ReadIniStr("Keys", "Key3", DEF_KEY3)

global EdgeSpacing    := ReadIniInt("Images", "EdgeSpacing", DEF_EDGE_SPACING, 0, 10000)
global EdgeVertical   := ReadIniBool("Images", "EdgeVertical", DEF_EDGE_VERTICAL)
global EdgePosX       := ReadIniInt("Images", "EdgePosX", DEF_EDGE_POS_X, -1, 10000)
global EdgePosY       := ReadIniInt("Images", "EdgePosY", DEF_EDGE_POS_Y, -1, 10000)
global CenterDuration := ReadIniInt("Images", "CenterDuration", DEF_CENTER_DURATION, 100, 10000)
global CenterPosX     := ReadIniInt("Images", "CenterPosX", DEF_CENTER_POS_X, -1, 10000)
global CenterPosY     := ReadIniInt("Images", "CenterPosY", DEF_CENTER_POS_Y, -1, 10000)
global CenterGap      := ReadIniInt("Images", "CenterGap", DEF_CENTER_GAP, 0, 10000)
global CenterVertical := ReadIniBool("Images", "CenterVertical", DEF_CENTER_VERTICAL)

; 指示灯图片
global Key1OnPic  := ResolveImage(ReadIniStr("Images", "Key1OnPic",  "caps_on.png"))
global Key1OffPic := ResolveImage(ReadIniStr("Images", "Key1OffPic", "caps_off.png"))
global Key2OnPic  := ResolveImage(ReadIniStr("Images", "Key2OnPic",  "num_on.png"))
global Key2OffPic := ResolveImage(ReadIniStr("Images", "Key2OffPic", "num_off.png"))
global Key3OnPic  := ResolveImage(ReadIniStr("Images", "Key3OnPic",  "scr_on.png"))
global Key3OffPic := ResolveImage(ReadIniStr("Images", "Key3OffPic", "scr_off.png"))

; 提示图片（按虚拟键位编号，与Key1/2/3对应）
global Key1OnTipImg  := ResolveImage(ReadIniStr("Images", "Key1OnTip",  "caps_on_big.png"))
global Key1OffTipImg := ResolveImage(ReadIniStr("Images", "Key1OffTip", "caps_off_big.png"))
global Key2OnTipImg  := ResolveImage(ReadIniStr("Images", "Key2OnTip",  "num_on_big.png"))
global Key2OffTipImg := ResolveImage(ReadIniStr("Images", "Key2OffTip", "num_off_big.png"))
global Key3OnTipImg  := ResolveImage(ReadIniStr("Images", "Key3OnTip",  "scr_on_big.png"))
global Key3OffTipImg := ResolveImage(ReadIniStr("Images", "Key3OffTip", "scr_off_big.png"))

; 修饰键提示图
global ShiftDnC := ResolveImage(ReadIniStr("Images", "ShiftDownTip", "shift_down_big.png"))
global ShiftUpC := ResolveImage(ReadIniStr("Images", "ShiftUpTip",   "shift_up_big.png"))
global CtrlDnC  := ResolveImage(ReadIniStr("Images", "CtrlDownTip",  "ctrl_down_big.png"))
global CtrlUpC  := ResolveImage(ReadIniStr("Images", "CtrlUpTip",    "ctrl_up_big.png"))
global AltDnC   := ResolveImage(ReadIniStr("Images", "AltDownTip",   "alt_down_big.png"))
global AltUpC   := ResolveImage(ReadIniStr("Images", "AltUpTip",     "alt_up_big.png"))
global WinDnC   := ResolveImage(ReadIniStr("Images", "WinDownTip",   "win_down_big.png"))
global WinUpC   := ResolveImage(ReadIniStr("Images", "WinUpTip",     "win_up_big.png"))

; 提示声音（修正键名：与 setting.ini 中保持一致）
global Key1OnSnd  := ResolveSound(ReadIniStr("Sounds", "Key1OnSound",  "caps_on.wav"))
global Key1OffSnd := ResolveSound(ReadIniStr("Sounds", "Key1OffSound", "caps_off.wav"))
global Key2OnSnd  := ResolveSound(ReadIniStr("Sounds", "Key2OnSound",  "num_on.wav"))
global Key2OffSnd := ResolveSound(ReadIniStr("Sounds", "Key2OffSound", "num_off.wav"))
global Key3OnSnd  := ResolveSound(ReadIniStr("Sounds", "Key3OnSound",  "scr_on.wav"))
global Key3OffSnd := ResolveSound(ReadIniStr("Sounds", "Key3OffSound", "scr_off.wav"))
global ShiftDnS := ResolveSound(ReadIniStr("Sounds", "ShiftDownSound", "shift_down.wav"))
global ShiftUpS := ResolveSound(ReadIniStr("Sounds", "ShiftUpSound",   "shift_up.wav"))
global CtrlDnS  := ResolveSound(ReadIniStr("Sounds", "CtrlDownSound",  "ctrl_down.wav"))
global CtrlUpS  := ResolveSound(ReadIniStr("Sounds", "CtrlUpSound",    "ctrl_up.wav"))
global AltDnS   := ResolveSound(ReadIniStr("Sounds", "AltDownSound",   "alt_down.wav"))
global AltUpS   := ResolveSound(ReadIniStr("Sounds", "AltUpSound",     "alt_up.wav"))
global WinDnS   := ResolveSound(ReadIniStr("Sounds", "WinDownSound",   "win_down.wav"))
global WinUpS   := ResolveSound(ReadIniStr("Sounds", "WinUpSound",     "win_up.wav"))

; 初始状态：Key 为空时 LastKey 无意义（用 false 占位，PollAll 中会跳过空 Key）
global LastKey1 := (Key1 = "") ? false : GetKeyActive(Key1)
global LastKey2 := (Key2 = "") ? false : GetKeyActive(Key2)
global LastKey3 := (Key3 = "") ? false : GetKeyActive(Key3)

global SecondState := Map("Shift", 0, "Ctrl", 0, "Alt", 0, "Win", 0)
global SecondGen   := Map("Shift", 0, "Ctrl", 0, "Alt", 0, "Win", 0)
global SecondOrder := ["Shift", "Ctrl", "Alt", "Win"]
global PrevMod     := Map()

global KeyGui1   := CreatePicWindow("KeyLights1")
global KeyGui2   := CreatePicWindow("KeyLights2")
global KeyGui3   := CreatePicWindow("KeyLights3")
global CenterGui := CreatePicWindow("KeyLightsCenter")
global SecondGuis := Map()
SecondGuis["Shift"] := CreatePicWindow("ShiftCenter")
SecondGuis["Ctrl"]  := CreatePicWindow("CtrlCenter")
SecondGuis["Alt"]   := CreatePicWindow("AltCenter")
SecondGuis["Win"]   := CreatePicWindow("WinCenter")

; 初始化 PrevMod 为当前物理状态，避免启动时误触发
for key in SecondOrder
    PrevMod[key] := IsSecondPhysicallyDown(key)

UpdateAllEdgePics()
LayoutEdgeWindows()
SetupTray()
SetTimer(PollAll, 30)
return


; ==================== 配置读写 ====================

GenerateDefaultIni(path) {
    content := "
    (

; =============================== 设置说明 =============================
; KeyLights 键盘指示灯 配置文件
; *修改后，必须重启程序才能生效*
; 本设置文件若改名、损坏、删除、不在本程序文件夹中，程序按默认设置参数，自动重新生成。
; 生成时若本程序文件夹写入权限不足、磁盘空间不足，程序将报错，退出。
; 若出现程序运行报错、显示错乱，建议将本设置文件改名（也可删除，删除前建议备份），程序将自动再生成默认设置，一般即可恢复正常。
; 图片文件放在程序文件夹下 \images\ 中，声音文件放在 \sounds\ 中，托盘图标放在 \icon\ 中，文件名不分大小写。
; 文件名留空、文件不存在、文件损坏，按“无图片/无声音”处理（无图片，不显示相应状态的图片；无声音，不播放相应状态的声音）。
; 若不要某个键显示/发声，可将对应图片/声音删除或将设置对应文件名清空，即不显示/不发声。
; ============================================================

[General]
; 始终保持在屏幕最上层（前端）显示，不受遮挡。
; 1 最前端，0 系统自动分配。
AlwaysOnTop=1

; 系统任务栏（系统托盘/通知区域）图标。
; 1 显示，0 不显示。
ShowTrayIcon=1

; 任务栏图标文件名（放在 icon 文件夹；支持 .ico / .png / .bmp），大小建议不超过 256x256 像素。
; 留空或文件不存在，与↑上一项配合，若设置为显示，则显示程序默认图标。
TrayIcon=

[Keys]
; 3个指示灯位置：key1(左、上）/key2（中）/key3（右、下），可分别对应 CapsLock/NumLock/ScrollLock（建议仅此三键），任意指定对应键。
; 如 Key1=CapsLock 指示 CapsLock 状态，同时 Key2=CapsLock 也指示 CapsLock 状态。
; 留空 => 该指示灯不响应任何键。
Key1=CapsLock
Key2=NumLock
Key3=ScrollLock

[Images]
; 图片文件放在程序文件夹下 \images\ 中，文件名不分大小写。
; 图片按实际大小显示，支持 .png 图片透明度/背景（镂空）透明。大小建议不超过 128x128 像素，图片过大，会干扰其它的显示。
; 文件名留空、文件不存在、文件损坏，不显示相应状态的图片。

; ---- 指示灯图片组 ----
; 中心 X 坐标，-1=自动水平居中，设置过大会超出屏幕。
EdgePosX=-1

; 中心 Y 坐标，-1=自动屏幕底部，设置过大会超出屏幕。
EdgePosY=-1

; 间距，建议 0~200 像素，键与键的指示图片间距离。
EdgeSpacing=10

; 排列方向：1=竖排（1列），0=横排（1行）。
EdgeVertical=0

; ---- 指示灯图片组 (跟随键盘 锁定/解锁 状态的显示) ----
; key1~key3 3套（OnPic+OffPic 2个图片为一套）。
; On(锁定时)、Off(解锁后) 显示图片。
; key1 => 横排 左边图片、竖排 上方图片。
Key1OnPic=caps_on.png
Key1OffPic=caps_off.png

; key2 => 中间图片。
Key2OnPic=num_on.png
Key2OffPic=num_off.png

; key3 => 横排 右边图片、竖排 下方图片。
Key3OnPic=scr_on.png
Key3OffPic=scr_off.png

; ---- 提示图片组 ----
; 提示显示时长 建议 100-1000 毫秒。
CenterDuration=500

; 中心 X 坐标（像素），-1=自动工作区正中，设置过大会超出屏幕。
CenterPosX=-1

; 中心 Y 坐标（像素），-1=自动工作区正中，设置过大会超出屏幕。
CenterPosY=-1

; 间距 建议 0-200 像素，键与键的提示图片间距离。
CenterGap=20

; 排列方向：1=竖排（1列），0=横排（2行，key1/key2/key3 提示在第1行，Shift/Ctrl/Alt/Win 提示在第2行）。
CenterVertical=0

; ---- 锁定提示图片组（键盘状切换时 短暂显示，显示时长 CenterDuration 参数） ----
; key1~key3 3套（OnTip+OffTip 2个图片为一套）。
; key1 横排 左边图片、竖排 上方图片, On(锁定时)、Off(解锁后) 显示。
Key1OnTip=caps_on_big.png
Key1OffTip=caps_off_big.png

; key2 中间图片, On(锁定时)、Off(解锁后) 显示。
Key2OnTip=num_on_big.png
Key2OffTip=num_off_big.png

; key3 横排 右边图片、竖排 下方图片, On(锁定时)、Off(解锁后) 显示。
Key3OnTip=scr_on_big.png
Key3OffTip=scr_off_big.png

; ---- 按键提示图片组（键盘按下时 显示，一直按下，一直显示；弹起时 短暂显示，显示时长 CenterDuration 参数） ----
; shift/ctrl/alt/win 键，4套（DownTip+UpTip 2个图片为一套）。
; 设置 Shift/Ctrl/Alt/Win（不区分左右 RShift/LShift 视为同一键)，响应按下（包括一直按住）、弹起时的状态。
; shift Down(按下时)、Up(弹起后) 显示。
ShiftDownTip=shift_down_big.png
ShiftUpTip=shift_up_big.png

; ctrl Down(按下时)、Up(弹起后) 显示。
CtrlDownTip=ctrl_down_big.png
CtrlUpTip=ctrl_up_big.png

; alt Down(按下时)、Up(弹起后) 显示。
AltDownTip=alt_down_big.png
AltUpTip=alt_up_big.png

; win Down(按下时)、Up(弹起后) 显示。
WinDownTip=win_down_big.png
WinUpTip=win_up_big.png

[Sounds]
; 声音文件放在程序文件夹下 \sounds\ 中，文件名不分大小写。
; 文件名留空、文件不存在、文件损坏，不播放对应声音。
; key1 On(锁定时)、Off(解锁后) 发声。
Key1OnSound=caps_on.wav
Key1OffSound=caps_off.wav

; key2 On(锁定时)、Off(解锁后) 发声。
Key2OnSound=num_on.wav
Key2OffSound=num_off.wav

; key3 On(锁定时)、Off(解锁后) 发声。
Key3OnSound=scr_on.wav
Key3OffSound=scr_off.wav

; shift On(按下时)、Off(弹起后) 发声。
ShiftDownSound=shift_down.wav
ShiftUpSound=shift_up.wav

; ctrl On(按下时)、Off(弹起后) 发声。
CtrlDownSound=ctrl_down.wav
CtrlUpSound=ctrl_up.wav

; alt On(按下时)、Off(弹起后) 发声。
AltDownSound=alt_down.wav
AltUpSound=alt_up.wav

; win On(按下时)、Off(弹起后) 发声。
WinDownSound=win_down.wav
WinUpSound=win_up.wav
    )"
    content := RegExReplace(content, "m)^[ \t]+", "")
    f := FileOpen(path, "w", "UTF-8")
    f.Write(content)
    f.Close()
}

ReadIniStr(section, key, default := "") {
    global INI_FILE, MISSING
    v := IniRead(INI_FILE, section, key, MISSING)
    if (v = MISSING)
        return default
    return Trim(v)
}

ReadIniInt(section, key, default, minVal, maxVal) {
    global INI_FILE, MISSING
    v := IniRead(INI_FILE, section, key, MISSING)
    if (v = MISSING)
        return default
    v := Trim(v)
    if (v = "" || !IsInteger(v))
        return default
    n := Integer(v)
    if (n < minVal || n > maxVal)
        return default
    return n
}

ReadIniBool(section, key, default) {
    global INI_FILE, MISSING
    v := IniRead(INI_FILE, section, key, MISSING)
    if (v = MISSING)
        return default
    v := Trim(v)
    if (v = "" || v = "?")
        return default
    if (v = "1" || v = "true" || v = "yes" || v = "on")
        return true
    if (v = "0" || v = "false" || v = "no" || v = "off")
        return false
    return default
}

; ==================== 文件解析 ====================

ResolveImage(name) {
    global IMG_DIR
    if (name = "")
        return ""
    if InStr(name, ":") || SubStr(name, 1, 1) = "\" || SubStr(name, 1, 1) = "/"
        full := name
    else if InStr(name, "\") || InStr(name, "/")
        full := A_ScriptDir . "\" . name
    else
        full := IMG_DIR . name
    return FileExist(full) ? full : ""
}

ResolveSound(name) {
    global SND_DIR
    if (name = "")
        return ""
    if InStr(name, ":") || SubStr(name, 1, 1) = "\" || SubStr(name, 1, 1) = "/"
        full := name
    else if InStr(name, "\") || InStr(name, "/")
        full := A_ScriptDir . "\" . name
    else
        full := SND_DIR . name
    if FileExist(full)
        return full
    base := RegExReplace(full, "\.[^.\\/]+$")
    for ext in [".wav", ".mp3"] {
        if FileExist(base . ext)
            return base . ext
    }
    return ""
}

ResolveIcon(name) {
    global ICO_DIR
    if (name = "")
        return ""
    if InStr(name, ":") || SubStr(name, 1, 1) = "\" || SubStr(name, 1, 1) = "/"
        full := name
    else if InStr(name, "\") || InStr(name, "/")
        full := A_ScriptDir . "\" . name
    else
        full := ICO_DIR . name
    return FileExist(full) ? full : ""
}

; ==================== 工作区 / 图片尺寸 ====================

GetWorkArea() {
    rect := Buffer(16, 0)
    DllCall("SystemParametersInfoW", "UInt", 0x30, "UInt", 0, "Ptr", rect, "UInt", 0)
    l := NumGet(rect, 0, "Int")
    t := NumGet(rect, 4, "Int")
    r := NumGet(rect, 8, "Int")
    b := NumGet(rect, 12, "Int")
    return {l: l, t: t, r: r, b: b, w: r - l, h: b - t}
}

GetImageSize(path) {
    global ImgSizeCache
    if (path = "" || !FileExist(path))
        return {w: 0, h: 0}
    if ImgSizeCache.Has(path)
        return ImgSizeCache[path]
    g := Gui("-Caption +ToolWindow")
    g.MarginX := 0
    g.MarginY := 0
    p := g.Add("Picture", "x0 y0", path)
    g.Show("x-10000 y-10000 AutoSize NoActivate")
    p.GetPos(&px, &py, &pw, &ph)
    g.Destroy()
    ImgSizeCache[path] := {w: pw, h: ph}
    return ImgSizeCache[path]
}

; ==================== 键状态 ====================

GetKeyActive(k) {
    static lockMap := Map("capslock", "CapsLock", "numlock", "NumLock", "scrolllock", "ScrollLock")
    static modMap := Map(
        "shift", ["LShift", "RShift"],
        "ctrl",  ["LControl", "RControl"],
        "alt",   ["LAlt", "RAlt"],
        "win",   ["LWin", "RWin"])
    if (k = "")
        return false
    kl := StrLower(k)
    try {
        if lockMap.Has(kl)
            return GetKeyState(lockMap[kl], "T")
        if modMap.Has(kl) {
            for side in modMap[kl]
                if GetKeyState(side, "P")
                    return true
            return false
        }
        return GetKeyState(k, "P")
    } catch {
        return false
    }
}

GetModSides(key) {
    switch key {
        case "Shift": return ["LShift", "RShift"]
        case "Ctrl":  return ["LControl", "RControl"]
        case "Alt":   return ["LAlt", "RAlt"]
        case "Win":   return ["LWin", "RWin"]
    }
    return []
}

IsSecondPhysicallyDown(key) {
    for side in GetModSides(key)
        if GetKeyState(side, "P")
            return true
    return false
}

; ==================== 窗口创建 ====================

CreatePicWindow(title) {
    global AlwaysOnTop
    g := Gui("-Caption +ToolWindow +E0x80000 +E0x20 +E0x08000000", title)
    g.MarginX := 0
    g.MarginY := 0
    g.Add("Text", "x0 y0 BackgroundTrans vPic")
    g.imageHwnd := 0
    g.Show("x-10000 y-10000 w1 h1 NoActivate")
    if AlwaysOnTop
        WinSetAlwaysOnTop(true, "ahk_id " . g.Hwnd)
    g.Hide()
    return g
}

SetGuiPic(g, imgPath, &outW, &outH) {
    if (imgPath = "" || !FileExist(imgPath)) {
        ; 空路径或文件不存在：清理旧子窗口并隐藏
        if (g.imageHwnd) {
            try DllCall("DestroyWindow", "Ptr", g.imageHwnd)
            g.imageHwnd := 0
        }
        g.Hide()
        outW := 0
        outH := 0
        return false
    }

    ; 1. 如果存在旧的图像子窗口，先销毁它，防止重叠
    if (g.imageHwnd) {
        try DllCall("DestroyWindow", "Ptr", g.imageHwnd)
        g.imageHwnd := 0
    }

    try {
        outW := ImageWidth(imgPath)
        outH := ImageHeight(imgPath)

        ; 2. 调整容器控件和父 GUI 的尺寸
        g["Pic"].Move(0, 0, outW, outH)
        g.Move(, , outW, outH)

        ; 3. 创建新的图像子窗口，并记录其句柄
        g.imageHwnd := ImageShow(imgPath, "", [0, 0], 0x40000000 | 0x10000000 | 0x8000000, 0x80000, g["Pic"].Hwnd, false)

        ; 4. 显示父 GUI，子窗口才会随之出现
        g.Show("NoActivate")
        return true
    } catch {
        g.Hide()
        outW := 0
        outH := 0
        return false
    }
}

; ==================== 指示灯布局 ====================

UpdateAllEdgePics() {
    global LastKey1, LastKey2, LastKey3
    global Key1, Key2, Key3
    global Key1OnPic, Key1OffPic, Key2OnPic, Key2OffPic, Key3OnPic, Key3OffPic
    global KeyGui1, KeyGui2, KeyGui3, EdgeSizes

    EdgeSizes := Map()
    ; Key 为空时传空路径，不显示任何指示灯图片
    EdgeSizes[1] := SetEdgeSize(KeyGui1, Key1 = "" ? "" : (LastKey1 ? Key1OnPic : Key1OffPic))
    EdgeSizes[2] := SetEdgeSize(KeyGui2, Key2 = "" ? "" : (LastKey2 ? Key2OnPic : Key2OffPic))
    EdgeSizes[3] := SetEdgeSize(KeyGui3, Key3 = "" ? "" : (LastKey3 ? Key3OnPic : Key3OffPic))
}

SetEdgeSize(g, imgPath) {
    w := 0
    h := 0
    ok := SetGuiPic(g, imgPath, &w, &h)
    return {visible: ok, w: w, h: h}
}

LayoutEdgeWindows() {
    global KeyGui1, KeyGui2, KeyGui3, EdgeSizes
    global EdgeSpacing, EdgeVertical, EdgePosX, EdgePosY

    items := []
    for i, g in [KeyGui1, KeyGui2, KeyGui3] {
        if EdgeSizes.Has(i) && EdgeSizes[i].visible
            items.Push({gui: g, w: EdgeSizes[i].w, h: EdgeSizes[i].h})
    }
    if (items.Length = 0)
        return

    n := items.Length
    sp := EdgeSpacing
    wa := GetWorkArea()

    if (EdgeVertical) {
        totalH := (n - 1) * sp
        maxW := 0
        for it in items {
            totalH += it.h
            maxW := Max(maxW, it.w)
        }
        totalW := maxW

        cx := (EdgePosX < 0) ? (wa.l + wa.w // 2) : EdgePosX
        cy := (EdgePosY < 0) ? (wa.b - totalH // 2) : EdgePosY
        gx := cx - totalW // 2
        gy := cy - totalH // 2

        if (gx < wa.l || gy < wa.t || gx + totalW > wa.r || gy + totalH > wa.b) {
            cx := wa.l + wa.w // 2
            cy := wa.b - totalH // 2
            gx := cx - totalW // 2
            gy := cy - totalH // 2
            gx := Max(wa.l, Min(gx, wa.r - totalW))
            gy := Max(wa.t, Min(gy, wa.b - totalH))
        }

        y := gy
        for it in items {
            x := gx + (totalW - it.w) // 2
            it.gui.Move(x, y, it.w, it.h)
            it.gui.Show("NoActivate")
            y += it.h + sp
        }
    } else {
        totalW := (n - 1) * sp
        maxH := 0
        for it in items {
            totalW += it.w
            maxH := Max(maxH, it.h)
        }
        totalH := maxH

        cx := (EdgePosX < 0) ? (wa.l + wa.w // 2) : EdgePosX
        cy := (EdgePosY < 0) ? (wa.b - totalH // 2) : EdgePosY
        gx := cx - totalW // 2
        gy := cy - totalH // 2

        if (gx < wa.l || gy < wa.t || gx + totalW > wa.r || gy + totalH > wa.b) {
            cx := wa.l + wa.w // 2
            cy := wa.b - totalH // 2
            gx := cx - totalW // 2
            gy := cy - totalH // 2
            gx := Max(wa.l, Min(gx, wa.r - totalW))
            gy := Max(wa.t, Min(gy, wa.b - totalH))
        }

        x := gx
        for it in items {
            y := gy + (totalH - it.h) // 2
            it.gui.Move(x, y, it.w, it.h)
            it.gui.Show("NoActivate")
            x += it.w + sp
        }
    }
}

; ==================== 轮询（配置驱动） ====================

PollAll() {
    global LastKey1, LastKey2, LastKey3
    global Key1, Key2, Key3
    global KeyGui1, KeyGui2, KeyGui3, EdgeSizes
    global Key1OnPic, Key1OffPic, Key2OnPic, Key2OffPic, Key3OnPic, Key3OffPic
    global Key1OnTipImg, Key1OffTipImg, Key2OnTipImg, Key2OffTipImg, Key3OnTipImg, Key3OffTipImg
    global Key1OnSnd, Key1OffSnd, Key2OnSnd, Key2OffSnd, Key3OnSnd, Key3OffSnd
    global SecondState, SecondGen, SecondOrder, PrevMod, CenterDuration

    ; ---- 锁键：由 Key1/Key2/Key3 配置驱动 ----
    ; 局部数组：索引 1/2/3 对应 key1/key2/key3
    keyNames := [Key1, Key2, Key3]
    onPics   := [Key1OnPic, Key2OnPic, Key3OnPic]
    offPics  := [Key1OffPic, Key2OffPic, Key3OffPic]
    onTips   := [Key1OnTipImg, Key2OnTipImg, Key3OnTipImg]
    offTips  := [Key1OffTipImg, Key2OffTipImg, Key3OffTipImg]
    onSnds   := [Key1OnSnd, Key2OnSnd, Key3OnSnd]
    offSnds  := [Key1OffSnd, Key2OffSnd, Key3OffSnd]
    guis     := [KeyGui1, KeyGui2, KeyGui3]

    layoutChanged := false
    triggered := Map()  ; 本周期内已触发过提示/声音的物理键，避免同一键被多个虚拟键位重复触发

    for i, keyName in keyNames {
        if (keyName = "")
            continue  ; 空配置：跳过，不检测/不显示/不发声

        nowActive := GetKeyActive(keyName)
        lastActive := (i = 1) ? LastKey1 : (i = 2) ? LastKey2 : LastKey3
        if (nowActive = lastActive)
            continue

        ; 更新该虚拟键位的指示灯图片
        EdgeSizes[i] := SetEdgeSize(guis[i], nowActive ? onPics[i] : offPics[i])
        layoutChanged := true

        ; 更新 Last 状态
        if (i = 1)
            LastKey1 := nowActive
        else if (i = 2)
            LastKey2 := nowActive
        else
            LastKey3 := nowActive

        ; 提示图片 + 声音：使用该虚拟键位自己的配置（修正问题2的关键）
        ; 同一物理键在本周期只触发一次（共用同一个提示图片框）
        physKey := StrLower(keyName)
        if !triggered.Has(physKey) {
            triggered[physKey] := true
            PlaySoundIfSet(nowActive ? onSnds[i] : offSnds[i])
            ShowCenter(nowActive ? onTips[i] : offTips[i])
        }
    }

    if (layoutChanged)
        LayoutEdgeWindows()

    ; ---- 修饰键（Shift/Ctrl/Alt/Win）物理状态检测 ----
    secondChanged := false
    for key in SecondOrder {
        isDown := IsSecondPhysicallyDown(key)
        wasDown := PrevMod[key]

        if (isDown && !wasDown) {
            PrevMod[key] := true
            if (SecondState[key] != 1) {
                SecondState[key] := 1
                PlaySecondSound(key, "Down")
                secondChanged := true
            }
        } else if (!isDown && wasDown) {
            PrevMod[key] := false
            if (SecondState[key] = 1) {
                SecondState[key] := 2
                curGen := SecondGen[key] + 1
                SecondGen[key] := curGen
                PlaySecondSound(key, "Up")
                SetTimer(HideSecondKey.Bind(key, curGen), -CenterDuration)
                secondChanged := true
            }
        }
    }
    if (secondChanged)
        LayoutSecondGroup()
}

; ==================== 第一组提示 ====================

ShowCenter(imgPath) {
    global CenterGui, CenterPosX, CenterPosY, CenterDuration
    global CurrentCenterW, CurrentCenterH

    if (imgPath = "" || !FileExist(imgPath))
        return

    CenterGui.Hide()

    sz := GetImageSize(imgPath)
    CurrentCenterW := sz.w
    CurrentCenterH := sz.h

    wa := GetWorkArea()
    cx := (CenterPosX < 0) ? (wa.l + wa.w // 2) : CenterPosX
    cy := (CenterPosY < 0) ? (wa.t + wa.h // 2) : CenterPosY
    x := cx - sz.w // 2
    y := cy - sz.h // 2
    if (x < wa.l || y < wa.t || x + sz.w > wa.r || y + sz.h > wa.b) {
        x := wa.l + (wa.w - sz.w) // 2
        y := wa.t + (wa.h - sz.h) // 2
    }

    ok := SetGuiPic(CenterGui, imgPath, &w, &h)
    if ok {
        CenterGui.Move(x, y, w, h)
        CenterGui.Show("NoActivate")
    }

    SetTimer(HideCenter, -CenterDuration)

    if HasVisibleSecond()
        LayoutSecondGroup()
}

HideCenter() {
    global CenterGui
    CenterGui.Hide()
}

; ==================== 声音 ====================

PlaySoundIfSet(file) {
    if (file = "" || !FileExist(file))
        return
    try SoundPlay(file)
}

PlaySecondSound(key, dir) {
    global ShiftDnS, ShiftUpS, CtrlDnS, CtrlUpS, AltDnS, AltUpS, WinDnS, WinUpS
    snd := ""
    switch key {
        case "Shift": snd := (dir = "Down") ? ShiftDnS : ShiftUpS
        case "Ctrl":  snd := (dir = "Down") ? CtrlDnS  : CtrlUpS
        case "Alt":   snd := (dir = "Down") ? AltDnS   : AltUpS
        case "Win":   snd := (dir = "Down") ? WinDnS   : WinUpS
    }
    PlaySoundIfSet(snd)
}

; ==================== 第二组 ====================

GetSecondImg(k, st) {
    global ShiftDnC, ShiftUpC, CtrlDnC, CtrlUpC, AltDnC, AltUpC, WinDnC, WinUpC
    switch k {
        case "Shift": return st = 1 ? ShiftDnC : ShiftUpC
        case "Ctrl":  return st = 1 ? CtrlDnC  : CtrlUpC
        case "Alt":   return st = 1 ? AltDnC   : AltUpC
        case "Win":   return st = 1 ? WinDnC   : WinUpC
    }
    return ""
}

HasVisibleSecond() {
    global SecondState, SecondOrder
    for k in SecondOrder
        if (SecondState[k] != 0)
            return true
    return false
}

HideSecondKey(key, gen) {
    global SecondState, SecondGen
    if (SecondGen[key] != gen)
        return
    if (SecondState[key] != 2)
        return
    SecondState[key] := 0
    LayoutSecondGroup()
}

LayoutSecondGroup() {
    global SecondState, SecondOrder, SecondGuis
    global CenterPosX, CenterPosY, CenterGap, CenterVertical
    global CurrentCenterW, CurrentCenterH

    for k in SecondOrder
        SecondGuis[k].Hide()

    visible := []
    for k in SecondOrder {
        st := SecondState[k]
        if (st = 0)
            continue
        img := GetSecondImg(k, st)
        if (img = "" || !FileExist(img))
            continue
        sz := GetImageSize(img)
        visible.Push({key: k, state: st, img: img, w: sz.w, h: sz.h})
    }
    if (visible.Length = 0)
        return

    wa := GetWorkArea()
    c1x := (CenterPosX < 0) ? (wa.l + wa.w // 2) : CenterPosX
    c1y := (CenterPosY < 0) ? (wa.t + wa.h // 2) : CenterPosY
    firstBottom := c1y + CurrentCenterH // 2
    topY := firstBottom + CenterGap

    n := visible.Length
    sp := CenterGap

    if (CenterVertical) {
        totalH := (n - 1) * sp
        for it in visible
            totalH += it.h
        if (topY + totalH > wa.b)
            topY := wa.b - totalH
        if (topY < wa.t)
            topY := wa.t

        y := topY
        for it in visible {
            x := c1x - it.w // 2
            if (x < wa.l)
                x := wa.l
            if (x + it.w > wa.r)
                x := wa.r - it.w
            g := SecondGuis[it.key]
            if SetGuiPic(g, it.img, &w, &h) {
                g.Move(x, y, w, h)
                g.Show("NoActivate")
            }
            y += it.h + sp
        }
    } else {
        totalW := (n - 1) * sp
        maxH := 0
        for it in visible {
            totalW += it.w
            maxH := Max(maxH, it.h)
        }
        gx := c1x - totalW // 2
        if (gx < wa.l)
            gx := wa.l
        if (gx + totalW > wa.r)
            gx := wa.r - totalW
        if (topY + maxH > wa.b)
            topY := wa.b - maxH
        if (topY < wa.t)
            topY := wa.t

        x := gx
        for it in visible {
            y := topY + (maxH - it.h) // 2
            g := SecondGuis[it.key]
            if SetGuiPic(g, it.img, &w, &h) {
                g.Move(x, y, w, h)
                g.Show("NoActivate")
            }
            x += it.w + sp
        }
    }
}

; ==================== 托盘菜单 ====================

SetupTray() {
    global ShowTrayIcon, TrayIconFile
    A_TrayMenu.Delete()
    A_TrayMenu.Add("打开设置", (*) => OpenSettings())
    A_TrayMenu.Add("关闭任务栏图标", (*) => HideTrayIcon())
    A_TrayMenu.Add()
    A_TrayMenu.Add("退出", (*) => ExitApp())
    A_TrayMenu.Default := "打开设置"
    A_IconTip := "KeyLights 锁键指示灯"

    if (TrayIconFile != "") {
        full := ResolveIcon(TrayIconFile)
        if (full != "") {
            try TraySetIcon(full)
        }
    }

    if !ShowTrayIcon
        A_IconHidden := true
}

OpenSettings() {
    global INI_FILE
    if !FileExist(INI_FILE)
        GenerateDefaultIni(INI_FILE)
    Run(INI_FILE)
}

HideTrayIcon() {
    global INI_FILE, ShowTrayIcon
    A_IconHidden := true
    ShowTrayIcon := false               ; 同步内存中的变量（可选，保持一致性）
    try IniWrite("0", INI_FILE, "General", "ShowTrayIcon")   ; 写入设置文件
    MsgBox("任务栏的 图标 已隐藏。`n`n如需修改设置 或重新显示图标，`n请到程序文件夹下，打开 setting.ini 文件，找到 ShowTrayIcon 项，设置为 1 。", "KeyLights", "Iconi")
}