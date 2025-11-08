## This module implements array operations.
## 

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import ./[assign3]

func initArrWith*[T](size: static int, val: T): array[size, T] {.inline.} =
  ## Returns the array with all elements the value.
  when size == 0: # NOTE: cpp backend needs branching
    []
  else:
    {.push warning[Uninit]: off.}
    var arr: array[size, T] # NOTE: `noinit` does not work if T has heap-allocated type
    for elem in arr.mitems:
      elem.assign val

    return arr
    {.pop.}

func initArrWith*[E: enum, T](val: T): array[E, T] {.inline.} =
  ## Returns the array with all elements the value.
  {.push warning[Uninit]: off.}
  var arr: array[E, T] # NOTE: `noinit` does not work if T has heap-allocated type
  for elem in arr.mitems:
    elem.assign val

  return arr
  {.pop.}
