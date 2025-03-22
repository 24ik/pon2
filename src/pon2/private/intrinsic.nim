## This module implements intrinsic functions.
## Note that now AVX2 is disabled on Windows due to some bugs.
##
## Compile Options:
## | Option                | Description            | Default |
## | --------------------- | ---------------------- | ------- |
## | `-d:pon2.avx2=<bool>` | Use AVX2 instructions. | `true`  |
## | `-d:pon2.bmi2=<bool>` | Use BMI2 instructions. | `true`  |
##

{.push raises: [].}
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
  const
    BitCnt64 = 6
    BitCnt32 = 5
    BitCnt16 = 4

  type PextMask*[U: uint64 or uint32 or uint16] = object ## Mask used in `pext`.
    mask: U
    bits: array[
      when U is uint64:
        BitCnt64
      elif U is uint32:
        BitCnt32
      else:
        BitCnt16,
      U,
    ]

  func toPextMask*[U: uint64 or uint32 or uint16](mask: U): PextMask[U] {.inline.} =
    ## Converts `mask` to the pext mask.
    const BitNum =
      when U is uint64:
        BitCnt64
      elif U is uint32:
        BitCnt32
      else:
        BitCnt16

    var pextMask = PextMask[U](
      mask: mask,
      bits:
        when U is uint64:
          [0, 0, 0, 0, 0, 0]
        elif U is uint32:
          [0, 0, 0, 0, 0]
        else:
          [0, 0, 0, 0],
    )

    var lastMask = not mask
    for i in 0 ..< BitNum.pred:
      var bit = lastMask shl 1
      for j in 0 ..< BitNum:
        bit = bit xor (bit shl (1 shl j))

      pextMask.bits[i] = bit
      lastMask = lastMask and bit

    pextMask.bits[^1] = (U.high - lastMask + 1) shl 1

  func pext*[U: uint64 or uint32 or uint16](a: U, mask: PextMask[U]): U {.inline.} =
    ## Parallel bits extract.
    ## This function is suitable for multiple `pext` callings with the same `mask`.
    const BitNum =
      when U is uint64:
        BitCnt64
      elif U is uint32:
        BitCnt32
      else:
        BitCnt16

    var res = a and mask.mask

    for i in 0 ..< BitNum:
      let bit = mask.bits[i]
      res = (res and not bit) or ((res and bit) shr (1 shl i))

  func pext*[U: uint64 or uint32 or uint16](a, mask: U): U {.inline.} =
    ## Parallel bits extract.
    a.pext mask.toPextMask
