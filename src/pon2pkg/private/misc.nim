## This module implements miscellaneous things.
##

{.experimental: "strictDefs".}

import std/[options, strutils]
import docopt

# ------------------------------------------------
# Sum
# ------------------------------------------------

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

# ------------------------------------------------
# Parse
# ------------------------------------------------

func parseNatural*(val: Value, allowNone = false): Option[Natural] {.inline.} =
  ## Converts the value to the Natural integer.
  ## If the conversion fails, `ValueError` will be raised.
  ## If `allowNone` is `true`, `vkNone` is accepted as `val` and `none` is
  ## returned.
  {.push warning[ProveInit]: off.}
  result = none Natural # HACK: dummy to remove warning
  {.pop.}

  case val.kind
  of vkNone:
    {.push warning[ProveInit]: off.}
    if allowNone:
      result = none Natural
    else:
      raise newException(ValueError, "必須の数値入力が省略されています．")
    {.pop.}
  of vkStr:
    result = some Natural parseInt $val
  else:
    assert false

func parseNatural*(val: char or string): Natural {.inline.} = parseInt $val
  ## Converts the char or string to the Natural integer.
  ## If the conversion fails, `ValueError` will be raised.
