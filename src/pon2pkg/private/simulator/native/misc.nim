## This module implements miscellaneous things.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[math, tables, setutils]
import nigui
import ../[render]
import ../../../simulatorpkg/[simulator]

# ------------------------------------------------
# Button
# ------------------------------------------------

type ColorButton* = ref object of Button
  ## [Reference](https://github.com/simonkrauter/NiGui/issues/9)

proc initColorButton*(text = ""): ColorButton {.inline.} =
  ## Returns a new color button.
  result = new ColorButton
  result.init
  result.text = text

method handleDrawEvent*(control: ColorButton, event: DrawEvent) =
  let canvas = event.control.canvas
  canvas.areaColor = control.backgroundColor
  canvas.textColor = control.textColor
  canvas.lineColor = control.textColor
  canvas.drawRectArea(0, 0, control.width, control.height)
  canvas.drawTextCentered(control.text)
  canvas.drawRectOutline(0, 0, control.width, control.height)

# ------------------------------------------------
# Color
# ------------------------------------------------

func toNiguiColor*(color: render.Color): nigui.Color {.inline.} =
  ## Converts the `render.Color` to `nigui.Color`.
  rgb(color.red, color.green, color.blue, color.alpha)

# ------------------------------------------------
# Key
# ------------------------------------------------

const KeyToCode = {
  Key_Numpad0: "Numpad0", Key_Numpad1: "Numpad1", Key_Numpad2: "Numpad2",
  Key_Numpad3: "Numpad3", Key_Numpad4: "Numpad4", Key_Numpad5: "Numpad5",
  Key_Numpad6: "Numpad6", Key_Numpad7: "Numpad7", Key_Numpad8: "Numpad8",
  Key_Numpad9: "Numpad9", Key_F1: "F1", Key_F2: "F2", Key_F3: "F3",
  Key_F4: "F4", Key_F5: "F5", Key_F6: "F6", Key_F7: "F7", Key_F8: "F8",
  Key_F9: "F9", Key_F10: "F10", Key_F11: "F11", Key_F12: "F12", Key_F13: "F13",
  Key_F14: "F14", Key_F15: "F15", Key_F16: "F16", Key_F17: "F17",
  Key_F18: "F18", Key_F19: "F19", Key_F20: "F20", Key_F21: "F21",
  Key_F22: "F22", Key_F23: "F23", Key_F24: "F24", Key_NumpadAdd: "NumpadAdd",
  Key_NumpadSubtract: "NumpadSubtract", Key_NumpadMultiply: "NumpadMultiply",
  Key_NumpadDivide: "NumpadDivide", Key_NumpadDecimal: "NumpadDecimal",
  Key_NumpadEnter: "NumpadEnter", Key_Up: "ArrowUp", Key_Down: "ArrowDown",
  Key_Right: "ArrowRight", Key_Left: "ArrowLeft", Key_PageUp: "PageUp",
  Key_PageDown: "PageDown", Key_Home: "Home", Key_End: "End",
  Key_Insert: "Insert", Key_ScrollLock: "ScrollLock", Key_NumLock: "NumLock",
  Key_Pause: "Pause", Key_CapsLock: "CapsLock"}.toTable

func toKeyEvent*(event: KeyboardEvent, keys = downKeys()): KeyEvent {.inline.} =
  ## Converts the KeyboardEvent to the KeyEvent.
  ##
  ## Notes:
  ## - This function only works with JIS keyboard.
  ## - Some modifiers (Control with non-alphabet, Alt, Meta) does not work \
  ## on Windows.
  # TODO: support US keyboard
  let keysSet = keys.toSet

  var
    code: string
    shift, control, alt, meta: bool

  shift = Key_ShiftL in keysSet or Key_ShiftR in keysSet
  control = Key_ControlL in keysSet or Key_ControlR in keysSet
  alt = Key_AltL in keysSet or Key_AltR in keysSet
  meta = Key_SuperL in keysSet or Key_SuperR in keysSet

  if event.unicode == 0:
    var onlyModifier = false
    for key in keys:
      if key in {Key_ShiftL, Key_ShiftR, Key_ControlL, Key_ControlR, Key_AltL,
                 Key_AltR, Key_SuperL, Key_SuperR}:
        onlyModifier = true
      else:
        onlyModifier = false
        code = KeyToCode[key]
        break

    if onlyModifier:
      if Key_ShiftL in keysSet: code = "ShiftLeft"
      elif Key_ShiftR in keysSet: code = "ShiftRight"
      elif Key_ControlL in keysSet: code = "ControlLeft"
      elif Key_ControlR in keysSet: code = "ControlRight"
      elif Key_AltL in keysSet: code = "AltLeft"
      elif Key_AltR in keysSet: code = "AltRight"
      elif Key_SuperL in keysSet: code = "MetaLeft"
      elif Key_SuperR in keysSet: code = "MetaRight"
  else:
    code = case event.unicode
    of 8: "Backspace"
    of 9: "Tab"
    of 13: "Enter"
    of 27: "Escape"
    of 32: "Space"
    of 33..41: "Digit" & '1'.succ event.unicode - 33
    of 42: "Quote"
    of 43: "Semicolon"
    of 44: "Comma"
    of 45: "Minus"
    of 46: "Period"
    of 47: "Slash"
    of 48..57: "Digit" & '0'.succ event.unicode - 48
    of 58: "Quote"
    of 59: "Semicolon"
    of 60: "Comma"
    of 61: "Minus"
    of 62: "Period"
    of 63: "Slash"
    of 64: "BracketLeft"
    of 65..90: "Key" & 'A'.succ event.unicode - 65
    of 91: "BracketRight"
    of 92: "IntlRo"
    of 93: "Backslash"
    of 94: "Equal"
    of 95: "IntlRo"
    of 96: "BracketLeft"
    of 97..122: "Key" & 'A'.succ event.unicode - 97
    of 123: "BracketRight"
    of 124: "IntlYen"
    of 125: "Backslash"
    of 126: "Equal"
    of 127: "Delete"
    else: ""

    when defined(windows):
      if control and event.unicode in 1..26:
        code = "Key" & 'A'.succ event.unicode.pred

  result = initKeyEvent(code, shift, control, alt, meta)

# ------------------------------------------------
# Others
# ------------------------------------------------

const Dpi = when defined(windows): 144 else: 120 # TODO: better implementation

func pt*(px: int): float {.inline.} = px / Dpi * 72 ## Converts px to pt.

func px*(pt: float): int {.inline.} = (pt / 72 * Dpi).round.int
  ## Converts pt to px.
