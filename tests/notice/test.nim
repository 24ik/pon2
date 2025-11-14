{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[notice, rule]

# ------------------------------------------------
# Notice Garbage
# ------------------------------------------------

block: # noticeCnts
  check 150000.noticeCnts(Tsu) == [0, 2, 5, 1, 1, 2, 0]

block: # noticeCnts (comet)
  check 150000.noticeCnts(Tsu, useComet = true) == [0, 2, 5, 1, 1, 0, 1]

block: # noticeCnts (water)
  check 150000.noticeCnts(Water) == [4, 2, 1, 1, 0, 2, 0]

block: # noticeCnts (negative)
  check -150000.noticeCnts(Tsu) == [0, -2, -5, -1, -1, -2, 0]
