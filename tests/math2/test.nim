{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[math2]

block: # sum2
  check @[1.0, 2.0].sum2 == 3.0
  check [4, -2, 0].sum2 == 2
  check [8'i32].sum2 == 8'i32
  check newSeq[uint64]().sum2 == 0'u64
