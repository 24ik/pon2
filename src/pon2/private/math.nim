## This module implements mathematic functions.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[math]

export math except sum

func sum*[T](x1, x2: T): T {.inline, noinit.} =
  ## Returns a summation of the arguments.
  x1 + x2

func sum*[T](x1, x2, x3: T): T {.inline, noinit.} =
  ## Returns a summation of the arguments.
  x1 + x2 + x3

func sum*[T](x1, x2, x3, x4: T): T {.inline, noinit.} =
  ## Returns a summation of the arguments.
  (x1 + x2) + (x3 + x4)

func sum*[T](x1, x2, x3, x4, x5: T): T {.inline, noinit.} =
  ## Returns a summation of the arguments.
  (x1 + x2 + x3) + (x4 + x5)

func sum*[T](x1, x2, x3, x4, x5, x6: T): T {.inline, noinit.} =
  ## Returns a summation of the arguments.
  (x1 + x2) + (x3 + x4) + (x5 + x6)

func sum*[T](x1, x2, x3, x4, x5, x6, x7: T): T {.inline, noinit.} =
  ## Returns a summation of the arguments.
  (x1 + x2) + (x3 + x4) + (x5 + x6 + x7)

func sum*[T](x1, x2, x3, x4, x5, x6, x7, x8: T): T {.inline, noinit.} =
  ## Returns a summation of the arguments.
  ((x1 + x2) + (x3 + x4)) + ((x5 + x6) + (x7 + x8))

func sum*[T: SomeNumber](numbers: openArray[T]): T {.inline, noinit.} =
  ## Returns a summation of the array.
  var summation = 0.T
  for number in numbers:
    summation += number

  summation

template sumIt*(iter, unit, body: untyped): untyped =
  ## Returns a summation of the `body` with respect to the iterable.
  var summation = unit
  for it {.inject.} in iter:
    summation += body

  summation

template sumIt*(iter, body: untyped): untyped =
  ## Returns a summation of the `body` with respect to the iterable.
  iter.sumIt(0, body)
