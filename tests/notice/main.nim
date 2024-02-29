{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2pkg/core/[notice {.all.}, rule]

proc main*() =
  # ------------------------------------------------
  # Notice Garbage
  # ------------------------------------------------

  # noticeGarbageCounts
  block:
    check 150000.noticeGarbageCounts(Tsu) == [0, 2, 5, 1, 1, 2, 0]
    check 150000.noticeGarbageCounts(Tsu, useComet = true) == [0, 2, 5, 1, 1, 0, 1]
