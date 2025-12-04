{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[notice, rule]

# ------------------------------------------------
# Notice Garbage
# ------------------------------------------------

block: # noticeCounts
  check 150000.noticeCounts(Rule.Tsu) == [0, 2, 5, 1, 1, 2, 0]

block: # noticeCounts (comet)
  check 150000.noticeCounts(Rule.Tsu, useComet = true) == [0, 2, 5, 1, 1, 0, 1]

block: # noticeCounts (water)
  check 150000.noticeCounts(Rule.Water) == [4, 2, 1, 1, 0, 2, 0]

block: # noticeCounts (negative)
  check -150000.noticeCounts(Rule.Tsu) == [0, -2, -5, -1, -1, -2, 0]
