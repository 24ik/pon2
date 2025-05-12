## This module implements string utilities.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strutils]
import ./[results2]

export results2, strutils

func parseIntRes*(str: string): Res[int] {.inline.} =
  ## Returns the integer converted from the string.
  try:
    ok str.parseInt
  except ValueError as ex:
    err ex.msg
