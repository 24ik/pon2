## This module implements mathematic functions.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[math]
import ./[assign3, staticfor2]

export math

func sum2*[T: SomeNumber](arr: openArray[T]): T {.inline.} =
  ## Returns a summation of the array.
  var res = 0.T
  for elem in arr:
    res.assign res + elem

  res

func sum2*[E: enum, T: SomeNumber](
    arr: array[E, T], slice: static Slice[E]
): T {.inline.} =
  ## Returns a summation of the array with the given slice.
  var res = 0.T
  staticFor(idx, slice):
    res.assign res + arr[idx]

  res

template sum2It*[E: enum, T: SomeNumber](slice: static Slice[E], body: untyped): T =
  ## Returns a summation of the `body` with `it` injected.
  var res = 0.T
  staticFor(idx, slice):
    const it {.inject.} = idx
    res.assign res + body

  res
