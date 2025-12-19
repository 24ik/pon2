{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[notice]

# ------------------------------------------------
# Notice Garbage
# ------------------------------------------------

block: # noticeCounts
  check 150000.noticeCounts(70) == [0, 2, 5, 1, 1, 2, 0]
  check -150000.noticeCounts(70) == [0, -2, -5, -1, -1, -2, 0]
  check 150000.noticeCounts(70, useComet = true) == [0, 2, 5, 1, 1, 0, 1]
  check 150000.noticeCounts(90) == [4, 2, 1, 1, 0, 2, 0]
