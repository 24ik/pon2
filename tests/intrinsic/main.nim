{.experimental: "strictDefs".}

import std/[unittest]
import ../../src/pon2pkg/private/core/[intrinsic {.all.}]

proc main* =
  # ------------------------------------------------
  # BMI2
  # ------------------------------------------------

  # pext
  block:
    let
      val = 0b0100_1011
      mask = 0b1101_0010
      res = 0b0000_0101

    check val.uint16.pext(mask.uint16) == res.uint16
    check val.uint32.pext(mask.uint32) == res.uint32
    check val.uint64.pext(mask.uint64) == res.uint64
