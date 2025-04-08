{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[tables, unittest]
import ../../src/pon2/private/[results2, utils]

# ------------------------------------------------
# Result - Table
# ------------------------------------------------

block: # getRes
  let table = {1: "one", 2: "two"}.toTable
  check table.getRes(1) == Res[string].ok "one"
  check table.getRes(3).isErr

# ------------------------------------------------
# Result - Parse
# ------------------------------------------------

block: # parseIntRes
  check "123".parseIntRes == Res[int].ok 123
  check "-45".parseIntRes == Res[int].ok -45
  check "xyz".parseIntRes.isErr

# ------------------------------------------------
# Warning-suppress
# ------------------------------------------------

block: # sum2
  check [1, 2, 3, 4].sum2 == 10
  check newSeq[int](0).sum2 == 0
