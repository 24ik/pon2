## This module implements cells.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar, tables]
import ./[res]

type Cell* {.pure.} = enum
  None = "."
  Hard = "h"
  Garbage = "o"
  Red = "r"
  Green = "g"
  Blue = "b"
  Yellow = "y"
  Purple = "p"

# ------------------------------------------------
# Cell <-> string
# ------------------------------------------------

const StrToCell = collect:
  for cell in Cell:
    {$cell: cell}

func parseCell*(str: string): Res[Cell] {.inline.} =
  ## Returns the cell converted from the string representation.
  if str notin StrToCell:
    Res[Cell].err "Invalid cell: {str}".fmt

  Res[Cell].ok StrToCell[str]
