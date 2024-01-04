## This module implements cells.
##

{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[sugar, tables]

type
  Cell* {.pure.} = enum
    None = "."
    Hard = "h"
    Garbage = "o"
    Red = "r"
    Green = "g"
    Blue = "b"
    Yellow = "y"
    Purple = "p"

  ColorPuyo* = range[Red..Purple]
  Puyo* = range[Hard..Purple]

# ------------------------------------------------
# Cell <-> string
# ------------------------------------------------

const StrToCell = collect:
  for cell in Cell:
    {$cell: cell}

func parseCell*(str: string): Cell {.inline.} =
  ## Converts the string representation to the cell.
  ## If `str` is not a valid representation, `ValueError` is raised.
  if str notin StrToCell:
    raise newException(ValueError, "Invalid cell: " & str)

  result = StrToCell[str]
