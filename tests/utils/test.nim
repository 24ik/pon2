{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, unittest]
import ../../src/pon2/private/[algorithm, utils]

block: # toggle
  check not true.dup(toggle)
  check false.dup(toggle)

block: # rotateSucc, rotatePred, rotateInc, rotateDec
  var x = int.high

  check x.rotateSucc == int.low
  x.rotateInc
  check x == int.low

  check x.rotateSucc == int.low.succ
  x.rotateInc
  check x == int.low.succ

  check x.rotatePred == int.low
  x.rotateDec
  check x == int.low

  check x.rotatePred == int.high
  x.rotateDec
  check x == int.high
