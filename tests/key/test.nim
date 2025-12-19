{.push raises: [].}
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
  check KeyEvent.init("KeyA") == KeyEventA
  check KeyEvent.init("KeyD", shift = true) == KeyEventShiftD

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
      code: "KeyA",
      isComposing: false,
      key: "a",
      keyCode: 65,
      location: 0,
    ).toKeyEvent == KeyEvent.init("KeyA", alt = true, meta = true)
