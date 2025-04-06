{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[intrinsic]

when UseSse42:
  import std/[bitops]
  import nimsimd/[sse42]

proc main*() =
  # ------------------------------------------------
  # SSE4.2
  # ------------------------------------------------

  # reverseBits
  when UseSse42:
    block:
      let
        a = 12345'u64
        b = 67890'u64
        xmm = mm_set_epi64x(a, b)
        rev = xmm.reverseBits

      let diff = mm_xor_si128(rev, mm_set_epi64x(b.reverseBits, a.reverseBits))
      check mm_testz_si128(diff, diff).bool

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
