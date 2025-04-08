## This module implements bit operations.
##
## Compile Options:
## | Option              | Description                            | Default |
## | ------------------- | -------------------------------------- | ------- |
## | `-d:pon2.bmi=<int>` | BMI level. (2: BMI2, 1: BMI1, 0: None) | 2       |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

const BmiLvl {.define: "pon2.bmi".} = 2

static:
  doAssert BmiLvl in 0 .. 2

const
  X86_64 = defined(amd64) or defined(i386)
  Bmi1Available* = BmiLvl >= 1 and X86_64
  Bmi2Available* = BmiLvl >= 2 and X86_64

import ./[arrayops2, assign3, staticfor2]

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

# ------------------------------------------------
# Bitwise-and
# ------------------------------------------------

func bitand2*[T: SomeUnsignedInt](x1, x2: T): T {.inline.} =
  ## Bitwise-and operation.
  x1 and x2

func bitand2*[T: SomeUnsignedInt](x1, x2, x3: T): T {.inline.} =
  ## Bitwise-and operation.
  x1 and x2 and x3

func bitand2*[T: SomeUnsignedInt](x1, x2, x3, x4: T): T {.inline.} =
  ## Bitwise-and operation.
  (x1 and x2) and (x3 and x4)

func bitand2*[T: SomeUnsignedInt](x1, x2, x3, x4, x5: T): T {.inline.} =
  ## Bitwise-and operation.
  (x1 and x2 and x3) and (x4 and x5)

func bitand2*[T: SomeUnsignedInt](x1, x2, x3, x4, x5, x6: T): T {.inline.} =
  ## Bitwise-and operation.
  (x1 and x2) and (x3 and x4) and (x5 and x6)

func bitand2*[T: SomeUnsignedInt](x1, x2, x3, x4, x5, x6, x7: T): T {.inline.} =
  ## Bitwise-and operation.
  (x1 and x2) and (x3 and x4) and (x5 and x6 and x7)

func bitand2*[T: SomeUnsignedInt](x1, x2, x3, x4, x5, x6, x7, x8: T): T {.inline.} =
  ## Bitwise-and operation.
  ((x1 and x2) and (x3 and x4)) and ((x5 and x6) and (x7 and x8))

# ------------------------------------------------
# Bitwise-or
# ------------------------------------------------

func bitor2*[T: SomeUnsignedInt](x1, x2: T): T {.inline.} =
  ## Bitwise-or operation.
  x1 or x2

func bitor2*[T: SomeUnsignedInt](x1, x2, x3: T): T {.inline.} =
  ## Bitwise-or operation.
  x1 or x2 or x3

func bitor2*[T: SomeUnsignedInt](x1, x2, x3, x4: T): T {.inline.} =
  ## Bitwise-or operation.
  (x1 or x2) or (x3 or x4)

func bitor2*[T: SomeUnsignedInt](x1, x2, x3, x4, x5: T): T {.inline.} =
  ## Bitwise-or operation.
  (x1 or x2 or x3) or (x4 or x5)

func bitor2*[T: SomeUnsignedInt](x1, x2, x3, x4, x5, x6: T): T {.inline.} =
  ## Bitwise-or operation.
  (x1 or x2) or (x3 or x4) or (x5 or x6)

func bitor2*[T: SomeUnsignedInt](x1, x2, x3, x4, x5, x6, x7: T): T {.inline.} =
  ## Bitwise-or operation.
  (x1 or x2) or (x3 or x4) or (x5 or x6 or x7)

func bitor2*[T: SomeUnsignedInt](x1, x2, x3, x4, x5, x6, x7, x8: T): T {.inline.} =
  ## Bitwise-or operation.
  ((x1 or x2) or (x3 or x4)) or ((x5 or x6) or (x7 or x8))

# ------------------------------------------------
# Bitwise-andnot
# ------------------------------------------------

func andnotNim[T: SomeUnsignedInt](x1, x2: T): T {.inline.} =
  ## Bitwise-andnot operation; returns `x1 and (not x2)`.
  x1 and not x2

when Bmi1Available:
  func `*~`*(x1, x2: uint64): uint64 {.inline.} =
    ## Bitwise-andnot operation; returns `x1 and (not x2)`.
    when nimvm:
      x1.andnotNim x2
    else:
      x2.andn_u64 x1

  func `*~`*(x1, x2: uint32): uint32 {.inline.} =
    ## Bitwise-andnot operation; returns `x1 and (not x2)`.
    when nimvm:
      x1.andnotNim x2
    else:
      x2.andn_u32 x1

  func `*~`*[T: uint or uint16 or uint8](x1, x2: T): T {.inline.} =
    ## Bitwise-andnot operation; returns `x1 and (not x2)`.
    when nimvm:
      x1.andnotNim x2
    else:
      when T.sizeof > 4:
        T x2.uint64.andn_u64 x1.uint64
      else:
        T x2.uint32.andn_u32 x1.uint32
else:
  func `*~`*[T: SomeUnsignedInt](x1, x2: T): T {.inline.} =
    ## Bitwise-andnot operation; returns `x1 and (not x2)`.
    x1.andnotNim x2

