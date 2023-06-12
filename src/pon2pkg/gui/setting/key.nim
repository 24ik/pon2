## This module implements GUI key settings.
##

import strformat
import strutils
import sugar
import tables

import nigui

type
  AdditionalKey* {.pure.} = enum
    ## Key that NiGui cannot handle appropriately.
    ## Ordinal value means the ASCII code.
    AKey_None = 0
    AKey_SingleQuote = 39
    AKey_Asterisk = 42
    AKey_Colon = 58
    AKey_Semicolon = 59
    AKey_OpenBracket = 91
    AKey_Backslash = 92
    AKey_CloseBracket = 93
    AKey_Circumflex = 94
    AKey_Underscore = 95
    AKey_GraveAccent = 96
    AKey_SmallA = 97
    AKey_SmallB = 98
    AKey_SmallC = 99
    AKey_SmallD = 100
    AKey_SmallE = 101
    AKey_SmallF = 102
    AKey_SmallG = 103
    AKey_SmallH = 104
    AKey_SmallI = 105
    AKey_SmallJ = 106
    AKey_SmallK = 107
    AKey_SmallL = 108
    AKey_SmallM = 109
    AKey_SmallN = 110
    AKey_SmallO = 111
    AKey_SmallP = 112
    AKey_SmallQ = 113
    AKey_SmallR = 114
    AKey_SmallS = 115
    AKey_SmallT = 116
    AKey_SmallU = 117
    AKey_SmallV = 118
    AKey_SmallW = 119
    AKey_SmallX = 120
    AKey_SmallY = 121
    AKey_SmallZ = 122
    AKey_OpenBrace = 123
    AKey_VerticalBar = 124
    AKey_CloseBrace = 125
    AKey_Tilde = 126
    AKey_Delete = 127

  FullKey* = tuple
    ## Key with modifiers.
    key: Key
    additionalKey: AdditionalKey
    unicode: Natural
    shift: bool
    control: bool

  KeySetting* = tuple
    ## Key settings.
    # cursor
    up: FullKey
    right: FullKey
    down: FullKey
    left: FullKey

    # rotate
    rotateRight: FullKey
    rotateLeft: FullKey

    # cell
    none: FullKey
    garbage: FullKey
    red: FullKey
    green: FullKey
    blue: FullKey
    yellow: FullKey
    purple: FullKey
    color: FullKey
    all: FullKey

    # shift
    shiftUp: FullKey
    shiftDown: FullKey
    shiftRight: FullKey
    shiftLeft: FullKey

    # clipboard
    copy: FullKey
    paste: FullKey

    # undo/redo
    undo: FullKey
    redo: FullKey

    # mode
    focus: FullKey
    insert: FullKey
    mode: FullKey
    setting: FullKey

    # edit
    drop: FullKey
    solve: FullKey
    save: FullKey
    remove: FullKey

    # simulator
    skip: FullKey
    next: FullKey

    # others
    newWindow: FullKey
    exit: FullKey

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func fixUnicode(fullKey: var FullKey) {.inline.} =
  ## Fixes :code:`fullKey.unicode` that depends on the OS.
  when defined windows:
    #[
      unicode[A] == 97 == ASCII[a]
      unicode[Shift-A] == 65 == ASCII[A]
      unicode[Ctrl-A] == 1
      unicode[Ctrl-Shift-A] == 1
      unicode[Ctrl-<non-alphabet>] == 0
    ]#
    if fullKey.control:
      if fullKey.key in {Key_A .. Key_Z}:
        fullKey.unicode.dec Key_A.ord
        fullKey.unicode.inc
      elif fullKey.additionalKey in {AKey_SmallA .. AKey_SmallZ}:
        fullKey.unicode.dec AKey_SmallA.ord
        fullKey.unicode.inc
      else:
        fullKey.unicode = 0

  when not defined windows:
    #[
      unicode[A] == 65 == ASCII[A]
      unicode[Shift-A] == 65 == ASCII[A]
      unicode[Ctrl-A] == 97 == ASCII[a]
      unicode[Ctrl-Shift-A] == 65 == ASCII[A]
      unicode[Ctrl-<non-alphabet>] == unicode[<non-alphabet>]
    ]#
    # TODO: this is tested only on Ubuntu22.04; should be tested on macOS
    if fullKey.control and not fullKey.shift:
      if fullKey.key in {Key_A .. Key_Z}:
        fullKey.unicode.inc AKey_SmallA.ord - Key_A.ord
    else:
      if fullKey.additionalKey in {AKey_SmallA .. AKey_SmallZ}:
        fullKey.unicode.dec AKey_SmallA.ord - Key_A.ord

func toFullKey(key: Key, shift = false, control = false): FullKey {.inline.} =
  ## Converts the arguments to the full key.
  result.key = key
  result.additionalKey = AKey_None
  result.unicode = key.ord
  result.shift = shift
  result.control = control

  result.fixUnicode

func toFullKey(additionalKey: AdditionalKey, shift = false, control = false): FullKey {.inline.} =
  ## Converts the arguments to the full key.
  result.key = Key_None
  result.additionalKey = additionalKey
  result.unicode = additionalKey.ord
  result.shift = shift
  result.control = control

  result.fixUnicode

# ------------------------------------------------
# Default
# ------------------------------------------------

