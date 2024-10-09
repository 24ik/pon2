## This module implements intrinsic functions.
## Note that AVX2 is disabled on Windows due to some bugs.
##
## Compile Options:
## | Option                | Description            | Default |
## | --------------------- | ---------------------- | ------- |
## | `-d:pon2.avx2=<bool>` | Use AVX2 instructions. | `true`  |
## | `-d:pon2.bmi2=<bool>` | Use BMI2 instructions. | `true`  |
##

{.experimental: "inferGenericTypes".}
{.experimental: "notnil".}
{.experimental: "strictCaseObjects".}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

const
  Avx2 {.define: "pon2.avx2".} = true
  Bmi2 {.define: "pon2.bmi2".} = true

  UseAvx2* = Avx2 and (defined(i386) or defined(amd64)) and not defined(windows)
  UseBmi2* = Bmi2 and (defined(i386) or defined(amd64))

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

  func pext*(a, mask: uint64): uint64 {.header: "<immintrin.h>", importc: "_pext_u64".}
    ## Parallel bits extract.

  func pext*(a, mask: uint32): uint32 {.header: "<immintrin.h>", importc: "_pext_u32".}
    ## Parallel bits extract.

  func pext*(a, mask: uint16): uint16 {.inline.} =
    ## Parallel bits extract.
    uint16 a.uint32.pext mask.uint32
else:
  import std/[bitops]

  const
    BitNum64 = 6
    BitNum32 = 5
    BitNum16 = 4

  type PextMask*[T: uint64 or uint32 or uint16] = object ## Mask used in `pext`.
    mask: T
    bits: array[
      when T is uint64:
        BitNum64
      elif T is uint32:
        BitNum32
      else:
        BitNum16
      ,
      T,
    ]

  func toPextMask*[T: uint64 or uint32 or uint16](mask: T): PextMask[T] {.inline.} =
    ## Converts `mask` to the pext mask.
    const BitNum =
      when T is uint64:
        BitNum64
      elif T is uint32:
        BitNum32
      else:
        BitNum16

    result = PextMask[T](
      mask: mask,
      bits:
        when T is uint64:
          [0, 0, 0, 0, 0, 0]
        elif T is uint32:
          [0, 0, 0, 0, 0]
        else:
          [0, 0, 0, 0]
      ,
    )

    var lastMask = mask.bitnot
    for i in 0 ..< BitNum.pred:
      var bit = lastMask shl 1
      for j in 0 ..< BitNum:
        bit = bitxor(bit, (bit shl (1 shl j)))

      result.bits[i] = bit
      lastMask = bitand(lastMask, bit)

    result.bits[^1] = (T.high - lastMask + 1) shl 1

  func pext*[T: uint64 or uint32 or uint16](a: T, mask: PextMask[T]): T {.inline.} =
    ## Parallel bits extract.
    ## Suitable for multiple `pext` calling with the same `mask`.
    const BitNum =
      when T is uint64:
        BitNum64
      elif T is uint32:
        BitNum32
      else:
        BitNum16

    result = bitand(a, mask.mask)

    for i in 0 ..< BitNum:
      let bit = mask.bits[i]
      result = bitor(bitand(result, bit.bitnot), bitand(result, bit) shr (1 shl i))

  func pext*[T: uint64 or uint32 or uint16](a, mask: T): T {.inline.} =
    ## Parallel bits extract.
    a.pext mask.toPextMask
