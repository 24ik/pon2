{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2pkg/corepkg/[cell {.all.}]

proc main* =
  # ------------------------------------------------
  # Cell <-> string
  # ------------------------------------------------

  # toCell
  block:
    for cell in Cell:
      check ($cell).parseCell == cell

    expect ValueError:
      discard "".parseCell
    expect ValueError:
      discard "H".parseCell
