{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}
{.push raises: [].}

import std/[strutils, unittest]
import ../../src/pon2/utils/[results2]

block: # context
  let
    val = 5
    error1 = "error1"
    error2 = "error2"

  check Pon2Result[int].ok(val).context(error2) == Pon2Result[int].ok(val)
  check Pon2Result[int].err(error1).context(error2) ==
    Pon2Result[int].err(error2 & "\n" & error1)

block: # catch
  let val1 = catch ValueError:
    "123".parseInt
  check val1 == Pon2Result[int].ok 123

  let val2 = catch(ValueError, IOError):
    "xyz".parseInt
  check val2.isErr
