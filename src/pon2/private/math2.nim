## This module implements mathematic functions.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[math]
import ./[assign3]

export math

func sum2*[T: SomeNumber](arr: openArray[T]): T {.inline.} =
  ## Returns a summation of the array.
  var res = 0.T
  for elem in arr:
    res.assign res + elem

  res

# TODO: sum2 with slice
