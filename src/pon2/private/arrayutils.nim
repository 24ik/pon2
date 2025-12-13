## This module implements array utilities.
## 

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./[assign]

func initArrayWith*[T](count: static int, val: T): array[count, T] {.inline, noinit.} =
  ## Returns the array with all elements the value.
  when count == 0: # NOTE: cpp backend needs branching
    []
  else:
    var valArray {.noinit.}: array[count, T]
    for elem in valArray.mitems:
      elem.wasMoved
      elem.assign val

    valArray

func initArrayWith*[E: enum, T](
    t: typedesc[E], val: T
): array[E, T] {.inline, noinit.} =
  ## Returns the array with all elements the value.
  var valArray {.noinit.}: array[E, T]
  for elem in valArray.mitems:
    elem.wasMoved
    elem.assign val

  valArray
