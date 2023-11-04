## This module implements miscellaneous things.
##

{.experimental: "strictDefs".}

func sum*[I, T: SomeNumber or Natural](arr: array[I, T]): T {.inline.} =
  ## Returns the summation.
  ## This function removes the warning from `math.sum`.
  result = 0.T
  for e in arr:
    result.inc e

func sum*[T: SomeNumber or Natural](s: seq[T]): T {.inline.} =
  ## Returns the summation.
  ## This function removes the warning from `math.sum`.
  result = 0.T
  for e in s:
    result.inc e
