{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[results2, strutils2]

block: # parseIntRes
  check "123".parseIntRes == Res[int].ok 123
  check "xyz".parseIntRes.isErr
