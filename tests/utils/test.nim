{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, unittest]
import ../../src/pon2/private/[utils]

block: # toggle
  check not true.dup(toggle)
  check false.dup(toggle)

block: # incRot, decRot
  var x = int.high

  x.incRot
  check x == int.low

  x.incRot
  check x == int.low.succ

  x.decRot
  check x == int.low

  x.decRot
  check x == int.high
