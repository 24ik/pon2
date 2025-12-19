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
    var valArray: array[count, T] # NOTE: sometimes crashes with noinit
    {.push warning[Uninit]: off.}
    for elem in valArray.mitems:
      elem.assign val

    return valArray
    {.pop.}

func initArrayWith*[E: enum, T](
    t: typedesc[E], val: T
): array[E, T] {.inline, noinit.} =
  ## Returns the array with all elements the value.
  var valArray: array[E, T] # NOTE: sometimes crashes with noinit
  {.push warning[Uninit]: off.}
  for elem in valArray.mitems:
    elem.assign val

  return valArray
  {.pop.}
