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
  Sse42 {.define: "pon2.sse42".} = true
  Avx2 {.define: "pon2.avx2".} = true
  Bmi2 {.define: "pon2.bmi2".} = true

  UseSse42* = Sse42 and (defined(i386) or defined(amd64))
  UseAvx2* = Avx2 and (defined(i386) or defined(amd64)) and not defined(windows)
  UseBmi2* = Bmi2 and (defined(i386) or defined(amd64))

when UseSse42:
  import nimsimd/[sse42]
when not UseBmi2:
  import stew/[staticfor]
  import ./[assign3]

# ------------------------------------------------
# SSE4.2
# ------------------------------------------------

when UseSse42:
  when defined(gcc):
    {.passc: "-msse2".}
    {.passl: "-msse2".}
    {.passc: "-msse3".}
    {.passl: "-msse3".}
    {.passc: "-mssse3".}
    {.passl: "-mssse3".}
    {.passc: "-msse4.1".}
    {.passl: "-msse4.1".}
    {.passc: "-msse4.2".}
    {.passl: "-msse4.2".}

  func mm_set_epi16*(
    a, b, c, d, e, f, g, h: uint16
  ): M128i {.header: "<emmintrin.h>", importc: "_mm_set_epi16".}

  func reverseBits*(x: M128i): M128i {.inline.} =
    ## Returns the bit reversal of x.
    var y = mm_or_si128(
      mm_and_si128(mm_set1_epi8 0x55'u8, x).mm_slli_epi64 1,
      mm_and_si128(mm_set1_epi8 0xaa'u8, x).mm_srli_epi64 1,
    )
    y = mm_or_si128(
      mm_and_si128(mm_set1_epi8 0x33'u8, y).mm_slli_epi64 2,
      mm_and_si128(mm_set1_epi8 0xcc'u8, y).mm_srli_epi64 2,
    )
    y = mm_or_si128(
      mm_and_si128(mm_set1_epi8 0x0f'u8, y).mm_slli_epi64 4,
      mm_and_si128(mm_set1_epi8 0xf0'u8, y).mm_srli_epi64 4,
    )
    y = mm_or_si128(
      mm_and_si128(mm_set1_epi16 0x00ff'u16, y).mm_slli_si128 1,
      mm_and_si128(mm_set1_epi16 0xff00'u16, y).mm_srli_si128 1,
    )
    y = mm_or_si128(
      mm_and_si128(mm_set1_epi32 0x0000ffff'u32, y).mm_slli_si128 2,
      mm_and_si128(mm_set1_epi32 0xffff0000'u32, y).mm_srli_si128 2,
    )
    y = mm_or_si128(
      mm_and_si128(mm_set1_epi64x 0x0000_0000_ffff_ffff'u64, y).mm_slli_si128 4,
      mm_and_si128(mm_set1_epi64x 0xffff_ffff_0000_0000'u64, y).mm_srli_si128 4,
    )

    mm_or_si128(y.mm_slli_si128 8, y.mm_srli_si128 8)

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
