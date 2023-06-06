## This module implements GUI configurations.
##

import os
import streams

import nigui
import yaml
import yaml/serialization

import ../core/common

type
  FullKey* = tuple
    ## Key event with modifiers.
    unicode: int
    shift: bool
    control: bool

  KeyConfig* = tuple
    ## Key configuration.
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

  ThemeConfig* = tuple
    ## Theme configuration.
    bg: Color
    bgControl: Color
    bgGhost: Color
    bgSelect: Color

  Config* = tuple
    ## GUI configuration.
    key: KeyConfig
    theme: ThemeConfig

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func toFullKey(unicode: int, shift = false, control = false): FullKey {.inline.} =
  ## Returns the key event with the given arguments.
  # TODO: test on Windows and macOS
  result.unicode = unicode
  if control and unicode in Key_A.ord .. Key_Z.ord:
    result.unicode.inc 32

  result.shift = shift
  result.control = control

func toFullKey(key: Key, shift = false, control = false): FullKey {.inline.} =
  ## Returns the key event with the given arguments.
  key.ord.toFullKey(shift, control)

# ------------------------------------------------
# Default Config
# ------------------------------------------------

const DefaultConfig = (
  key: (
    up: Key_W.toFullKey,
    right: Key_D.toFullKey,
    down: Key_S.toFullKey,
    left: Key_A.toFullKey,

    rotateRight: Key_K.toFullKey,
    rotateLeft: Key_J.toFullKey,

    none: Key_Space.toFullKey,
    garbage: Key_O.toFullKey,
    red: Key_H.toFullKey,
    green: Key_J.toFullKey,
    blue: Key_K.toFullKey,
    yellow: Key_L.toFullKey,
    purple: 59.toFullKey,
    color: Key_P.toFullKey,
    all: Key_Space.toFullKey,

    shiftUp: Key_W.toFullKey(shift = true),
    shiftDown: Key_S.toFullKey(shift = true),
    shiftRight: Key_D.toFullKey(shift = true),
    shiftLeft: Key_A.toFullKey(shift = true),

    copy: Key_C.toFullKey(control = true),
    paste: Key_V.toFullKey(control = true),

    undo: Key_Z.toFullKey(control = true),
    redo: Key_Y.toFullKey(control = true),

    focus: Key_Tab.toFullKey,
    insert: Key_I.toFullKey,
    mode: Key_U.toFullKey,

    drop: Key_N.toFullKey,
    solve: Key_Return.toFullKey,
    save: Key_S.toFullKey(control = true),
    remove: Key_Backspace.toFullKey,

    skip: Key_Space.toFullKey,
    next: Key_N.toFullKey,

    newWindow: Key_N.toFullKey(control = true),
    exit: Key_Escape.toFullKey,
  ).KeyConfig,
  theme: (
    bg: rgb(255, 255, 255),
    bgControl: rgb(240, 240, 240),
    bgGhost: rgb(230, 230, 230),
    bgSelect: rgb(205, 205, 205),
  ).ThemeConfig,
).Config

# ------------------------------------------------
# Property
# ------------------------------------------------

func pressed*(key: FullKey, event: KeyboardEvent, pressedKeys: set[Key]): bool {.inline.} =
  ## Returns :code:`true` if the :code:`key` is pressed.
  ## :code:`pressedKeys` should be :code:`nigui.downKeys().toSet()`.
  # TODO: test on Windows and macOS
  if event.unicode != key.unicode:
    return false
  if key.shift != (Key_ShiftL in pressedKeys or Key_ShiftR in pressedKeys):
    return false
  if key.control != (Key_ControlL in pressedKeys or Key_ControlR in pressedKeys):
    return false

  return true

# ------------------------------------------------
# Save / Load
# ------------------------------------------------

const ConfigFileName = "cfg.yaml"

proc save*(cfg: Config, cfgFile = ConfigDir / ConfigFileName) {.inline.} =
  ## Saves the :code:`cfg` to the :code:`cfgFile`.
  var s = cfgFile.newFileStream fmWrite
  defer: s.close

  cfg.dump s

proc loadConfig*(cfgFile = ConfigDir / ConfigFileName): Config {.inline.} =
  ## Returns the config loaded from the :code:`cfgFile`.
  ## If the :code:`cfgFile` does not exist, returns the default config.
  if not cfgFile.fileExists:
    return DefaultConfig

  var s = cfgFile.newFileStream
  defer: s.close

  try:
    s.load result
  except YamlConstructionError, YamlParserError:
    return DefaultConfig
