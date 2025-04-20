{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[macros, unittest]
import ../../src/pon2/private/[macros2]

# ------------------------------------------------
# Replace
# ------------------------------------------------

block: # replaced
  macro foo2bar(body: untyped): untyped =
    body.replaced("foo".ident, "bar".ident)

  let bar = 1
  foo2bar:
    let x = foo + 2 * foo.succ
  check x == 5
