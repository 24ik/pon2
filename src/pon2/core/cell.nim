## This module implements cells.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar, tables]
import ../private/[misc, results2]

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

func parseCell*(str: string): Res[Cell] {.inline.} =
  ## Returns the cell converted from the string representation.
  StrToCell.getRes(str).context "Invalid cell: {str}".fmt
