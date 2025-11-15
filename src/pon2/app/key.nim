## This module implements keyboard events.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../private/[strutils]

when defined(js) or defined(nimsuggest):
  import std/[dom]

type KeyEvent* = object ## Keyboard Event.
  code: string
  shift: bool
  ctrl: bool
  alt: bool
  meta: bool

# ------------------------------------------------
# Constructor
# ------------------------------------------------

func init*(
    T: type KeyEvent,
    code: string,
    shift = false,
    ctrl = false,
    alt = false,
    meta = false,
): T =
  KeyEvent(code: code, shift: shift, ctrl: ctrl, alt: alt, meta: meta)

func init*(
    T: type KeyEvent, c: char, shift = false, ctrl = false, alt = false, meta = false
): T =
  ## This constructor requires that `c` is digit or alphabet.
  ## `shift` is ignored if 'c' is alphabet.
  if c in '0' .. '9':
    T.init("Digit" & c, shift, ctrl, alt, meta)
  elif c in 'a' .. 'z':
    T.init("Key" & c.toUpperAscii, false, ctrl, alt, meta)
  elif c in 'A' .. 'Z':
    T.init("Key" & c, true, ctrl, alt, meta)
  else:
    T.init($c, shift, ctrl, alt, meta)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  func toKeyEvent*(event: KeyboardEvent): KeyEvent =
    ## Returns the keyboard event converted from the `KeyboardEvent`.
    KeyEvent.init(
      $event.code, event.shiftKey, event.ctrlKey, event.altKey, event.metaKey
    )
