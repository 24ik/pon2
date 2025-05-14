{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/app/[key]

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
