## This module implements intrinsic functions.
## 
## This module partly uses [zp7](https://github.com/zwegner/zp7),
## distributed under the [MIT license](https://opensource.org/license/mit/).
## - Copyright (c) 2020 Zach Wegner
##

{.experimental: "strictDefs".}

const
  avx2 {.booldefine.} = true
  bmi2 {.booldefine.} = true

  UseAvx2* = avx2 and (defined(i386) or defined(amd64))
  UseBmi2* = bmi2 and (defined(i386) or defined(amd64))

static:
  echo "[puyo-core] AVX2 is " & (if UseAvx2: "enabled." else: "disabled.")
  echo "[puyo-core] BMI2 is " & (if UseBmi2: "enabled." else: "disabled.")

# ------------------------------------------------
# AVX2
# ------------------------------------------------

when UseAvx2:
  when defined(gcc):
    {.passc: "-mavx2".}
    {.passl: "-mavx2".}

# ------------------------------------------------
# BMI2
# ------------------------------------------------

when UseBmi2:
  when defined(gcc):
    {.passc: "-mbmi2".}
    {.passl: "-mbmi2".}

  func pext*(a, mask: uint64): uint64
            {.header: "<immintrin.h>", importc: "_pext_u64".}
    ## Parallel bits extract.
  func pext*(a, mask: uint32): uint32
            {.header: "<immintrin.h>", importc: "_pext_u32".}
  func pext*(a, mask: uint16): uint16 {.inline.} =
    uint16 a.uint32.pext mask.uint32
else:
  import std/[bitops]

  const
    BitNum64 = 6
    BitNum32 = 5
    BitNum16 = 4

  type PextMask*[T: uint64 or uint32 or uint16] = object
    ## Mask used in `pext`.
    mask: T
    bits: array[BitNum64, T]
      
  func toPextMask*[T: uint64 or uint32 or uint16](mask: T): PextMask[T]
                  {.inline.} =
    ## Converts `mask` to the pext mask.
    const BitNum =
      when T is uint64: BitNum64 elif T is uint32: BitNum32 else: BitNum16

    result.mask = mask

    var lastMask = mask.bitnot
    for i in 0..<BitNum.pred:
      var bit = lastMask shl 1
      for j in 0..<BitNum:
        bit = bitxor(bit, (bit shl (1 shl j)))

      result.bits[i] = bit
      lastMask = bitand(lastMask, bit)

    result.bits[BitNum.pred] = (T.high - lastMask + 1) shl 1

  func pext*[T: uint64 or uint32 or uint16](a: T, mask: PextMask[T]): T
            {.inline.} =
    ## Parallel bits extract.
    ## Suitable for multiple `pext` calling with the same `mask`.
    const BitNum =
      when T is uint64: BitNum64 elif T is uint32: BitNum32 else: BitNum16

    result = bitand(a, mask.mask)

    for i in 0..<BitNum:
      let bit = mask.bits[i]
      result = bitor(bitand(result, bit.bitnot),
                     bitand(result, bit) shr (1 shl i))

  func pext*[T: uint64 or uint32 or uint16](a, mask: T): T {.inline.} =
    ## Parallel bits extract.
    a.pext mask.toPextMask
