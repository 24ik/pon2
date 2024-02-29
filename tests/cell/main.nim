{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}

import std/[unittest]
import ../../src/pon2pkg/core/[cell {.all.}]

proc main*() =
  # ------------------------------------------------
  # Cell <-> string
  # ------------------------------------------------

  # parseCell
  block:
    for cell in Cell:
      check ($cell).parseCell == cell

    expect ValueError:
      discard "".parseCell
    expect ValueError:
      discard "H".parseCell
