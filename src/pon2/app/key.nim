## This module implements keyboard events.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat]
import ../private/[macros]

when defined(js) or defined(nimsuggest):
  import ../private/[dom]

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

# ------------------------------------------------
# Constants
# ------------------------------------------------

macro defineAsciiKeyEvents(): untyped =
  ## Defines `KeyEvent0` to `KeyEvent9`, `KeyEventA` to `KeyEventZ`, and
  ## `KeyEventShiftA` to `KeyEventShiftZ`.
  let stmts = nnkStmtList.newNimNode

  # digit
  for digit in 0 .. 9:
    let
      ident = "KeyEvent{digit}".fmt.ident
      code = "Digit{digit}".fmt.newLit
    stmts.add quote do:
      const `ident`* = KeyEvent.init `code`

  # alphabet
  for alphabet in 'A' .. 'Z':
    let
      lowerIdent = "KeyEvent{alphabet}".fmt.ident
      upperIdent = "KeyEventShift{alphabet}".fmt.ident

      code = "Key{alphabet}".fmt.newLit
    stmts.add quote do:
      const `lowerIdent`* = KeyEvent.init `code`
      const `upperIdent`* = KeyEvent.init(`code`, shift = true)

  stmts

defineAsciiKeyEvents()

const
  KeyEventEnter* = KeyEvent.init "Enter"
  KeyEventSemicolon* = KeyEvent.init "Semicolon"
  KeyEventSpace* = KeyEvent.init "Space"
  KeyEventTab* = KeyEvent.init "Tab"

  KeyEventShiftEnter* = KeyEvent.init("Enter", shift = true)
  KeyEventShiftTab* = KeyEvent.init("Tab", shift = true)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js) or defined(nimsuggest):
  func toKeyEvent*(event: KeyboardEvent): KeyEvent =
    ## Returns the keyboard event converted from the `KeyboardEvent`.
    KeyEvent.init(
      $event.code, event.shiftKey, event.ctrlKey, event.altKey, event.metaKey
    )
