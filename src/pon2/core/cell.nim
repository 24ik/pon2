## This module implements cells.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat]
import ../[utils]

export utils

type Cell* {.pure.} = enum
  None = "."
  Hard = "h"
  Garbage = "o"
  Red = "r"
  Green = "g"
  Blue = "b"
  Yellow = "y"
  Purple = "p"

const
  Puyos* = {Hard .. Purple}
  NuisancePuyos* = {Hard, Garbage}
  ColoredPuyos* = {Red .. Purple}

# ------------------------------------------------
# Cell <-> string
# ------------------------------------------------

func parseCell*(str: string): Pon2Result[Cell] {.inline, noinit.} =
  ## Returns the cell converted from the string representation.
  for cell in Cell:
    if str == $cell:
      return ok cell

  err "Invalid cell: {str}".fmt
