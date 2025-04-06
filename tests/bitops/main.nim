{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[bitops, sugar, unittest]
import ../../src/pon2/private/[bitops3]

proc main*() =
  # ------------------------------------------------
  # In-place Operations
  # ------------------------------------------------

  # mask2, setMask2, clearMask2
  block:
    let
      val = 123456789
      mask = 98765432
      maskSlice = 12 .. 34

    check val.dup(mask2(_, mask)) == val.masked mask
    check val.dup(mask2(_, maskSlice)) == val.masked maskSlice
    check val.dup(setMask2(_, mask)) == val.setMasked mask
    check val.dup(setMask2(_, maskSlice)) == val.setMasked maskSlice
    check val.dup(clearMask2(_, mask)) == val.clearMasked mask
    check val.dup(clearMask2(_, maskSlice)) == val.clearMasked maskSlice

  # ------------------------------------------------
  # Bitwise-and
  # ------------------------------------------------

  # bitand2
  block:
    let
      a = 0xffff_ffff_ffff_ffff'u64
      b = 0xffef_fbfb_feff_feff'u64
      c = 0xf7ff_fffb_fffd_fbff'u64
      d = 0xfffd_ffef_ff7f_feff'u64
      e = 0xff7f_dfff_ffef_fdff'u64
      f = 0xfdff_ff7f_bfff_ff7f'u64
      g = 0xffbf_feff_fffb_dfff'u64
      h = 0xef7f_fdff_ef7f_f7ff'u64

    check bitand2(a, b) == bitand(a, b)
    check bitand2(a, b, c) == bitand(a, b, c)
    check bitand2(a, b, c, d) == bitand(a, b, c, d)
    check bitand2(a, b, c, d, e) == bitand(a, b, c, d, e)
    check bitand2(a, b, c, d, e, f) == bitand(a, b, c, d, e, f)
    check bitand2(a, b, c, d, e, f, g) == bitand(a, b, c, d, e, f, g)
    check bitand2(a, b, c, d, e, f, g, h) == bitand(a, b, c, d, e, f, g, h)

  # ------------------------------------------------
  # Bitwise-or
  # ------------------------------------------------

  # bitor2
  block:
    let
      a = 0x0000_0000_0000_0000'u64
      b = 0x0102_4020_8000_0400'u64
      c = 0x4200_0100_0020_8008'u64
      d = 0x0010_0402_0400_0010'u64
      e = 0x2000_8080_0010_0240'u64
      f = 0x0400_1000_0200_2001'u64
      g = 0x8020_0040_0001_0000'u64
      h = 0x0200_4001_8400_0810'u64

    check bitor2(a, b) == bitor(a, b)
    check bitor2(a, b, c) == bitor(a, b, c)
    check bitor2(a, b, c, d) == bitor(a, b, c, d)
    check bitor2(a, b, c, d, e) == bitor(a, b, c, d, e)
    check bitor2(a, b, c, d, e, f) == bitor(a, b, c, d, e, f)
    check bitor2(a, b, c, d, e, f, g) == bitor(a, b, c, d, e, f, g)
    check bitor2(a, b, c, d, e, f, g, h) == bitor(a, b, c, d, e, f, g, h)
