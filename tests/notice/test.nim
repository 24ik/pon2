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
  let cnts = 150000.noticeCnts(Tsu)
  check cnts == Res[array[Notice, int]].ok [0, 2, 5, 1, 1, 2, 0]

block: # noticeCnts (comet)
  let cnts = 150000.noticeCnts(Tsu, useComet = true)
  check cnts == Res[array[Notice, int]].ok [0, 2, 5, 1, 1, 0, 1]

block: # noticeCnts (water)
  let cnts = 150000.noticeCnts(Water)
  check cnts == Res[array[Notice, int]].ok [4, 2, 1, 1, 0, 2, 0]

block: # noticeCnts (error)
  check (-150000).noticeCnts(Tsu).isErr
