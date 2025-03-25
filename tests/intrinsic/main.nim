{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[intrinsic]

proc main*() =
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

    let
      pextMask16 = PextMask[uint16].init mask.uint16
      pextMask32 = PextMask[uint32].init mask.uint32
      pextMask64 = PextMask[uint64].init mask.uint64

    check val.uint16.pext(pextMask16) == res.uint16
    check val.uint32.pext(pextMask32) == res.uint32
    check val.uint64.pext(pextMask64) == res.uint64
