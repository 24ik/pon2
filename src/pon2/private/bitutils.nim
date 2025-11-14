## This module implements bit operations.
##
## Compile Options:
## | Option                 | Description                            | Default |
## | ---------------------- | -------------------------------------- | ------- |
## | `-d:pon2.bmi=<int>`    | BMI level. (2: BMI2, 1: BMI1, 0: None) | 2       |
## | `-d:pon2.clmul=<bool>` | Uses CLMUL.                            | true    |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

const
  BmiLevel {.define: "pon2.bmi".} = 2
  ClmulUse {.define: "pon2.clmul".} = true

static:
  doAssert BmiLevel in 0 .. 2

const
  X86_64 = defined(amd64) or defined(i386)
  Bmi1Available* = BmiLevel >= 1 and X86_64
  Bmi2Available* = BmiLevel >= 2 and X86_64
  ClmulAvailable* = ClmulUse and X86_64

import std/[bitops, typetraits]
import stew/[bitops2]
import ./[arrayutils, assign, staticfor2]

export bitops, bitops2

when Bmi1Available:
  import nimsimd/[bmi1]
  export bmi1

  when defined(gcc) or defined(clang):
    {.passc: "-mbmi".}
    {.passl: "-mbmi".}

when Bmi2Available:
  import nimsimd/[bmi2]
  export bmi2

  when defined(gcc) or defined(clang):
    {.passc: "-mbmi2".}
    {.passl: "-mbmi2".}

when ClmulAvailable:
  import nimsimd/[pclmulqdq, sse2]
  export pclmulqdq

  when defined(gcc) or defined(clang):
    {.passc: "-mpclmul".}
    {.passl: "-mpclmul".}

# ------------------------------------------------
# Cast
# ------------------------------------------------

func asUnsigned(x: int8): uint8 {.inline, noinit.} =
  ## Returns the unsigned integer casted from the argument.
  cast[uint8](x)

func asUnsigned(x: int16): uint16 {.inline, noinit.} =
  ## Returns the unsigned integer casted from the argument.
  cast[uint16](x)

func asUnsigned(x: int32): uint32 {.inline, noinit.} =
  ## Returns the unsigned integer casted from the argument.
  cast[uint32](x)

func asUnsigned(x: int64): uint64 {.inline, noinit.} =
  ## Returns the unsigned integer casted from the argument.
  cast[uint64](x)

func asUnsigned(x: int): uint {.inline, noinit.} =
  ## Returns the unsigned integer casted from the argument.
  cast[uint](x)

func asSigned(x: uint8): int8 {.inline, noinit.} =
  ## Returns the signed integer casted from the argument.
  cast[int8](x)

func asSigned(x: uint16): int16 {.inline, noinit.} =
  ## Returns the signed integer casted from the argument.
  cast[int16](x)

func asSigned(x: uint32): int32 {.inline, noinit.} =
  ## Returns the signed integer casted from the argument.
  cast[int32](x)

func asSigned(x: uint64): int64 {.inline, noinit.} =
  ## Returns the signed integer casted from the argument.
  cast[int64](x)

func asSigned(x: uint): int {.inline, noinit.} =
  ## Returns the signed integer casted from the argument.
  cast[int](x)

# ------------------------------------------------
# Operator
# ------------------------------------------------

func `-`[T: SomeUnsignedInt](x: T): T {.inline, noinit.} =
  (not x).succ

# ------------------------------------------------
# Bitwise-and
# ------------------------------------------------

func bitand2*[T: SomeInteger](x1, x2: T): T {.inline, noinit.} =
  ## Bitwise-and operation.
  x1 and x2

func bitand2*[T: SomeInteger](x1, x2, x3: T): T {.inline, noinit.} =
  ## Bitwise-and operation.
  x1 and x2 and x3

func bitand2*[T: SomeInteger](x1, x2, x3, x4: T): T {.inline, noinit.} =
  ## Bitwise-and operation.
  (x1 and x2) and (x3 and x4)

func bitand2*[T: SomeInteger](x1, x2, x3, x4, x5: T): T {.inline, noinit.} =
  ## Bitwise-and operation.
  (x1 and x2 and x3) and (x4 and x5)

func bitand2*[T: SomeInteger](x1, x2, x3, x4, x5, x6: T): T {.inline, noinit.} =
  ## Bitwise-and operation.
  (x1 and x2) and (x3 and x4) and (x5 and x6)

