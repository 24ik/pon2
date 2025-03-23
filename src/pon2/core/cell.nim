## This module implements cells.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import results
import stew/shims/[tables]

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
  ColorPuyos* = {Red .. Purple}

# ------------------------------------------------
# Cell <-> string
# ------------------------------------------------

const StrToCell = collect:
  for cell in Cell:
    {$cell: cell}

func parseCell*(str: string): Result[Cell, string] {.inline.} =
  ## Returns the cell converted from the string representation.
  if str in StrToCell:
    Result[Cell, string].ok StrToCell[str]
  else:
    Result[Cell, string].err "Invalid cell: {str}".fmt