const DefaultKeySetting* = (
  up: AKey_SmallW.toFullKey,
  right: AKey_SmallD.toFullKey,
  down: AKey_SmallS.toFullKey,
  left: AKey_SmallA.toFullKey,

  rotateRight: AKey_SmallK.toFullKey,
  rotateLeft: AKey_SmallJ.toFullKey,

  none: Key_Space.toFullKey,
  garbage: AKey_SmallO.toFullKey,
  red: AKey_SmallH.toFullKey,
  green: AKey_SmallJ.toFullKey,
  blue: AKey_SmallK.toFullKey,
  yellow: AKey_SmallL.toFullKey,
  purple: AKey_Semicolon.toFullKey,
  color: AKey_SmallP.toFullKey,
  all: Key_Space.toFullKey,

  shiftUp: Key_W.toFullKey(shift = true),
  shiftDown: Key_S.toFullKey(shift = true),
  shiftRight: Key_D.toFullKey(shift = true),
  shiftLeft: Key_A.toFullKey(shift = true),

  copy: AKey_SmallC.toFullKey(control = true),
  paste: AKey_SmallV.toFullKey(control = true),

  undo: AKey_SmallZ.toFullKey(control = true),
  redo: AKey_SmallY.toFullKey(control = true),

  focus: Key_Tab.toFullKey,
  insert: AKey_SmallI.toFullKey,
  mode: AKey_SmallU.toFullKey,
  setting: AKey_SmallU.toFullKey(control = true),

  drop: AKey_SmallN.toFullKey,
  solve: Key_Return.toFullKey,
  save: AKey_SmallS.toFullKey(control = true),
  remove: Key_Backspace.toFullKey,

  skip: Key_Space.toFullKey,
  next: AKey_SmallN.toFullKey,

  newWindow: AKey_SmallN.toFullKey(control = true),
  exit: Key_Escape.toFullKey).KeySetting

# ------------------------------------------------
# Property
# ------------------------------------------------

func pressed*(fullKey: FullKey, event: KeyboardEvent, pressedKeys: set[Key]): bool {.inline.} =
  ## Returns :code:`true` if the :code:`fullKey` is pressed.
  ## :code:`pressedKeys` should be :code:`nigui.downKeys().toSet()`.
  # check modifiers
  if fullKey.shift != (Key_ShiftL in pressedKeys or Key_ShiftR in pressedKeys):
    return false
  if fullKey.control != (Key_ControlL in pressedKeys or Key_ControlR in pressedKeys):
    return false

  # check key
  if event.unicode in 1 ..< 128:
    return event.unicode == fullKey.unicode
  else:
    return event.key == fullKey.key

# ------------------------------------------------
# FullKey -> string
# ------------------------------------------------

func `$`(fullKey: FullKey): string {.inline.} =
  const
    KeyStringPairsWithoutFunction = @[
      (Key_Backspace, "BackSpace"),
      (Key_Tab, "Tab"),
      (Key_Return, "Enter"),
      (Key_Pause, "Pause"),
      (Key_CapsLock, "CapsLock"),
      (Key_Escape, "Esc"),
      (Key_ContextMenu, "Menu"),
      (Key_NumLock, "NumLock"),
      (Key_ScrollLock, "ScrollLock"),
      (Key_Insert, "Insert"),
      (Key_Left, "←"),
      (Key_Right, "→"),
      (Key_Up, "↑"),
      (Key_Down, "↓"),
      (Key_Home, "Home"),
      (Key_End, "End"),
      (Key_PageUp, "PageUp"),
      (Key_PageDown, "PageDown")]
    KeyStringPairsFunction = collect:
      for idx in 1 .. 24:
        (Key Key_F1.ord.succ idx.pred, &"F{idx}")
    KeyStringPairs = (KeyStringPairsWithoutFunction & KeyStringPairsFunction).toTable

  var strs = newSeqOfCap[string](3)
  strs.add (
    if fullKey.additionalKey != AKey_None:
      case fullKey.additionalKey
      of AKey_Delete:
        "Delete"
      of AKey_SmallA .. AKey_SmallZ:
        $fullKey.unicode.char.toUpperAscii
      else:
        $fullKey.unicode.char
    else:
      if fullKey.key in KeyStringPairs:
        KeyStringPairs[fullKey.key]
      else:
        $fullKey.unicode.char)

  if fullKey.shift:
    strs.add "Shift"
  if fullKey.control:
    strs.add "Ctrl"

  return strs.join " + "

# ------------------------------------------------
# KeySetting -> string
# ------------------------------------------------

func toStr*(setting: KeySetting, idx: Natural): string {.inline.} =
  ## This function roughly equivalent to :code:`$setting[idx]`.
  ## (When written this way, :code:`idx` need to be a compile-time constant.)
  # TODO: refactor
  case idx
  of 0: $setting.up
  of 1: $setting.right
  of 2: $setting.down
  of 3: $setting.left

  of 4: $setting.rotateRight
  of 5: $setting.rotateLeft

  of 6: $setting.none
  of 7: $setting.garbage
  of 8: $setting.red
  of 9: $setting.green
  of 10: $setting.blue
  of 11: $setting.yellow
  of 12: $setting.purple
  of 13: $setting.color
  of 14: $setting.all

  of 15: $setting.shiftUp
  of 16: $setting.shiftDown
  of 17: $setting.shiftRight
  of 18: $setting.shiftLeft

  of 19: $setting.copy
  of 20: $setting.paste

  of 21: $setting.undo
  of 22: $setting.redo

  of 23: $setting.focus
  of 24: $setting.insert
  of 25: $setting.mode
  of 26: $setting.setting

  of 27: $setting.drop
  of 28: $setting.solve
  of 29: $setting.save
  of 30: $setting.remove

  of 31: $setting.skip
  of 32: $setting.next

  of 33: $setting.newWindow
  of 34: $setting.exit

  else:
    doAssert false; "" # HACK: "" is dummy