# ------------------------------------------------
# Mask
# ------------------------------------------------

func toMaskNim[T: SomeUnsignedInt](slice: Slice[int]): T {.inline.} =
  ## Returns the mask converted from the slice.
  const MsbIdx = (T.sizeof shl 3).pred

  (T.high shr (MsbIdx - slice.b)) and (T.high shl slice.a)

when Bmi2Available:
  func toMaskImpl64(slice: Slice[int]): uint64 {.inline.} =
    ## Returns the mask converted from the slice.
    let
      subtracter = uint64.high.bzhi_u64 slice.a.uint32
      base = uint64.high.bzhi_u64 slice.b.uint32.succ

    base *~ subtracter

  func toMaskImpl32(slice: Slice[int]): uint32 {.inline.} =
    ## Returns the mask converted from the slice.
    let
      subtracter = uint32.high.bzhi_u32 slice.a.uint32
      base = uint32.high.bzhi_u32 slice.b.uint32.succ

    base *~ subtracter

  func toMask2*[T: SomeUnsignedInt](slice: Slice[int]): T {.inline.} =
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
  func toMaskImpl64(slice: Slice[int]): uint64 {.inline.} =
    ## Returns the mask converted from the slice.
    (1'u64 shl (slice.b - slice.a)).blsmsk_u64 shl slice.a

  func toMaskImpl32(slice: Slice[int]): uint32 {.inline.} =
    ## Returns the mask converted from the slice.
    (1'u32 shl (slice.b - slice.a)).blsmsk_u32 shl slice.a

  func toMask2*[T: SomeUnsignedInt](slice: Slice[int]): T {.inline.} =
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
  func toMask2*[T: SomeUnsignedInt](slice: Slice[int]): T {.inline.} =
    ## Returns the mask converted from the slice.
    toMaskNim[T](slice)

# ------------------------------------------------
# PEXT
# ------------------------------------------------

const
  BitCnt64 = 6
  BitCnt32 = 5
  BitCnt16 = 4

type PextMaskNim[T: uint64 or uint32 or uint16] = object ## Mask used in `pext`.
  mask: T
  bits: array[
    when T is uint64:
      BitCnt64
    elif T is uint32:
      BitCnt32
    else:
      BitCnt16,
    T,
  ]

func initNim[T: uint64 or uint32 or uint16](
    M: type PextMaskNim[T], mask: T
): M {.inline.} =
  const
    BitCnt =
      when T is uint64:
        BitCnt64
      elif T is uint32:
        BitCnt32
      else:
        BitCnt16
    ZeroArr = BitCnt.initArrWith 0.T

  var
    pextMask = M(mask: mask, bits: ZeroArr)
    lastMask = not mask
  staticFor(i, 0 ..< BitCnt.pred):
    var bit = lastMask shl 1
    staticFor(j, 0 ..< BitCnt):
      bit.assign bit xor (bit shl (1 shl j))

    pextMask.bits[i].assign bit
    lastMask.assign lastMask and bit

  pextMask.bits[^1].assign (T.high - lastMask + 1) shl 1

  pextMask

func pextNim[T: uint64 or uint32 or uint16](a: T, mask: PextMaskNim[T]): T {.inline.} =
  ## Parallel bits extract.
  ## This function is suitable for multiple PEXT callings with the same mask.
  const BitCnt =
    when T is uint64:
      BitCnt64
    elif T is uint32:
      BitCnt32
    else:
      BitCnt16

  var res = a and mask.mask

  staticFor(i, 0 ..< BitCnt):
    let bit = mask.bits[i]
    res.assign (res and not bit) or ((res and bit) shr (1 shl i))

  res

func pextNim[T: uint64 or uint32 or uint16](a, mask: T): T {.inline.} =
  ## Parallel bits extract.
  a.pextNim PextMaskNim[T].initNim mask

when Bmi2Available:
  type PextMask*[T: uint64 or uint32 or uint16] = T ## Mask used in `pext`.

  func init*[T: uint64 or uint32 or uint16](
      M: type PextMask[T], mask: T
  ): M {.inline.} =
    mask

  func pext*(a: uint64, mask: uint64 or PextMask[uint64]): uint64 {.inline.} =
    ## Parallel bits extract.
    a.pext_u64 mask

  func pext*(a: uint32, mask: uint32 or PextMask[uint32]): uint32 {.inline.} =
    ## Parallel bits extract.
    a.pext_u32 mask

  func pext*(a: uint16, mask: uint16 or PextMask[uint16]): uint16 {.inline.} =
    ## Parallel bits extract.
    uint16 a.uint32.pext mask.uint32
else:
  type PextMask* = PextMaskNim

  func init*[T: uint64 or uint32 or uint16](
      M: type PextMask[T], mask: T
  ): M {.inline.} =
    M.initNim mask

  func pext*[T: uint64 or uint32 or uint16](a: T, mask: PextMask[T]): T {.inline.} =
    ## Parallel bits extract.
    ## This function is suitable for multiple PEXT callings with the same mask.
    a.pextNim mask

  func pext*[T: uint64 or uint32 or uint16](a, mask: T): T {.inline.} =
    ## Parallel bits extract.
    a.pextNim mask
