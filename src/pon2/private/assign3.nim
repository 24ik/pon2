## This modules implements assignments.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js):
  func assign*[T](tgt: var T, src: T) {.inline.} =
    ## Assigns the source to the target.
    tgt = src
else:
  import stew/[assign2]
  import ./[intrinsic]

  when UseSse42:
    import nimsimd/[sse42]
  when UseAvx2:
    import nimsimd/[avx2]

  when UseSse42:
    func assign*(tgt: var M128i, src: M128i) {.inline.} =
      tgt = src

  when UseAvx2:
    func assign*(tgt: var M256i, src: M256i) {.inline.} =
      tgt = src

  func assign*[T](tgt: var T, src: T) {.inline.} =
    ## Assigns the source to the target.
    assign2.assign tgt, src
