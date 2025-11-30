## This module implements mathematic functions.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[math]
import ./[staticfor]

export math except sum

func sum*[T: SomeNumber](x1, x2: T): T {.inline, noinit.} =
  ## Returns a summation of the arguments.
  x1 + x2

func sum*[T: SomeNumber](x1, x2, x3: T): T {.inline, noinit.} =
  ## Returns a summation of the arguments.
  x1 + x2 + x3

func sum*[T: SomeNumber](x1, x2, x3, x4: T): T {.inline, noinit.} =
  ## Returns a summation of the arguments.
  (x1 + x2) + (x3 + x4)

func sum*[T: SomeNumber](x1, x2, x3, x4, x5: T): T {.inline, noinit.} =
  ## Returns a summation of the arguments.
  (x1 + x2 + x3) + (x4 + x5)

func sum*[T: SomeNumber](x1, x2, x3, x4, x5, x6: T): T {.inline, noinit.} =
  ## Returns a summation of the arguments.
  (x1 + x2) + (x3 + x4) + (x5 + x6)

func sum*[T: SomeNumber](x1, x2, x3, x4, x5, x6, x7: T): T {.inline, noinit.} =
  ## Returns a summation of the arguments.
  (x1 + x2) + (x3 + x4) + (x5 + x6 + x7)

func sum*[T: SomeNumber](x1, x2, x3, x4, x5, x6, x7, x8: T): T {.inline, noinit.} =
  ## Returns a summation of the arguments.
  sum(x1 + x2, x3 + x4, x5 + x6, x7 + x8)

func sum*[T: SomeNumber](numbers: openArray[T]): T {.inline, noinit.} =
  ## Returns a summation of the array.
  var summation = 0.T
  for number in numbers:
    summation += number

  summation

func sum*[E: enum, T: SomeNumber](
    numbers: array[E, T], slice: static Slice[E]
): T {.inline, noinit.} =
  ## Returns a summation of the array with the given slice.
  var summation = 0.T
  staticFor(idx, slice):
    summation += numbers[idx]

  summation
