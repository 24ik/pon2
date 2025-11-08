{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ../../src/pon2/private/[simd]

when Sse42Available:
  import std/[bitops, unittest]

when Sse42Available:
  # ------------------------------------------------
  # XMM - Constructor
  # ------------------------------------------------

  block: # mm_set_epi16
    let
      a = 12
      b = 3
      c = 4
      d = 56
      e = 7
      f = 890
      g = 12345
      h = 6789

    check mm_set_epi16(
      a.uint16, b.uint16, c.uint16, d.uint16, e.uint16, f.uint16, g.uint16, h.uint16
    ) ==
      mm_set_epi16(
        a.int16, b.int16, c.int16, d.int16, e.int16, f.int16, g.int16, h.int16
      )

  # ------------------------------------------------
  # XMM - Operator
  # ------------------------------------------------

  block: # `$`
    check $mm_set_epi16(1'u16, 2, 3, 45, 67, 890, 12345, 6789) ==
      "M128i[6789, 12345, 890, 67, 45, 3, 2, 1]"

  block: # assign
    var x = mm_setzero_si128()
    let y = mm_set1_epi64x(123)
    x.assign y

    check x == y

  # ------------------------------------------------
  # XMM - reverse
  # ------------------------------------------------

  block: # reverseBits
    let
      a = 12345'u
      b = 678'u

    check mm_set_epi64x(a, b).reverseBits == mm_set_epi64x(b.reverseBits, a.reverseBits)
