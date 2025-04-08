## This modules implements assignments.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

when not defined(js):
  import stew/[assign2]

func assign*[T](tgt: var T, src: T) {.inline.} =
  ## Assigns the source to the target.
  when defined(js):
    tgt = src
  else:
    assign2.assign tgt, src
