## This module implements mathematic functions.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[math]
import ./[assign, staticfor]

export math except sum

func sum*[T: SomeNumber](items: openArray[T]): T {.inline, noinit.} =
  ## Returns a summation of the array.
  var res = 0.T
  for item in items:
    res.assign res + item

  res

func sum*[E: enum, T: SomeNumber](
    items: array[E, T], slice: static Slice[E]
): T {.inline, noinit.} =
  ## Returns a summation of the array with the given slice.
  var res = 0.T
  staticFor(idx, slice):
    res.assign res + items[idx]

  res

template sumIt*[E: enum, T: SomeNumber](slice: static Slice[E], body: untyped): T =
  ## Returns a summation of the `body` with `it` injected.
  var res = 0.T
  staticFor(idx, slice):
    const it {.inject.} = idx
    res.assign res + body

  res
