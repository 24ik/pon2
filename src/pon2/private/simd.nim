## This module implements SIMD operations.
##
## Compile Options:
## | Option               | Description                      | Default |
## | -------------------- | -------------------------------- | ------- |
## | `-d:pon2.simd=<int>` | SIMD level. (1: SSE4.2, 0: None) | 1       |
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

const SimdLvl {.define: "pon2.simd".} = 1

static:
  doAssert SimdLvl in 0 .. 1

const
  X86_64 = defined(amd64) or defined(i386)
  Sse42Available* = SimdLvl >= 1 and X86_64

when Sse42Available:
  import nimsimd/[sse42]
  export sse42

  when defined(gcc) or defined(clang):
    {.passc: "-msse4.2".}
    {.passl: "-msse4.2".}

when Sse42Available:
  import std/[strformat]

when Sse42Available:
  # ------------------------------------------------
  # XMM - Constructor
  # ------------------------------------------------

  func mm_set_epi16*(
    a, b, c, d, e, f, g, h: uint16
  ): M128i {.header: "<emmintrin.h>", importc: "_mm_set_epi16".}
    # patch for nimsimd's bug

  # ------------------------------------------------
  # XMM - Operator
  # ------------------------------------------------

  func `$`*(self: M128i): string {.inline.} =
    var arr {.noinit, align(16).}: array[8, uint16]
    arr.addr.mm_store_si128 self

    {.push warning[Uninit]: off.}
    return "M128i{arr}".fmt
    {.pop.}

  func `==`*(x1, x2: M128i): bool {.inline.} =
    let diff = mm_xor_si128(x1, x2)
    mm_testz_si128(diff, diff).bool

  func assign*(tgt: var M128i, src: M128i) {.inline.} =
    ## Assigns the source to the target.
    tgt = src

  # ------------------------------------------------
  # XMM - reverse
  # ------------------------------------------------

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
