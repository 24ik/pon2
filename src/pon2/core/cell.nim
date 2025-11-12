## This module implements cells.
##

{.push raises: [].}
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[strformat, sugar]
import ../private/[results2, tables2]

export results2

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

func parseCell*(str: string): Res[Cell] {.inline, noinit.} =
  ## Returns the cell converted from the string representation.
  StrToCell.getRes(str).context "Invalid cell: {str}".fmt
