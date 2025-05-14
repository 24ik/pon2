{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/app/[color]

# ------------------------------------------------
# Constructor
# ------------------------------------------------

block: # init
  check Color.init(12, 34, 56) == Color(red: 12, green: 34, blue: 56, alpha: 255)
  check Color.init(1, 2, 3, 4) == Color(red: 1, green: 2, blue: 3, alpha: 4)
