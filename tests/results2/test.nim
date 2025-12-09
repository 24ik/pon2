{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/utils/[results2]

block: # context
  let
    val = 5
    err1 = "error1"
    err2 = "error2"

  check Pon2Result[int].ok(val).context(err2) == Pon2Result[int].ok(val)
  check Pon2Result[int].err(err1).context(err2) ==
    Pon2Result[int].err(err2 & "\n" & err1)
