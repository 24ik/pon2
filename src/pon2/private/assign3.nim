## This modules implements assignments.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when defined(js):
  func assign*[T](tgt: var T, src: T) {.inline.} =
    tgt = src
else:
  import stew/[assign2]
  export assign2
