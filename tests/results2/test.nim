{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[results2]

block: # context
  let
    val = 5
    err1 = "error1"
    err2 = "error2"

  check Res[int].ok(val).context(err2) == Res[int].ok(val)
  check Res[int].err(err1).context(err2) == Res[int].err(err2 & "\n" & err1)
