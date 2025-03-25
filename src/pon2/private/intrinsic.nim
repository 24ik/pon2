## This module implements intrinsic functions.
## Note that AVX2 is disabled on Windows due to alignment bug.
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

when not UseBmi2:
  import stew/[staticfor]
  import ./[assign2]

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

  type PextMask*[U: uint64 or uint32 or uint16] = U ## Mask used in `pext`.

  func init*[U: uint64 or uint32 or uint16](
      T: type PextMask[U], mask: U
  ): T {.inline.} =
    mask

  func pext*(
    a: uint64, mask: uint64 or PextMask[uint64]
  ): uint64 {.header: "<immintrin.h>", importc: "_pext_u64".} ## Parallel bits extract.

  func pext*(
    a: uint32, mask: uint32 or PextMask[uint32]
  ): uint32 {.header: "<immintrin.h>", importc: "_pext_u32".} ## Parallel bits extract.

  func pext*(a: uint16, mask: uint16 or PextMask[uint16]): uint16 {.inline.} =
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

  func init*[U: uint64 or uint32 or uint16](
      T: type PextMask[U], mask: U
  ): PextMask[U] {.inline.} =
    const BitCnt =
      when U is uint64:
        BitCnt64
      elif U is uint32:
        BitCnt32
      else:
        BitCnt16

    var pextMask = T(
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
    staticFor(i, 0 ..< BitCnt.pred):
      var bit = lastMask shl 1
      staticFor(j, 0 ..< BitCnt):
        bit.assign bit xor (bit shl (1 shl j))

      pextMask.bits[i].assign bit
      lastMask.assign lastMask and bit

    pextMask.bits[^1].assign (U.high - lastMask + 1) shl 1

    pextMask

  func pext*[U: uint64 or uint32 or uint16](a: U, mask: PextMask[U]): U {.inline.} =
    ## Parallel bits extract.
    ## This function is suitable for multiple `pext` callings with the same `mask`.
    const BitCnt =
      when U is uint64:
        BitCnt64
      elif U is uint32:
        BitCnt32
      else:
        BitCnt16

    var res = a and mask.mask

    staticFor(i, 0 ..< BitCnt):
      let bit = mask.bits[i]
      res.assign (res and not bit) or ((res and bit) shr (1 shl i))

    res

  func pext*[U: uint64 or uint32 or uint16](a, mask: U): U {.inline.} =
    ## Parallel bits extract.
    a.pext PextMask[U].init mask
