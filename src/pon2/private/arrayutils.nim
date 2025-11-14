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
    {.push warning[Uninit]: off.}
    var arr: array[count, T] # NOTE: `noinit` does not work if T has heap-allocated type
    for elem in arr.mitems:
      elem.assign val

    return arr
    {.pop.}

func initArrayWith*[E: enum, T](t: typedesc[E], val: T): array[E, T] {.inline.} =
  ## Returns the array with all elements the value.
  {.push warning[Uninit]: off.}
  var arr: array[E, T] # NOTE: `noinit` does not work if T has heap-allocated type
  for elem in arr.mitems:
    elem.assign val

  return arr
  {.pop.}
