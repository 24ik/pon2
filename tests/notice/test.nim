{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/core/[notice, rule]
import ../../src/pon2/private/[results2]

# ------------------------------------------------
# Notice Garbage
# ------------------------------------------------

block: # noticeGarbageCnts
  let cnts = 150000.noticeGarbageCnts(Tsu)
  check cnts == Res[array[NoticeGarbage, int]].ok [0, 2, 5, 1, 1, 2, 0]

block: # noticeGarbageCnts (comet)
  let cnts = 150000.noticeGarbageCnts(Tsu, useComet = true)
  check cnts == Res[array[NoticeGarbage, int]].ok [0, 2, 5, 1, 1, 0, 1]

block: # noticeGarbageCnts (water)
  let cnts = 150000.noticeGarbageCnts(Water)
  check cnts == Res[array[NoticeGarbage, int]].ok [4, 2, 1, 1, 0, 2, 0]

block: # noticeGarbageCnts (error)
  check (-150000).noticeGarbageCnts(Tsu).isErr