func bitand2*[T: SomeInteger](x1, x2, x3, x4, x5, x6, x7: T): T {.inline, noinit.} =
  ## Bitwise-and operation.
  (x1 and x2) and (x3 and x4) and (x5 and x6 and x7)

func bitand2*[T: SomeInteger](x1, x2, x3, x4, x5, x6, x7, x8: T): T {.inline, noinit.} =
  ## Bitwise-and operation.
  ((x1 and x2) and (x3 and x4)) and ((x5 and x6) and (x7 and x8))

# ------------------------------------------------
# Bitwise-or
# ------------------------------------------------

func bitor2*[T: SomeInteger](x1, x2: T): T {.inline, noinit.} =
  ## Bitwise-or operation.
  x1 or x2

func bitor2*[T: SomeInteger](x1, x2, x3: T): T {.inline, noinit.} =
  ## Bitwise-or operation.
  x1 or x2 or x3

func bitor2*[T: SomeInteger](x1, x2, x3, x4: T): T {.inline, noinit.} =
  ## Bitwise-or operation.
  (x1 or x2) or (x3 or x4)

func bitor2*[T: SomeInteger](x1, x2, x3, x4, x5: T): T {.inline, noinit.} =
  ## Bitwise-or operation.
  (x1 or x2 or x3) or (x4 or x5)

func bitor2*[T: SomeInteger](x1, x2, x3, x4, x5, x6: T): T {.inline, noinit.} =
  ## Bitwise-or operation.
  (x1 or x2) or (x3 or x4) or (x5 or x6)

func bitor2*[T: SomeInteger](x1, x2, x3, x4, x5, x6, x7: T): T {.inline, noinit.} =
  ## Bitwise-or operation.
  (x1 or x2) or (x3 or x4) or (x5 or x6 or x7)

func bitor2*[T: SomeInteger](x1, x2, x3, x4, x5, x6, x7, x8: T): T {.inline, noinit.} =
  ## Bitwise-or operation.
  ((x1 or x2) or (x3 or x4)) or ((x5 or x6) or (x7 or x8))

# ------------------------------------------------
# Bitwise-andnot
# ------------------------------------------------

func andnotNim[T: SomeUnsignedInt](x1, x2: T): T {.inline, noinit.} =
  ## Bitwise-andnot operation; returns `x1 and (not x2)`.
  x1 and not x2

when Bmi1Available:
  func `*~`*(x1, x2: uint64): uint64 {.inline, noinit.} =
    ## Bitwise-andnot operation; returns `x1 and (not x2)`.
    when nimvm:
      x1.andnotNim x2
    else:
      x2.andn_u64 x1

  func `*~`*(x1, x2: uint32): uint32 {.inline, noinit.} =
    ## Bitwise-andnot operation; returns `x1 and (not x2)`.
    when nimvm:
      x1.andnotNim x2
    else:
      x2.andn_u32 x1

  func `*~`*[T: uint or uint16 or uint8](x1, x2: T): T {.inline, noinit.} =
    ## Bitwise-andnot operation; returns `x1 and (not x2)`.
    when nimvm:
      x1.andnotNim x2
    else:
      when T.sizeof > 4:
        x2.uint64.andn_u64(x1.uint64).T
      else:
        x2.uint32.andn_u32(x1.uint32).T
else:
  func `*~`*[T: SomeUnsignedInt](x1, x2: T): T {.inline, noinit.} =
    ## Bitwise-andnot operation; returns `x1 and (not x2)`.
    x1.andnotNim x2

func `*~`*[T: SomeSignedInt](x1, x2: T): T {.inline, noinit.} =
  ## Bitwise-andnot operation; returns `x1 and (not x2)`.
  (x1.asUnsigned *~ x2.asUnsigned).asSigned

# ------------------------------------------------
# Mask
# ------------------------------------------------

func toMaskNim[T: SomeUnsignedInt](slice: Slice[int]): T {.inline, noinit.} =
  ## Returns the mask converted from the slice.
  const MsbIndex = (T.sizeof shl 3).pred

  (T.high shr (MsbIndex - slice.b)) and (T.high shl slice.a)

