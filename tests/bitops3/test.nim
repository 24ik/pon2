{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[bitops3]

# ------------------------------------------------
# Bitwise-and
# ------------------------------------------------

block: # bitand2
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

block: # bitor2
  let
    a = 0x0000_0000_0000_0000'i64
    b = 0x0102_4020_8000_0400'i64
    c = 0x4200_0100_0020_8008'i64
    d = 0x0010_0402_0400_0010'i64
    e = 0x2000_8080_0010_0240'i64
    f = 0x0400_1000_0200_2001'i64
    g = 0x8020_0040_0001_0000'i64
    h = 0x0200_4001_8400_0810'i64

  check bitor2(a, b) == bitor(a, b)
  check bitor2(a, b, c) == bitor(a, b, c)
  check bitor2(a, b, c, d) == bitor(a, b, c, d)
  check bitor2(a, b, c, d, e) == bitor(a, b, c, d, e)
  check bitor2(a, b, c, d, e, f) == bitor(a, b, c, d, e, f)
  check bitor2(a, b, c, d, e, f, g) == bitor(a, b, c, d, e, f, g)
  check bitor2(a, b, c, d, e, f, g, h) == bitor(a, b, c, d, e, f, g, h)

# ------------------------------------------------
# Bitwise-andnot
# ------------------------------------------------

block: # `*~`
  const
    a = 987654321
    b = 12345678
    res = a and not b

  check a.int *~ b.int == res
  check a.uint *~ b.uint == res.uint
  check static(a.int *~ b.int) == res

# ------------------------------------------------
# Mask
# ------------------------------------------------

block: # toMask2
  const slice = 1 .. 5
  check toMask2[uint](slice) == toMask[uint](slice)
  check toMask2[uint8](slice) == toMask[uint8](slice)
  check toMask2[uint16](slice) == toMask[uint16](slice)
  check toMask2[uint32](slice) == toMask[uint32](slice)
  check toMask2[uint64](slice) == toMask[uint64](slice)

  check toMask2[int](slice) == toMask[int](slice)
  check toMask2[int8](slice) == toMask[int8](slice)
  check toMask2[int16](slice) == toMask[int16](slice)
  check toMask2[int32](slice) == toMask[int32](slice)
  check toMask2[int64](slice) == toMask[int64](slice)

  check static(toMask2[uint](slice)) == toMask[uint](slice)

# ------------------------------------------------
# BEXTR
# ------------------------------------------------

block: # bextr
  const
    val = 0b0101_1001
    start = 2'u32
    length = 5'u32
    res = 0b10110

  check val.uint.bextr(start, length) == res.uint
  check val.uint8.bextr(start, length) == res.uint8
  check val.uint16.bextr(start, length) == res.uint16
  check val.uint32.bextr(start, length) == res.uint32
  check val.uint64.bextr(start, length) == res.uint64

  check val.int.bextr(start, length) == res.int
  check val.int8.bextr(start, length) == res.int8
  check val.int16.bextr(start, length) == res.int16
  check val.int32.bextr(start, length) == res.int32
  check val.int64.bextr(start, length) == res.int64

  check val.uint.bextr(start, 0) == 0.uint
  check val.uint8.bextr(start, 0) == 0.uint8
  check val.uint16.bextr(start, 0) == 0.uint16
  check val.uint32.bextr(start, 0) == 0.uint32
  check val.uint64.bextr(start, 0) == 0.uint64

  check val.int.bextr(start, 0) == 0.int
  check val.int8.bextr(start, 0) == 0.int8
  check val.int16.bextr(start, 0) == 0.int16
  check val.int32.bextr(start, 0) == 0.int32
  check val.int64.bextr(start, 0) == 0.int64

  check static(val.uint.bextr(start, length)) == res.uint

# ------------------------------------------------
# BLSMSK
# ------------------------------------------------

block: # blsmsk
  const
    val = 0b0010_1000
    res = 0b0000_1111

  check val.uint.blsmsk == res.uint
  check val.uint8.blsmsk == res.uint8
  check val.uint16.blsmsk == res.uint16
  check val.uint32.blsmsk == res.uint32
  check val.uint64.blsmsk == res.uint64

  check val.int.blsmsk == res.int
  check val.int8.blsmsk == res.int8
  check val.int16.blsmsk == res.int16
  check val.int32.blsmsk == res.int32
  check val.int64.blsmsk == res.int64

  check 0.uint.blsmsk == uint.high
  check 0.uint8.blsmsk == uint8.high
  check 0.uint16.blsmsk == uint16.high
  check 0.uint32.blsmsk == uint32.high
  check 0.uint64.blsmsk == uint64.high

  check 0.int.blsmsk == -1
  check 0.int8.blsmsk == -1'i8
  check 0.int16.blsmsk == -1'i16
  check 0.int32.blsmsk == -1'i32
  check 0.int64.blsmsk == -1'i64

  check static(val.uint.blsmsk) == res.uint

# ------------------------------------------------
# TZCNT
# ------------------------------------------------

block: # tzcnt
  const
    val = 0b0100_1000
    res = 3

  check val.uint.tzcnt == res
  check val.uint8.tzcnt == res
  check val.uint16.tzcnt == res
  check val.uint32.tzcnt == res
  check val.uint64.tzcnt == res

  check val.int.tzcnt == res
  check val.int8.tzcnt == res
  check val.int16.tzcnt == res
  check val.int32.tzcnt == res
  check val.int64.tzcnt == res

  check 0.uint.tzcnt == bitsof uint
  check 0.uint8.tzcnt == bitsof uint8
  check 0.uint16.tzcnt == bitsof uint16
  check 0.uint32.tzcnt == bitsof uint32
  check 0.uint64.tzcnt == bitsof uint64

  check 0.int.tzcnt == bitsof int
  check 0.int8.tzcnt == bitsof int8
  check 0.int16.tzcnt == bitsof int16
  check 0.int32.tzcnt == bitsof int32
  check 0.int64.tzcnt == bitsof int64

  check static(val.uint.tzcnt) == res

# ------------------------------------------------
# PEXT
# ------------------------------------------------

block: # pext
  const
    val = 0b0100_1011
    mask = 0b1101_0010
    res = 0b0000_0101

  check val.uint16.pext(mask.uint16) == res.uint16
  check val.uint32.pext(mask.uint32) == res.uint32
  check val.uint64.pext(mask.uint64) == res.uint64

  check static(val.uint64.pext(mask.uint64)) == res.uint64

  let
    pextMask16 = PextMask[uint16].init mask.uint16
    pextMask32 = PextMask[uint32].init mask.uint32
    pextMask64 = PextMask[uint64].init mask.uint64

  check val.uint16.pext(pextMask16) == res.uint16
  check val.uint32.pext(pextMask32) == res.uint32
  check val.uint64.pext(pextMask64) == res.uint64

  check static(val.uint64.pext(PextMask[uint64].init mask.uint64)) == res.uint64

block: # popcnt
  const val = 0b1100_0110_0100_1101'u16

  check PextMask[uint16].init(val).popcnt == val.countOnes
  check PextMask[uint32].init(val.uint32).popcnt == val.countOnes
  check PextMask[uint64].init(val.uint64).popcnt == val.countOnes

  check static(PextMask[uint64].init(val.uint64)).popcnt == val.countOnes
