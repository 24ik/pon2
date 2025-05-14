{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/app/[key]

when defined(js):
  import std/[dom]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  check KeyEvent.init("KeyA") == KeyEvent.init('a')
  check KeyEvent.init("KeyB", shift = true, alt = true) == KeyEvent.init(
    'B', alt = true
  )
  check KeyEvent.init("KeyC", ctrl = true) ==
    KeyEvent.init('c', shift = true, ctrl = true)
  check KeyEvent.init("Digit1", meta = true) == KeyEvent.init('1', meta = true)
  check KeyEvent.init("Digit2", shift = true, meta = true) ==
    KeyEvent.init('2', shift = true, meta = true)

# ------------------------------------------------
# JS backend
# ------------------------------------------------

when defined(js):
  block: # toKeyEvent
    check KeyboardEvent(
      altKey: true,
      ctrlKey: false,
      metaKey: true,
      shiftKey: false,
      code: cstring "KeyA",
      isComposing: false,
      key: cstring "a",
      keyCode: 65,
      location: 0,
    ).toKeyEvent == KeyEvent.init('a', alt = true, meta = true)
