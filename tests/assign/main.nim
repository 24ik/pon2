{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2/private/[assign3, intrinsic]

when UseSse42:
  import nimsimd/[sse42]
when UseAvx2:
  import nimsimd/[avx2]

proc main*() =
  # regular type
  block:
    var
      intVar = 1234
      strVar = "abc"
      arrVar = ['Z', 'Y']
      seqVar = @[{4'i8}, {5'i8, 6'i8}]

    let
      intLet = 5678
      strLet = "def"
      arrLet = ['X', 'W']
      seqLet = @[{7'i8}, {}, {}]

    intVar.assign intLet
    strVar.assign strLet
    arrVar.assign arrLet
    seqVar.assign seqLet

    check intVar == intLet
    check strVar == strLet
    check arrVar == arrLet
    check seqVar == seqLet

  # XMM
  when UseSse42:
    block:
      var xmmVar = mm_setzero_si128()
      let xmmLet = mm_set1_epi64x 1

      xmmVar.assign xmmLet
      let diff = mm_xor_si128(xmmVar, xmmLet)
      check mm_testz_si128(diff, diff).bool

  # YMM
  when UseAvx2:
    block:
      var ymmVar = mm256_setzero_si256()
      let ymmLet = mm256_set1_epi64x 1

      ymmVar.assign ymmLet
      let diff = mm256_xor_si256(ymmVar, ymmLet)
      check mm256_testz_si256(diff, diff).bool
