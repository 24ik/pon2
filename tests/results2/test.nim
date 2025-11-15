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

  check StrErrorResult[int].ok(val).context(err2) == StrErrorResult[int].ok(val)
  check StrErrorResult[int].err(err1).context(err2) ==
    StrErrorResult[int].err(err2 & "\n" & err1)
