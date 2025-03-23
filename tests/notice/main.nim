{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import results
import ../../src/pon2/core/[notice, rule]

proc main*() =
  # ------------------------------------------------
  # Notice Garbage
  # ------------------------------------------------

  # noticeGarbageCnts
  block:
    let cnts = 150000.noticeGarbageCnts(Tsu)
    check cnts.isOk and cnts.value == [0, 2, 5, 1, 1, 2, 0]

  # noticeGarbageCnts (comet)
  block:
    let cnts = 150000.noticeGarbageCnts(Tsu, useComet = true)
    check cnts.isOk and cnts.value == [0, 2, 5, 1, 1, 0, 1]

  # noticeGarbageCnts (water)
  block:
    let cnts = 150000.noticeGarbageCnts(Water)
    check cnts.isOk and cnts.value == [4, 2, 1, 1, 0, 2, 0]

  # noticeGarbageCnts (error)
  block:
    check (-150000).noticeGarbageCnts(Tsu).isErr