when Bmi2Available:
  func toMaskImpl64(slice: Slice[int]): uint64 {.inline, noinit.} =
    ## Returns the mask converted from the slice.
    let
      subtracter = uint64.high.bzhi_u64 slice.a.uint32
      base = uint64.high.bzhi_u64 slice.b.uint32.succ

    base *~ subtracter

  func toMaskImpl32(slice: Slice[int]): uint32 {.inline, noinit.} =
    ## Returns the mask converted from the slice.
    let
      subtracter = uint32.high.bzhi_u32 slice.a.uint32
      base = uint32.high.bzhi_u32 slice.b.uint32.succ

    base *~ subtracter

  func toMask2Unsigned[T: SomeUnsignedInt](slice: Slice[int]): T {.inline, noinit.} =
    ## Returns the mask converted from the slice.
    when nimvm:
      toMaskNim[T](slice)
    else:
      when T is uint64:
        slice.toMaskImpl64
      elif T is uint32:
        slice.toMaskImpl32
      elif T.sizeof > 4:
        slice.toMaskImpl64.T
      else:
        slice.toMaskImpl32.T
elif Bmi1Available:
  func toMaskImpl64(slice: Slice[int]): uint64 {.inline, noinit.} =
    ## Returns the mask converted from the slice.
    (1'u64 shl (slice.b - slice.a)).blsmsk_u64 shl slice.a

  func toMaskImpl32(slice: Slice[int]): uint32 {.inline, noinit.} =
    ## Returns the mask converted from the slice.
    (1'u32 shl (slice.b - slice.a)).blsmsk_u32 shl slice.a

  func toMask2Unsigned[T: SomeUnsignedInt](slice: Slice[int]): T {.inline, noinit.} =
    ## Returns the mask converted from the slice.
    when nimvm:
      toMaskNim[T](slice)
    else:
      when T is uint64:
        slice.toMaskImpl64
      elif T is uint32:
        slice.toMaskImpl32
      elif T.sizeof > 4:
        slice.toMaskImpl64.T
      else:
        slice.toMaskImpl32.T
else:
  func toMask2Unsigned[T: SomeUnsignedInt](slice: Slice[int]): T {.inline, noinit.} =
    ## Returns the mask converted from the slice.
    toMaskNim[T](slice)

func toMask2Signed[T: SomeSignedInt](slice: Slice[int]): T {.inline, noinit.} =
  ## Returns the mask converted from the slice.
  toMask2Unsigned[T.toUnsigned](slice).asSigned

func toMask2*[T: SomeInteger](slice: Slice[int]): T {.inline, noinit.} =
  ## Returns the mask converted from the slice.
  when T is SomeSignedInt:
    toMask2Signed[T](slice)
  else:
    toMask2Unsigned[T](slice)

# ------------------------------------------------
# BEXTR
# ------------------------------------------------

func bextrNim[T: SomeInteger](val: T, start, length: uint32): T {.inline, noinit.} =
  ## Bit field extract.
  (val shr start) and (1.T shl length).pred

when Bmi1Available:
  func bextr*(val: uint64, start, length: uint32): uint64 {.inline, noinit.} =
    ## Bit field extract.
    when nimvm:
      val.bextrNim(start, length)
    else:
      val.bextr_u64(start, length)

  func bextr*(val: uint32, start, length: uint32): uint32 {.inline, noinit.} =
    ## Bit field extract.
    when nimvm:
      val.bextrNim(start, length)
    else:
      val.bextr_u32(start, length)

  func bextr*[T: uint or uint16 or uint8](
      val: T, start, length: uint32
  ): T {.inline, noinit.} =
    ## Bit field extract.
    when nimvm:
      val.bextrNim(start, length)
    else:
      when T.sizeof > 4:
        val.uint64.bextr(start, length).T
      else:
        val.uint32.bextr(start, length).T
else:
  func bextr*[T: SomeUnsignedInt](val: T, start, length: uint32): T {.inline, noinit.} =
    ## Bit field extract.
    val.bextrNim(start, length)

func bextr*[T: SomeSignedInt](val: T, start, length: uint32): T {.inline, noinit.} =
  ## Bit field extract.
  val.asUnsigned.bextrNim(start, length).asSigned

# ------------------------------------------------
# BLSMSK
# ------------------------------------------------

func blsmskNim[T: SomeSignedInt](val: T): T {.inline, noinit.} =
  ## Returns the mask up to the lowest set bit.
  ## If `val` is zero, all bits of the result are one.
  val.pred xor val

func blsmskNim[T: SomeUnsignedInt](val: T): T {.inline, noinit.} =
  ## Returns the mask up to the lowest set bit.
  ## If `val` is zero, all bits of the result are one.
  val.asSigned.blsmskNim.asUnsigned

when Bmi1Available:
  func blsmsk*(val: uint64): uint64 {.inline, noinit.} =
    ## Returns the mask up to the lowest set bit.
    ## If `val` is zero, all bits of the result are one.
    when nimvm: val.blsmskNim else: val.blsmsk_u64

  func blsmsk*(val: uint32): uint32 {.inline, noinit.} =
    ## Returns the mask up to the lowest set bit.
    ## If `val` is zero, all bits of the result are one.
    when nimvm: val.blsmskNim else: val.blsmsk_u32

  func blsmsk*[T: uint or uint16 or uint8](val: T): T {.inline, noinit.} =
    ## Returns the mask up to the lowest set bit.
    ## If `val` is zero, all bits of the result are one.
    when nimvm:
      val.blsmskNim
    else:
      when T.sizeof > 4: val.uint64.blsmsk.T else: val.uint32.blsmsk.T

  func blsmsk*[T: SomeSignedInt](val: T): T {.inline, noinit.} =
    ## Returns the mask up to the lowest set bit.
    ## If `val` is zero, all bits of the result are one.
    val.asUnsigned.blsmsk.asSigned
else:
  func blsmsk*[T: SomeInteger](val: T): T {.inline, noinit.} =
    ## Returns the mask up to the lowest set bit.
    ## If `val` is zero, all bits of the result are one.
    val.blsmskNim

# ------------------------------------------------
# TZCNT
# ------------------------------------------------

when Bmi1Available:
  func tzcnt_u16(a: uint16): uint16 {.header: "immintrin.h", importc: "_tzcnt_u16".}
  func tzcnt_u32(a: uint32): uint32 {.header: "immintrin.h", importc: "_tzcnt_u32".}
  func tzcnt_u64(a: uint64): uint64 {.header: "immintrin.h", importc: "_tzcnt_u64".}

func tzcnt*[T: SomeUnsignedInt](val: T): int {.inline, noinit.} =
  ## Returns the number of trailing zeros.
  ## If `val` is zero, returns the number of bits of `T`.
  when nimvm:
    val.trailingZeros
  else:
    when Bmi1Available:
      when T.sizeof > 4:
        val.tzcnt_u64.int
      elif T.sizeof == 4:
        val.tzcnt_u32.int
      elif T.sizeof == 2:
        val.tzcnt_u16.int
      else:
        if val == 0: T.bitsof else: val.uint16.tzcnt_u16.int
    else:
      val.trailingZeros

func tzcnt*[T: SomeSignedInt](val: T): int {.inline, noinit.} =
  ## Returns the number of trailing zeros.
  ## If `val` is zero, returns the number of bits of `T`.
  val.asUnsigned.tzcnt

# ------------------------------------------------
# PEXT
# ref: https://github.com/zwegner/zp7/blob/master/zp7.c
# ------------------------------------------------

const
  BitCount64 = 6
  BitCount32 = 5
  BitCount16 = 4

type PextMaskNim[T: uint64 or uint32 or uint16] = object ## Mask used by PEXT.
  mask: T
  bits: array[
    when T is uint64:
      BitCount64
    elif T is uint32:
      BitCount32
    else:
      BitCount16,
    T,
  ]

func initPureNim[T: uint64 or uint32 or uint16](
    M: type PextMaskNim[T], mask: T
): M {.inline, noinit.} =
  ## Returns the PEXT mask.
  ## This function works on any context.
  const
    BitCount =
      when T is uint64:
        BitCount64
      elif T is uint32:
        BitCount32
      else:
        BitCount16
    ZeroArray = BitCount.initArrayWith 0.T

  var
    pextMask = M(mask: mask, bits: ZeroArray)
    lastMask = not mask
  staticFor(i, 0 ..< BitCount.pred):
    var bit = lastMask shl 1
    staticFor(j, 0 ..< BitCount):
      bit.assign bit xor (bit shl (1 shl j))

    pextMask.bits[i].assign bit
    lastMask.assign lastMask and bit

  pextMask.bits[^1].assign -lastMask shl 1

  pextMask

when ClmulAvailable:
  func initIntrinsicNim[T: uint64 or uint32 or uint16](
      M: type PextMaskNim[T], mask: T
  ): M {.inline, noinit.} =
    ## Returns the PEXT mask.
    ## This function uses SSE2 and CLMUL.
    const
      BitCount =
        when T is uint64:
          BitCount64
        elif T is uint32:
          BitCount32
        else:
          BitCount16
      ZeroArray = BitCount.initArrayWith 0.T

    var pextMask = M(mask: mask, bits: ZeroArray)
    when T is uint64:
      var mask2 = (not mask).mm_cvtsi64_si128
      let neg2 = (-2).mm_cvtsi64_si128
    elif T is uint32:
      var mask2 = (not mask).mm_cvtsi32_si128
      let neg2 = (-2).mm_cvtsi32_si128
    else:
      var mask2 = (not mask).uint32.mm_cvtsi32_si128
      let neg2 = (-2).mm_cvtsi32_si128

    staticFor(i, 0 ..< BitCnt.pred):
      let bit = mm_clmulepi64_si128(mask2, neg2, 0)
      pextMask.bits[i].assign(
        when T is uint64:
          bit.mm_cvtsi128_si64.asUnsigned
        elif T is uint32:
          bit.mm_cvtsi128_si32.asUnsigned
        else:
          bit.mm_cvtsi128_si32.asUnsigned.uint16
      )

      mask2 = mm_and_si128(mask2, bit)

    pextMask.bits[^1].assign(
      when T is uint64:
        (-mask2.mm_cvtsi128_si64 shl 1).asUnsigned
      elif T is uint32:
        (-mask2.mm_cvtsi128_si32 shl 1).asUnsigned
      else:
        (-mask2.mm_cvtsi128_si32 shl 1).asUnsigned.uint16
    )

    pextMask

func initNim[T: uint64 or uint32 or uint16](
    M: type PextMaskNim[T], mask: T
): M {.inline, noinit.} =
  ## Returns the PEXT mask.
  when nimvm:
    M.initPureNim mask
  else:
    when ClmulAvailable:
      M.initIntrinsicNim mask
    else:
      M.initPureNim mask

func pextNim[T: uint64 or uint32 or uint16](
    a: T, mask: PextMaskNim[T]
): T {.inline, noinit.} =
  ## Parallel bits extract.
  ## This function is suitable for multiple PEXT callings with the same mask.
  const BitCount =
    when T is uint64:
      BitCount64
    elif T is uint32:
      BitCount32
    else:
      BitCount16

  var res = a and mask.mask

  staticFor(i, 0 ..< BitCount):
    let bit = mask.bits[i]
    res.assign (res *~ bit) or ((res and bit) shr (1 shl i))

  res

func pextNim[T: uint64 or uint32 or uint16](a, mask: T): T {.inline, noinit.} =
  ## Parallel bits extract.
  a.pextNim PextMaskNim[T].initNim mask

when Bmi2Available:
  type PextMask*[T: uint64 or uint32 or uint16] = T ## Mask used in `pext`.

  func init*[T: uint64 or uint32 or uint16](
      M: type PextMask[T], mask: T
  ): M {.inline, noinit.} =
    mask

  func pext*(a: uint64, mask: uint64 or PextMask[uint64]): uint64 {.inline, noinit.} =
    ## Parallel bits extract.
    when nimvm:
      a.pextNim mask
    else:
      a.pext_u64 mask

  func pext*(a: uint32, mask: uint32 or PextMask[uint32]): uint32 {.inline, noinit.} =
    ## Parallel bits extract.
    when nimvm:
      a.pextNim mask
    else:
      a.pext_u32 mask

  func pext*(a: uint16, mask: uint16 or PextMask[uint16]): uint16 {.inline, noinit.} =
    ## Parallel bits extract.
    when nimvm:
      a.pextNim mask
    else:
      uint16 a.uint32.pext mask.uint32

  func popcnt*[T: uint64 or uint32 or uint16](
      self: PextMask[T]
  ): int {.inline, noinit.} =
    ## Population counts.
    self.countOnes
else:
  type PextMask*[T: uint64 or uint32 or uint16] = PextMaskNim[T] ## Mask used in `pext`.

  func init*[T: uint64 or uint32 or uint16](
      M: type PextMask[T], mask: T
  ): M {.inline, noinit.} =
    M.initNim mask

  func pext*[T: uint64 or uint32 or uint16](
      a: T, mask: PextMask[T]
  ): T {.inline, noinit.} =
    ## Parallel bits extract.
    ## This function is suitable for multiple PEXT callings with the same mask.
    a.pextNim mask

  func pext*[T: uint64 or uint32 or uint16](a, mask: T): T {.inline, noinit.} =
    ## Parallel bits extract.
    a.pextNim mask

  func popcnt*[T: uint64 or uint32 or uint16](
      self: PextMask[T]
  ): int {.inline, noinit.} =
    ## Population counts.
    self.mask.countOnes
