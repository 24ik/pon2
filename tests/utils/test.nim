{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, unittest]
import ../../src/pon2/private/[algorithm, utils]

block: # toggle
  check not true.dup(toggle)
  check false.dup(toggle)

block: # rotateInc, rotateDec
  var x = int.high

  x.rotateInc
  check x == int.low

  x.rotateInc
  check x == int.low.succ

  x.rotateDec
  check x == int.low

  x.rotateDec
  check x == int.high
